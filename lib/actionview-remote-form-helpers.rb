# frozen_string_literal: true

require "actionview-remote-form-helpers/railtie" if defined?(Rails::Railtie)

module ActionViewRemoteFormHelpers
  def form_for(record, options = {}, &block)
    remote = options[:remote]

    if remote && !ActionView::Helpers::FormTagHelper.embed_authenticity_token_in_remote_forms && options[:authenticity_token].blank?
      options[:authenticity_token] = false
    end

    options[:local] = !remote

    super
  end

  def form_tag(url_for_options = {}, options = {}, &block)
    options = _remote_html_options(options)
    super
  end

  def form_with(model: false, scope: nil, url: nil, format: nil, **options, &block)
    options[:html] = _html_options_for_form_with(local: options[:local] || !ActionView::Helpers::FormHelper.form_with_generates_remote_forms, **options)
    super
  end

  def submit_tag(value = "Save changes", options = {})
    return super if ActionView.version < "8.2.0.alpha"
    options = options.deep_stringify_keys
    tag_options = { "type" => "submit", "name" => "commit", "value" => value }.update(options)
    _set_default_disable_with(value, tag_options)
    super(value, tag_options)
  end

  private
    def _remote_html_options(options)
      options.symbolize_keys.tap do |options|
        if options.delete(:remote)
          options[:data] ||= {}
          options[:data][:remote] = true

          if ActionView::Helpers::FormTagHelper.embed_authenticity_token_in_remote_forms == false && options["authenticity_token"].blank?
            options["authenticity_token"] = false
          elsif options["authenticity_token"] == true
            options["authenticity_token"] = nil
          end
        end
      end
    end

    def _html_options_for_form_with(html: {}, local: false, **options)
      html_options = options.slice(:id, :class, :multipart, :method, :data, :authenticity_token).merge!(html)
      html_options[:remote] = html.delete(:remote) || !local
      _remote_html_options(html_options)
    end

    def _set_default_disable_with(value, tag_options)
      data = tag_options.fetch("data", {})

      if tag_options["data-disable-with"] == false || data["disable_with"] == false
        data.delete("disable_with")
      elsif ActionView::Base.automatically_disable_submit_tag
        disable_with_text = tag_options["data-disable-with"]
        disable_with_text ||= data["disable_with"]
        disable_with_text ||= value.to_s.clone
        tag_options.deep_merge!("data" => { "disable_with" => disable_with_text })
      end

      tag_options.delete("data-disable-with")
    end
end
