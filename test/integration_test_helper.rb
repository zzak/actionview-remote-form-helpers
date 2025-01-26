# frozen_string_literal: true

require 'rails'
require "rails/test_help"
require "fileutils"
require "digest/sha1"

# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

module RailsAppHelpers
  def self.included(base)
    base.include ActiveSupport::Testing::Isolation
  end

  private
    def create_new_rails_app(app_dir, options=[])
      require "rails/generators/rails/app/app_generator"
      Rails::Generators::AppGenerator.start([app_dir, *options, "--skip-bundle", "--skip-bootsnap", "--quiet"])

      Dir.chdir(app_dir) do
        gemfile = File.read("Gemfile")

        gemfile << %(gem "actionview-remote-form-helpers", path: #{File.expand_path("..", __dir__).inspect}\n)

        if Rails::VERSION::PRE == "alpha"
          gemfile.gsub!(/^gem ["']rails["'].*/, "")
          gemfile << %(gem "rails", path: #{Gem.loaded_specs["rails"].full_gem_path.inspect}\n)
        end

        if Gem::Requirement.new("< 8.0").satisfied_by?(Gem::Version.new(Rails.version))
          gemfile << %(gem "concurrent-ruby", "1.3.4"\n)
        end

        if Gem::Requirement.new("< 7.0").satisfied_by?(Gem::Version.new(Rails.version))
          str = "<%= javascript_pack_tag 'application', 'data-turbolinks-track': 'reload' %>"
          file = "app/views/layouts/application.html.erb"
          remove_from_file(file, str)

          gemfile.gsub!(/^gem ["']webpacker["'].*/, "")
        end

        File.write("Gemfile", gemfile)

        add_to_config(%(config.hosts << "example.org"))

        run_command("bundle", "install")
      end
    end

    def build_app(options=[])
      create_new_rails_app(tmp_path, options)
    end

    def teardown_app
      FileUtils.rm_rf(tmp_path)
    end

    def tmp_path
      @tmp_path ||=
        (
          variant = [RUBY_VERSION, Gem.loaded_specs["rails"].full_gem_path,]
          app_name = "app_#{Digest::SHA1.hexdigest(variant.to_s)}"
          Dir.mktmpdir(app_name)
        )
    end

    def run_command(*command)
      Bundler.with_unbundled_env do
        capture_subprocess_io { system(*command, exception: true) }
      end
    end

    def app_file(path, contents, mode = "w")
      file_name = "#{path}"
      FileUtils.mkdir_p File.dirname(file_name)
      File.open(file_name, mode) do |f|
        f.puts contents
      end
      file_name
    end

    def app(env = "production")
      old_env = ENV["RAILS_ENV"]
      @app ||= begin
        ENV["RAILS_ENV"] = env

        require "./config/environment"

        Rails.application
      end
    ensure
      ENV["RAILS_ENV"] = old_env
    end

    def add_to_config(str)
      environment = File.read("config/application.rb")
      if environment =~ /(\n\s*end\s*end\s*)\z/
        File.open("config/application.rb", "w") do |f|
          f.puts $` + "\n#{str}\n" + $1
        end
      end
    end

    def remove_from_config(str)
      remove_from_file("config/application.rb", str)
    end

    def remove_from_file(file, str)
      contents = File.read(file)
      contents.gsub!(/#{str}/, "")
      File.write(file, contents)
    end
end
