# frozen_string_literal: true

require "active_support/all"

require "action_view"
require "action_view/test_case"

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "actionview-remote-form-helpers"

require "minitest/autorun"

module RenderERBUtils
  def view
    @view ||= begin
      path = ActionView::FileSystemResolver.new(FIXTURE_LOAD_PATH)
      view_paths = ActionView::PathSet.new([path])
      view = ActionView::Base.with_empty_template_cache
      view.with_view_paths(view_paths)
    end
  end

  def render_erb(string)
    @virtual_path = nil

    template = ActionView::Template.new(
      string.strip,
      "test template",
      ActionView::Template.handler_for_extension(:erb),
      format: :html, locals: [])

    view = ActionView::Base.with_empty_template_cache
    template.render(view.empty, {}).strip
  end
end

class BasicController
  attr_accessor :request, :response

  def config
    @config ||= ActiveSupport::InheritableOptions.new(ActionController::Base.config).tap do |config|
      # VIEW TODO: View tests should not require a controller
      public_dir = File.expand_path("fixtures/public", __dir__)
      config.assets_dir = public_dir
      config.javascripts_dir = "#{public_dir}/javascripts"
      config.stylesheets_dir = "#{public_dir}/stylesheets"
      config.assets          = ActiveSupport::InheritableOptions.new(prefix: "assets")
      config
    end
  end
end

ActionView::RoutingUrlFor.include(ActionDispatch::Routing::UrlFor)

unless ActionView::Base.respond_to?(:automatically_disable_submit_tag)
  ActionView::Base.cattr_accessor :automatically_disable_submit_tag, default: true
end

unless ActionView::Helpers::FormTagHelper.respond_to?(:embed_authenticity_token_in_remote_forms)
  ActionView::Helpers::FormTagHelper.mattr_accessor :embed_authenticity_token_in_remote_forms
end

unless ActionView::Helpers::FormHelper.respond_to?(:form_with_generates_remote_forms)
  ActionView::Helpers::FormHelper.mattr_accessor :form_with_generates_remote_forms, default: true
end
