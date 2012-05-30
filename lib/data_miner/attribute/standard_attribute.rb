class DataMiner
  class Attribute
    class StandardAttribute
      # Local column name.
      # @return [Symbol]
      attr_reader :name

      attr_accessor :overwrite, :to_units, :from_units,
        :units_field_number, :units_field_name,
        :sprintf, :nullify_blank_strings,
        :delimiter, :chars, :field_name

      def initialize(name, options)
        @name = name.to_sym
        options = options.symbolize_keys
        if (errors = Attribute.check_options(options)).any?
          fail InvalidOptionsError, errors
        end
        options.each do |n, value|
          send "#{n}=", value
        end

        processor_list = DEFAULT_PROCESSORS.merge(options.slice AVAILABLE_PROCESSORS)
        puts processor_list.inspect
        @processors = processor_list.map do |name, value|
          if value
            klass = Processor.const_get name.to_s.camelize
            klass.new options.slice(klass.instance_methods)
          end
        end
      end

      def set_from_row(local_record, remote_row)
        previously_nil = local_record.send(name).nil?
        currently_nil = false

        if previously_nil or overwrite
          new_value = read remote_row
          if new_value.blank? and (local_record.class.columns_hash[name.to_s].type != :string or nullify_blank_strings)
            new_value = nil
          end
          local_record.send "#{name}=", new_value
          currently_nil = new_value.nil?
        end

        final_to_units = (to_units || DataMiner::Utility.units_field(remote_row, units_field_name, units_field_number))
        if not currently_nil and units? and final_to_units
          local_record.send "#{name}_units=", final_to_units
        end
      end

      def read(row)
        process(value(row).to_s, row)
      end

      def value(row)
        row[field_name.to_s]
      end

      def convertible?(options)
        from_units.present? or units_field_name.present? or units_field_number.present?
      end

      def process(value, row)
        if value.nil?
          return
        elsif value.is_a? ::ActiveRecord::Base
          return value
        else
          @processors.inject(value) do |processed_value, processor|
            processed_value = processor.process(processed_value, row) unless processed_value.nil?
            processed_value
          end
        end
      end

      def refresh
        dictionary_processor.refresh if dictionary_processor
      end

      def dictionary_processor
        @dictionary_processor ||= @processors.find { |p| p.is_a? Processor::Dictionary }
      end
          
      def units?
        to_units.present? or units_field_name.present? or units_field_number.present?
      end
    end
  end
end
