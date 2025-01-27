# frozen_string_literal: true

require "test_helper"

require "lib/controller/fake_models"

class FormTagHelperTest < ActionViewRemoteFormHelpersTestCase
  tests ActionViewRemoteFormHelpers

  def form_text(action = "http://www.example.com", options = {})
    remote, enctype, html_class, id, method = options.values_at(:remote, :enctype, :html_class, :id, :method)

    method = method.to_s == "get" ? "get" : "post"

    txt =  +%(<form accept-charset="UTF-8") + (action ? %( action="#{action}") : "")
    txt << %( enctype="multipart/form-data") if enctype
    txt << %( data-remote="true") if remote
    txt << %( class="#{html_class}") if html_class
    txt << %( id="#{id}") if id
    txt << %( method="#{method}">)
  end

  def whole_form(action = "http://www.example.com", options = {})
    out = form_text(action, options) + hidden_fields(options)

    if block_given?
      out << yield << "</form>"
    end

    out
  end

  def test_form_tag
    actual = form_tag
    expected = whole_form
    assert_dom_equal expected, actual
  end

  def test_form_tag_with_remote
    actual = form_tag({}, { remote: true })

    expected = whole_form("http://www.example.com", remote: true)
    assert_dom_equal expected, actual
  end

  def test_form_tag_with_remote_false
    actual = form_tag({}, { remote: false })

    expected = whole_form
    assert_dom_equal expected, actual
  end

  def test_submit_tag
    assert_dom_equal(
      %(<input name='commit' data-disable-with="Saving..." onclick="alert(&#39;hello!&#39;)" type="submit" value="Save" />),
      submit_tag("Save", onclick: "alert('hello!')", data: { disable_with: "Saving..." })
    )
  end

  def test_empty_submit_tag
    assert_dom_equal(
      %(<input data-disable-with="Save" name='commit' type="submit" value="Save" />),
      submit_tag("Save")
    )
  end

  def test_empty_submit_tag_with_opt_out
    with_auto_disable_submit_tag(false) do
      assert_dom_equal(
        %(<input name='commit' type="submit" value="Save" />),
        submit_tag("Save")
      )
    end
  end

  def test_empty_submit_tag_with_opt_out_and_explicit_disabling
    with_auto_disable_submit_tag(false) do
      assert_dom_equal(
        %(<input name='commit' type="submit" value="Save" />),
        submit_tag("Save", data: { disable_with: false })
      )
    end
  end

  def test_submit_tag_having_data_disable_with_string
    assert_dom_equal(
      %(<input data-disable-with="Processing..." data-confirm="Are you sure?" name='commit' type="submit" value="Save" />),
      submit_tag("Save", "data-disable-with" => "Processing...", "data-confirm" => "Are you sure?")
    )
  end

  def test_submit_tag_having_data_disable_with_boolean
    assert_dom_equal(
      %(<input data-confirm="Are you sure?" name='commit' type="submit" value="Save" />),
      submit_tag("Save", "data-disable-with" => false, "data-confirm" => "Are you sure?")
    )
  end

  def test_submit_tag_having_data_hash_disable_with_boolean
    assert_dom_equal(
      %(<input data-confirm="Are you sure?" name='commit' type="submit" value="Save" />),
      submit_tag("Save", data: { confirm: "Are you sure?", disable_with: false })
    )
  end

  def test_submit_tag_with_no_onclick_options
    assert_dom_equal(
      %(<input name='commit' data-disable-with="Saving..." type="submit" value="Save" />),
      submit_tag("Save", data: { disable_with: "Saving..." })
    )
  end

  def test_submit_tag_with_confirmation
    assert_dom_equal(
      %(<input name='commit' type='submit' value='Save' data-confirm="Are you sure?" data-disable-with="Save" />),
      submit_tag("Save", data: { confirm: "Are you sure?" })
    )
  end

  def test_submit_tag_doesnt_have_data_disable_with_twice
    assert_equal(
      %(<input type="submit" name="commit" value="Save" data-confirm="Are you sure?" data-disable-with="Processing..." />),
      submit_tag("Save", "data-disable-with" => "Processing...", "data-confirm" => "Are you sure?")
    )
  end

  def test_submit_tag_doesnt_have_data_disable_with_twice_with_hash
    assert_equal(
      %(<input type="submit" name="commit" value="Save" data-disable-with="Processing..." />),
      submit_tag("Save", data: { disable_with: "Processing..." })
    )
  end

  def test_submit_tag_with_symbol_value
    assert_dom_equal(
      %(<input data-disable-with="Save" name='commit' type="submit" value="Save" />),
      submit_tag(:Save)
    )
  end

  def test_button_tag_with_confirmation
    assert_dom_equal(
      %(<button name="button" type="submit" data-confirm="Are you sure?">Save</button>),
      button_tag("Save", type: "submit", data: { confirm: "Are you sure?" })
    )
  end

  def test_button_tag_with_data_disable_with_option
    assert_dom_equal(
      %(<button name="button" type="submit" data-disable-with="Please wait...">Checkout</button>),
      button_tag("Checkout", data: { disable_with: "Please wait..." })
    )
  end

  def test_image_submit_tag_with_confirmation
    assert_dom_equal(
      %(<input type="image" src="/images/save.gif" data-confirm="Are you sure?" />),
      image_submit_tag("save.gif", data: { confirm: "Are you sure?" })
    )
  end

  private
    def root_elem(rendered_content)
      Rails::Dom::Testing.html_document_fragment.parse(rendered_content).children.first # extract from nodeset
    end

    def with_auto_disable_submit_tag(value)
      old_value = ActionView::Base.automatically_disable_submit_tag
      ActionViewRemoteFormHelpers._deprecator.silence do
        ActionView::Base.automatically_disable_submit_tag = value
      end
      yield
    ensure
      ActionViewRemoteFormHelpers._deprecator.silence do
        ActionView::Base.automatically_disable_submit_tag = old_value
      end
    end
end
