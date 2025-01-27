# frozen_string_literal: true

require "integration_test_helper"
require "rack/test"
require "rails-dom-testing"

module ApplicationTests
  class UploadsIntegrationTest < ActiveSupport::TestCase
    include RailsAppHelpers
    include Rack::Test::Methods
    include Rails::Dom::Testing::Assertions

    def setup
      build_app

      Dir.chdir(tmp_path) do
        run_command("bin/rails", "generate", "model", "user", "name:string")
        run_command("bin/rails", "db:migrate")

        app_file "config/routes.rb", <<~RUBY
          Rails.application.routes.draw do
            resources :users, only: [:new, :create]
            get "form_tag_example", to: "users#form_tag_example"
            get "form_tag_with_remote_example", to: "users#form_tag_with_remote_example"
            get "form_for_example", to: "users#form_for_example"
            get "form_for_with_remote_example", to: "users#form_for_with_remote_example"
          end
        RUBY

        app_file "app/controllers/users_controller.rb", <<~RUBY
          class UsersController < ApplicationController
            def new
              @user = User.new
              render :new
            end

            def form_tag_example
              @user = User.new
              render :form_tag_example
            end

            def form_tag_with_remote_example
              @user = User.new
              render :form_tag_with_remote_example
            end

            def form_for_example
              @user = User.new
              render :form_for_example
            end

            def form_for_with_remote_example
              @user = User.new
              render :form_for_with_remote_example
            end

            def create
              @user = User.new(user_params)

              if @user.save
                redirect_to user_url(@user), notice: "User was successfully created."
              else
                render :new, status: :unprocessable_entity
              end
            end

            private
              def user_params
                params.expect(user: [:name])
              end
          end
        RUBY

        app_file "app/views/users/new.html.erb", <<~ERB
          <%= form_with model: @user, url: users_path do |form| %>
            <%= form.text_field :name %>
            <%= form.submit "Create User" %>
          <% end %>
        ERB

        app_file "app/views/users/form_tag_example.html.erb", <<~ERB
          <%= form_tag users_path do %>
            <%= text_field_tag :name %>
            <%= submit_tag "Create User" %>
          <% end %>
        ERB

        app_file "app/views/users/form_tag_with_remote_example.html.erb", <<~ERB
          <%= form_tag users_path, remote: true do %>
            <%= text_field_tag :name %>
            <%= submit_tag "Create User" %>
          <% end %>
        ERB

        app_file "app/views/users/form_for_example.html.erb", <<~ERB
          <%= form_for @user, url: users_path do |form| %>
            <%= form.text_field :name %>
            <%= form.submit "Create User" %>
          <% end %>
        ERB

        app_file "app/views/users/form_for_with_remote_example.html.erb", <<~ERB
          <%= form_for @user, url: users_path, remote: true do |form| %>
            <%= text_field_tag :name %>
            <%= submit_tag "Create User" %>
          <% end %>
        ERB
      end
    end

    def teardown
      teardown_app
    end

    def test_form_with_defaults
      Dir.chdir(tmp_path) do
        app("development")

        get "/users/new"
        assert_equal 200, last_response.status
        assert_select "form" do
          assert_select "[data-remote]", false
        end
        assert_select 'input[type=submit][data-disable-with="Create User"]'
      end
    end

    def test_form_with_config
      Dir.chdir(tmp_path) do
        add_to_config("config.action_view.form_with_generates_remote_forms = true")
        add_to_config("config.action_view.automatically_disable_submit_tag = false")

        app("development")

        get "/users/new"
        assert_equal 200, last_response.status
        assert_select "form" do
          assert_select "[data-remote=true]"
        end
        assert_select "input[type=submit][data-disable-with]", false
      end
    end

    def test_form_tag_defaults
      Dir.chdir(tmp_path) do
        app("development")

        get "/form_tag_example"
        assert_equal 200, last_response.status
        assert_select "form[data-remote=true]", false
        assert_select "input[name=authenticity_token]"
        assert_select 'input[type=submit][data-disable-with="Create User"]'
      end
    end

    def test_form_tag_with_remote_and_config
      Dir.chdir(tmp_path) do
        add_to_config("config.action_view.embed_authenticity_token_in_remote_forms = false")

        app("development")

        get "/form_tag_with_remote_example"
        assert_equal 200, last_response.status
        assert_select "form[data-remote=true]"
        assert_select "input[name=authenticity_token]", false
        assert_select 'input[type=submit][data-disable-with="Create User"]'
      end
    end

    def test_form_for_defaults
      Dir.chdir(tmp_path) do
        app("development")

        get "/form_for_example"
        assert_equal 200, last_response.status
        assert_select "form[data-remote=true]", false
        assert_select 'input[type=submit][data-disable-with="Create User"]'
      end
    end

    def test_form_for_with_config
      Dir.chdir(tmp_path) do
        add_to_config("config.action_view.form_with_generates_remote_forms = true")
        add_to_config("config.action_view.automatically_disable_submit_tag = false")

        app("development")

        get "/form_for_example"
        assert_equal 200, last_response.status
        assert_select "form[data-remote=true]", false
        assert_select "input[type=submit][data-disable-with]", false
      end
    end

    def test_form_for_with_remote
      Dir.chdir(tmp_path) do
        app("development")

        get "/form_for_with_remote_example"
        assert_equal 200, last_response.status
        assert_select "form[data-remote=true]"
        assert_select 'input[type=submit][data-disable-with="Create User"]'
      end
    end

    private
      def document_root_element
        Nokogiri::HTML5.parse(last_response.body)
      end
  end
end
