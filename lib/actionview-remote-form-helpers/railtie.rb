# frozen_string_literal: true

module ActionViewRemoteFormHelpers
  class Railtie < Rails::Railtie
    initializer "actionview_remote_forms_helper.action_view" do
      ActiveSupport.on_load(:action_view) do
        unless ActionView::Base.respond_to?(:automatically_disable_submit_tag)
          ActionView::Base.cattr_accessor :automatically_disable_submit_tag, default: false

          ActionView::Base.automatically_disable_submit_tag =
            Rails.application.config.action_view.delete(:automatically_disable_submit_tag)
        end

        unless ActionView::Helpers::FormTagHelper.respond_to?(:embed_authenticity_token_in_remote_forms)
          ActionView::Helpers::FormTagHelper.mattr_accessor :embed_authenticity_token_in_remote_forms

          ActionView::Helpers::FormTagHelper.embed_authenticity_token_in_remote_forms =
            Rails.application.config.action_view.delete(:embed_authenticity_token_in_remote_forms)
        end

        unless ActionView::Helpers::FormHelper.respond_to?(:form_with_generates_remote_forms)
          ActionView::Helpers::FormHelper.mattr_accessor :form_with_generates_remote_forms, default: true

          ActionView::Helpers::FormHelper.form_with_generates_remote_forms =
            Rails.application.config.action_view.delete(:form_with_generates_remote_forms)
        end

        ActionView::Base.prepend(ActionViewRemoteFormHelpers)
      end
    end
  end
end
