# frozen_string_literal: true

require "test_helper"

require "lib/controller/fake_models"

class ActionViewRemoteFormHelpersTest < ActionView::TestCase
  include RenderERBUtils

  setup do
    @old_value = ActionView::Helpers::FormHelper.form_with_generates_ids
    ActionView::Helpers::FormHelper.form_with_generates_ids = true
  end

  teardown do
    ActionView::Helpers::FormHelper.form_with_generates_ids = @old_value
  end

  private
    def with_default_enforce_utf8(value)
      old_value = ActionView::Helpers::FormTagHelper.default_enforce_utf8
      ActionView::Helpers::FormTagHelper.default_enforce_utf8 = value

      yield
    ensure
      ActionView::Helpers::FormTagHelper.default_enforce_utf8 = old_value
    end
end

class FormWithTest < ActionViewRemoteFormHelpersTest
  tests ActionViewRemoteFormHelpers

  def form_with(*, **)
    @rendered = super
  end

  setup do
    @post = Post.new
    @comment = Comment.new
    def @post.errors
      Class.new {
        def [](field); field == "author_name" ? [ "can't be empty" ] : [] end
        def empty?() false end
        def count() 1 end
        def full_messages() [ "Author name can't be empty" ] end
      }.new
    end
    def @post.to_key; [ 123 ]; end
    def @post.id; 0; end
    def @post.id_before_type_cast; "omg"; end
    def @post.id_came_from_user?; true; end
    def @post.to_param; "123"; end

    @post.persisted   = true
    @post.title       = "Hello World"
    @post.author_name = ""
    @post.body        = "Back to the hill and over it again!"
    @post.secret      = 1
    @post.written_on  = Date.new(2004, 6, 15)

    @post.comments = []
    @post.comments << @comment

    @post.tags = []
    @post.tags << Tag.new

    @post_delegator = PostDelegator.new

    @post_delegator.title = "Hello World"

    @car = Car.new("#000FFF")
    @controller.singleton_class.include Routes.url_helpers
  end

  RecordForm = Struct.new(:to_model, keyword_init: true)
  Routes = ActionDispatch::Routing::RouteSet.new
  Routes.draw do
    resources :posts do
      resources :comments
    end

    namespace :admin do
      resources :posts do
        resources :comments
      end
    end

    get "/foo", to: "controller#action"
    root to: "main#index"
  end

  include Routes.url_helpers

  def url_for(object)
    @url_for_options = object

    if object.is_a?(Hash) && object[:use_route].blank? && object[:controller].blank?
      object[:controller] = "main"
      object[:action] = "index"
    end

    super
  end

  def test_form_with
    form_with(model: @post, id: "create-post") do |f|
      concat f.label(:title) { "The Title" }
      concat f.text_field(:title)
      concat f.text_area(:body)
      concat f.check_box(:secret)
      concat f.select(:category, %w[ animal economy sports ])
      concat f.submit("Create post")
      concat f.button("Create post")
      concat f.button {
        concat content_tag(:span, "Create post")
      }
    end

    expected = whole_form("/posts/123", "create-post", method: "patch") do
      "<label for='post_title'>The Title</label>" \
      "<input name='post[title]' type='text' value='Hello World' id='post_title' />" \
      "<textarea name='post[body]' id='post_body'>\nBack to the hill and over it again!</textarea>" \
      "<input name='post[secret]' type='hidden' value='0' autocomplete='off' />" \
      "<input name='post[secret]' checked='checked' type='checkbox' value='1' id='post_secret' />" \
      "<select name='post[category]' id='post_category'><option value='animal'>animal</option>\n<option value='economy'>economy</option>\n<option value='sports'>sports</option></select>" \
      "<input name='commit' data-disable-with='Create post' type='submit' value='Create post' />" \
      "<button name='button' type='submit'>Create post</button>" \
      "<button name='button' type='submit'><span>Create post</span></button>"
    end

    assert_dom_equal expected, @rendered
  end

  def test_form_with_not_outputting_ids
    old_value = ActionView::Helpers::FormHelper.form_with_generates_ids
    ActionView::Helpers::FormHelper.form_with_generates_ids = false

    form_with(model: @post, id: "create-post") do |f|
      concat f.label(:title) { "The Title" }
      concat f.text_field(:title)
      concat f.text_area(:body)
      concat f.check_box(:secret)
      concat f.select(:category, %w[ animal economy sports ])
      concat f.submit("Create post")
    end

    expected = whole_form("/posts/123", "create-post", method: "patch") do
      "<label>The Title</label>" \
      "<input name='post[title]' type='text' value='Hello World' />" \
      "<textarea name='post[body]'>\nBack to the hill and over it again!</textarea>" \
      "<input name='post[secret]' type='hidden' value='0' autocomplete='off' />" \
      "<input name='post[secret]' checked='checked' type='checkbox' value='1' />" \
      "<select name='post[category]'><option value='animal'>animal</option>\n<option value='economy'>economy</option>\n<option value='sports'>sports</option></select>" \
      "<input name='commit' data-disable-with='Create post' type='submit' value='Create post' />"
    end

    assert_dom_equal expected, @rendered
  ensure
    ActionView::Helpers::FormHelper.form_with_generates_ids = old_value
  end

  def test_form_with_with_model_using_relative_model_naming
    blog_post = Blog::Post.new("And his name will be forty and four.", 44)

    form_with(model: blog_post) do |f|
      concat f.text_field :title
      concat f.submit("Edit post")
    end

    expected = whole_form("/posts/44", method: "patch") do
      "<input name='post[title]' type='text' value='And his name will be forty and four.' id='post_title' />" \
      "<input name='commit' data-disable-with='Edit post' type='submit' value='Edit post' />"
    end

    assert_dom_equal expected, @rendered
  end

  def test_form_with_with_symbol_scope
    form_with(model: @post, scope: "other_name", id: "create-post") do |f|
      concat f.label(:title, class: "post_title")
      concat f.text_field(:title)
      concat f.text_area(:body)
      concat f.check_box(:secret)
      concat f.submit("Create post")
    end

    expected = whole_form("/posts/123", "create-post", method: "patch") do
      "<label for='other_name_title' class='post_title'>Title</label>" \
      "<input name='other_name[title]' value='Hello World' type='text' id='other_name_title' />" \
      "<textarea name='other_name[body]' id='other_name_body'>\nBack to the hill and over it again!</textarea>" \
      "<input name='other_name[secret]' value='0' type='hidden' autocomplete='off' />" \
      "<input name='other_name[secret]' checked='checked' value='1' type='checkbox' id='other_name_secret' />" \
      "<input name='commit' value='Create post' data-disable-with='Create post' type='submit' />"
    end

    assert_dom_equal expected, @rendered
  end

  def test_form_with_enables_remote_by_default
    form_with(model: @post, url: "/", id: "create-post", method: :patch) do |f|
      concat f.text_field(:title)
      concat f.text_area(:body)
      concat f.check_box(:secret)
    end

    expected = whole_form("/", "create-post", method: "patch") do
      "<input name='post[title]' type='text' value='Hello World' id='post_title' />" \
      "<textarea name='post[body]' id='post_body' >\nBack to the hill and over it again!</textarea>" \
      "<input name='post[secret]' type='hidden' value='0' autocomplete='off' />" \
      "<input name='post[secret]' checked='checked' type='checkbox' value='1' id='post_secret' />"
    end

    assert_dom_equal expected, @rendered
  end

  def test_form_is_not_remote_by_default_if_form_with_generates_remote_forms_is_false
    old_value = ActionView::Helpers::FormHelper.form_with_generates_remote_forms
    ActionView::Helpers::FormHelper.form_with_generates_remote_forms = false

    form_with(model: @post, url: "/", id: "create-post", method: :patch) do |f|
      concat f.text_field(:title)
      concat f.text_area(:body)
      concat f.check_box(:secret)
    end

    expected = whole_form("/", "create-post", method: "patch", local: true) do
      "<input name='post[title]' type='text' value='Hello World' id='post_title' />" \
      "<textarea name='post[body]' id='post_body'>\nBack to the hill and over it again!</textarea>" \
      "<input name='post[secret]' type='hidden' value='0' autocomplete='off' />" \
      "<input name='post[secret]' checked='checked' type='checkbox' value='1' id='post_secret' />"
    end

    assert_dom_equal expected, @rendered
  ensure
    ActionView::Helpers::FormHelper.form_with_generates_remote_forms = old_value
  end

  def test_form_with_with_data_attributes
    form_with(model: @post, data: { behavior: "stuff" }) { }
    assert_match %r{data-behavior="stuff"}, @rendered
    assert_match %r{data-remote="true"}, @rendered
  end

  private
    def hidden_fields(options = {})
      method = options[:method]

      if options.fetch(:skip_enforcing_utf8, false)
        txt = +""
      else
        txt = +%(<input name="utf8" type="hidden" value="&#x2713;" autocomplete="off" />)
      end

      if method && !%w[get post].include?(method.to_s)
        txt << %(<input name="_method" type="hidden" value="#{method}" autocomplete="off" />)
      end

      txt
    end

    def form_text(action = "/", id = nil, html_class = nil, local = nil, multipart = nil, method = nil)
      txt =  +%(<form accept-charset="UTF-8") + (action ? %( action="#{action}") : "")
      txt << %( enctype="multipart/form-data") if multipart
      txt << %( data-remote="true") unless local
      txt << %( class="#{html_class}") if html_class
      txt << %( id="#{id}") if id
      method = method.to_s == "get" ? "get" : "post"
      txt << %( method="#{method}">)
    end

    def whole_form(action = "/", id = nil, html_class = nil, local: false, **options)
      contents = block_given? ? yield : ""

      method, multipart = options.values_at(:method, :multipart)

      form_text(action, id, html_class, local, multipart, method) + hidden_fields(options.slice :method, :skip_enforcing_utf8) + contents + "</form>"
    end

    def protect_against_forgery?
      false
    end
end
