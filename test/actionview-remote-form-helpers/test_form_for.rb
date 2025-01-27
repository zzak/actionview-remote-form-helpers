# frozen_string_literal: true

require "test_helper"

require "lib/controller/fake_models"

class FormForHelperTest < ActionViewRemoteFormHelpersTestCase
  tests ActionViewRemoteFormHelpers

  def form_for(*)
    @rendered = super
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

  def test_form_for
    form_for(@post, html: { id: "create-post" }) do |f|
      concat f.label(:title) { "The Title" }
      concat f.text_field(:title)
      concat f.text_area(:body)
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
end
