require "gravitype/list_type"
require "gravitype/Introspection"

require "ruby-progressbar"

module Gravitype
  class Introspection
    class Data < Introspection
      def introspect(fields_with_getters = exposed_fields_and_getters)
        progressbar = ProgressBar.create(total: @model.all.count + fields_with_getters.size)

        # For each document in the DB, get the type of each field’s values.
        fields_with_classes = Hash.new { |h,k| h[k] = Set.new }
        @model.all.each do |doc|
          fields_with_getters.each do |field, getter|
            value = doc.send(getter)
            if value.is_a?(Hash)
              fields_with_classes[field] << {
                List.for_list(Set.new(value.keys)) => List.for_list(Set.new(value.values))
              }
            elsif list = List.for_list(value)
              fields_with_classes[field] << list
            else
              fields_with_classes[field] << value.class
            end
          end
          progressbar.increment
        end

        # Merge all type sets for each field to a single set.
        fields_with_classes.each do |field, classes|
          lists = classes.select { |x| x.is_a?(List) }
          unless lists.empty?
            classes.delete_if { |x| x.is_a?(List) }
            classes << lists.reduce(:+).to_list
          end
          hashes = classes.select { |x| x.is_a?(Hash) }
          unless hashes.empty?
            classes.delete_if { |x| x.is_a?(Hash) }
            keys = hashes.map(&:keys).flatten.reduce(:+).to_list
            values = hashes.map(&:values).flatten.reduce(:+).to_list
            classes << { keys => values }
          end
          progressbar.increment
        end

        fields_with_classes
      end
    end
  end
end
