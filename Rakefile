# frozen_string_literal: true

require "bundler/gem_tasks"
require "minitest/test_task"

Minitest::TestTask.create do |test|
  test.verbose = true
  test.test_globs = ["test/actionview-remote-form-helpers/test_*.rb"]
end

Minitest::TestTask.create("test:integration") do |t|
  t.test_globs = ["test/test_actionview-remote-form-helpers.rb"]
  t.verbose = true
  t.warning = true
end

task default: :test
