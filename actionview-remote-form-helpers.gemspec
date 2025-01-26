# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "actionview-remote-form-helpers"
  spec.version = "1.0.0"
  spec.authors = ["zzak"]
  spec.email = ["zzakscott@gmail.com"]

  spec.summary = "Rails legacy support for `form` with `remote` options."
  spec.description = "For apps that are still using `remote` and `local` options in `form_with`."
  spec.homepage = "https://github.com/rails/actionview-remote-form-helpers"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/rails/actionview-remote-form-helpers/releases"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[test/ .git .github Gemfile])
    end
  end
  spec.require_paths = ["lib"]
end
