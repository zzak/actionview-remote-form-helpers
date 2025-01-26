# frozen_string_literal: true

require "test_helper"

require "lib/controller/fake_models"

class FormForHelperTest < ActionView::TestCase
  include RenderERBUtils

  tests ActionViewRemoteFormHelpers

  def form_for(*)
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

    namespace(:cpk) do
      resources(:books)
    end

    get "/foo", to: "controller#action"
    root to: "main#index"
  end

  def _routes
    Routes
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

  class FooTag < ActionView::Helpers::Tags::Base
    def initialize; end
  end

  def test_form_for
    form_for(@post, html: { id: "create-post" }) do |f|
      concat f.label(:title) { "The Title" }
      concat f.text_field(:title)
      concat f.text_area(:body)
      concat f.check_box(:secret)
      concat f.submit("Create post")
      concat f.button("Create post")
      concat f.button {
        concat content_tag(:span, "Create post")
      }
    end

    expected = whole_form("/posts/123", "create-post", "edit_post", method: "patch") do
      "<label for='post_title'>The Title</label>" \
      "<input name='post[title]' type='text' id='post_title' value='Hello World' />" \
      "<textarea name='post[body]' id='post_body'>\nBack to the hill and over it again!</textarea>" \
      "<input name='post[secret]' type='hidden' value='0' autocomplete='off' />" \
      "<input name='post[secret]' checked='checked' type='checkbox' id='post_secret' value='1' />" \
      "<input name='commit' data-disable-with='Create post' type='submit' value='Create post' />" \
      "<button name='button' type='submit'>Create post</button>" \
      "<button name='button' type='submit'><span>Create post</span></button>"
    end

    assert_dom_equal expected, @rendered

    assert_no_match %r{data-remote="true"}, @rendered
  end

  def test_form_for_with_html_options_adds_options_to_form_tag
    form_for(@post, html: { id: "some_form", class: "some_class", multipart: true }) do |f| end
    expected = whole_form("/posts/123", "some_form", "some_class", method: "patch", multipart: "multipart/form-data")

    assert_dom_equal expected, @rendered
  end

  def test_form_for_with_data_attributes
    form_for(@post, data: { behavior: "stuff" }, remote: true) { }
    assert_match %r{data-behavior="stuff"}, @rendered
    assert_match %r{data-remote="true"}, @rendered
  end

  private
    def hidden_fields(options = {})
      method = options[:method]

      if options.fetch(:enforce_utf8, true)
        txt = +%(<input name="utf8" type="hidden" value="&#x2713;" autocomplete="off" />)
      else
        txt = +""
      end

      if method && !%w[get post].include?(method.to_s)
        txt << %(<input name="_method" type="hidden" value="#{method}" autocomplete="off" />)
      end

      txt
    end

    def form_text(action = "/", id = nil, html_class = nil, remote = nil, multipart = nil, method = nil)
      txt =  +%(<form accept-charset="UTF-8") + (action ? %( action="#{action}") : "")
      txt << %( enctype="multipart/form-data") if multipart
      txt << %( data-remote="true") if remote
      txt << %( class="#{html_class}") if html_class
      txt << %( id="#{id}") if id
      method = method.to_s == "get" ? "get" : "post"
      txt << %( method="#{method}">)
    end

    def whole_form(action = "/", id = nil, html_class = nil, options = {})
      contents = block_given? ? yield : ""

      method, remote, multipart = options.values_at(:method, :remote, :multipart)

      form_text(action, id, html_class, remote, multipart, method) + hidden_fields(options.slice :method, :enforce_utf8) + contents + "</form>"
    end

    def protect_against_forgery?
      false
    end

    def with_default_enforce_utf8(value)
      old_value = ActionView::Helpers::FormTagHelper.default_enforce_utf8
      ActionView::Helpers::FormTagHelper.default_enforce_utf8 = value

      yield
    ensure
      ActionView::Helpers::FormTagHelper.default_enforce_utf8 = old_value
    end
end
