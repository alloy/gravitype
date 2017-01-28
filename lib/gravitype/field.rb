require "gravitype/type"
require "active_support/core_ext/object/duplicable"

module Gravitype
  class Field
    attr_reader :name, :type

    def initialize(name, type)
      @name, @type = name, type
    end

    def merge!(other)
      raise ArgumentError, "Cannot merge anything but fields" unless other.is_a?(Field)
      raise ArgumentError, "Different field name" unless @name == other.name
      @type += other.type
      self
    end

    def merge(other)
      Field.new(@name, @type).tap do |field|
        field.merge!(other)
      end
    end

    def normalize
      normalized_type = Type::Compound.new

      # Find any array types, add them all together, and wrap them as a single array.
      arrays = @type.types.select { |type| type.type == Array }
      unless arrays.empty?
        normalized_type += Type::Array.new(arrays.map(&:values).reduce(:+).types.to_a)
      end

      sets = @type.types.select { |type| type.type == Set }
      unless sets.empty?
        normalized_type += Type::Set.new(sets.map(&:values).reduce(:+).types.to_a)
      end

      # If there’s only 1 type, unwrap it from the compound type.
      normalized_type = normalized_type.types.first if normalized_type.types.size == 1

      Field.new(@name, normalized_type)
    end
  end
end
