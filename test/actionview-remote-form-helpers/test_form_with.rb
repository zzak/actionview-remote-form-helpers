# frozen_string_literal: true

require "test_helper"

require "lib/controller/fake_models"

class FormWithTest < ActionViewRemoteFormHelpersTestCase
  tests ActionViewRemoteFormHelpers

  def form_with(*, **)
    @rendered = super
  end

  def form_text(action = "/", id = nil, html_class = nil, local = nil, method = nil)
    txt =  +%(<form accept-charset="UTF-8") + (action ? %( action="#{action}") : "")
    txt << %( data-remote="true") unless local
    txt << %( class="#{html_class}") if html_class
    txt << %( id="#{id}") if id
    method = method.to_s == "get" ? "get" : "post"
    txt << %( method="#{method}">)
  end

  def whole_form(action = "/", id = nil, html_class = nil, local: false, **options)
    contents = block_given? ? yield : ""

    method = options.values_at(:method)

    form_text(action, id, html_class, local, method) + hidden_fields(options.slice :method) + contents + "</form>"
  end

  def test_form_with
    form_with(model: @post, id: "create-post") do |f|
      concat f.label(:title) { "The Title" }
      concat f.text_field(:title)
      concat f.text_area(:body)
      concat f.select(:category, %w[ animal economy sports ])
      concat f.submit("Create post")
      concat f.button("Create post")
      concat f.button {
        concat content_tag(:span, "Create post")
      }
    end

    expected = whole_form("/posts/123", "create-post", method: "patch") do
      "<label>The Title</label>" \
      "<input name='post[title]' type='text' value='Hello World' />" \
      "<textarea name='post[body]'>\nBack to the hill and over it again!</textarea>" \
      "<select name='post[category]'><option value='animal'>animal</option>\n<option value='economy'>economy</option>\n<option value='sports'>sports</option></select>" \
      "<input name='commit' data-disable-with='Create post' type='submit' value='Create post' />" \
      "<button name='button' type='submit'>Create post</button>" \
      "<button name='button' type='submit'><span>Create post</span></button>"
    end

    assert_dom_equal expected, @rendered
  end

  def test_form_with_enables_remote_by_default
    form_with(model: @post, url: "/", id: "create-post", method: :patch) do |f|
      concat f.text_field(:title)
      concat f.text_area(:body)
    end

    expected = whole_form("/", "create-post", method: "patch") do
      "<input name='post[title]' type='text' value='Hello World' />" \
      "<textarea name='post[body]' >\nBack to the hill and over it again!</textarea>" \
    end

    assert_dom_equal expected, @rendered
  end

  def test_form_is_not_remote_by_default_if_form_with_generates_remote_forms_is_false
    with_generates_remote_forms(false) do
      form_with(model: @post, url: "/", id: "create-post", method: :patch) do |f|
        concat f.text_field(:title)
        concat f.text_area(:body)
      end

      expected = whole_form("/", "create-post", method: "patch", local: true) do
        "<input name='post[title]' type='text' value='Hello World' />" \
        "<textarea name='post[body]'>\nBack to the hill and over it again!</textarea>" \
      end

      assert_dom_equal expected, @rendered
    end
  end

  def test_form_with_with_data_attributes
    form_with(model: @post, data: { behavior: "stuff" }) { }
    assert_match %r{data-behavior="stuff"}, @rendered
    assert_match %r{data-remote="true"}, @rendered
  end

  private
    def with_generates_remote_forms(value)
      old_value = ActionView::Helpers::FormHelper.form_with_generates_remote_forms
      ActionViewRemoteFormHelpers._deprecator.silence do
        ActionView::Helpers::FormHelper.form_with_generates_remote_forms = value
      end
      yield
    ensure
      ActionViewRemoteFormHelpers._deprecator.silence do
        ActionView::Helpers::FormHelper.form_with_generates_remote_forms = old_value
      end
    end
end
