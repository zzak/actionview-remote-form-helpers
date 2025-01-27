# frozen_string_literal: true

require "active_support/all"

require "action_view"
require "action_view/test_case"

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "actionview-remote-form-helpers"

require "minitest/autorun"

class ActionViewRemoteFormHelpersTestCase < ActionView::TestCase
  def setup
    @post = Post.new
    def @post.id; 0; end
    def @post.to_param; "123"; end

    @post.persisted   = true
    @post.title       = "Hello World"
    @post.body        = "Back to the hill and over it again!"
  end

  Routes = ActionDispatch::Routing::RouteSet.new
  Routes.draw do
    resources :posts
  end

  include Routes.url_helpers

  def url_for(options)
    if options.is_a?(Hash)
      "http://www.example.com"
    else
      super
    end
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
end

unless ActionView::Base.respond_to?(:automatically_disable_submit_tag)
  ActionView::Base.cattr_accessor :automatically_disable_submit_tag, default: true
end

unless ActionView::Helpers::FormTagHelper.respond_to?(:embed_authenticity_token_in_remote_forms)
  ActionView::Helpers::FormTagHelper.mattr_accessor :embed_authenticity_token_in_remote_forms
end

unless ActionView::Helpers::FormHelper.respond_to?(:form_with_generates_remote_forms)
  ActionView::Helpers::FormHelper.mattr_accessor :form_with_generates_remote_forms, default: true
end
