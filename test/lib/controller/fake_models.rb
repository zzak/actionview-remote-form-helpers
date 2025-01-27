# frozen_string_literal: true

require "active_model"

Post = Struct.new(:title, :author_name, :body, :persisted) do
  extend ActiveModel::Naming
  include ActiveModel::Conversion

  alias_method :persisted?, :persisted
end

module Blog
  def self.use_relative_model_naming?
    true
  end

  Post = Struct.new(:title, :id) do
    extend ActiveModel::Naming
    include ActiveModel::Conversion

    def persisted?
      id.present?
    end
  end
end
