$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "gravitype"

require "mongoid"
require "mongoid-cached-json"

ENV["TESTING"] = "1"

Mongoid.configure do |config|
  config.connect_to("localhost")
  config.logger.level = Logger::INFO
end
Mongo::Logger.logger = Mongoid.logger

require "minitest/around"
require "minitest/autorun"
require "minitest/focus"
require "minitest/reporters"

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

require "database_cleaner"
DatabaseCleaner[:mongoid].strategy = :truncation
class Minitest::Spec
  around do |tests|
    DatabaseCleaner.cleaning(&tests)
  end
end

class TestDoc
  include Mongoid::Document
  include Mongoid::CachedJson

  Mongoid::Fields::TYPE_MAPPINGS.each do |name, type|
    field "mongoid_#{name}", type: type
  end

  def ruby_method?
    "string"
  end

  json_fields({
    ruby_method:    { properties: :short, definition: :ruby_method? },
    ruby_proc:      { properties: :all,   definition: lambda { |instance| :ok } },
    mongoid_string: { properties: :short },
    mongoid_array:  { properties: :public },
    mongoid_hash:   { properties: :all },
  })
end

Gravitype::Type::DSL.define_scalar_type("TrueClass", TrueClass)
Gravitype::Type::DSL.define_scalar_type("FalseClass", FalseClass)
Gravitype::Type::DSL.define_scalar_type("Fixnum", Fixnum)
