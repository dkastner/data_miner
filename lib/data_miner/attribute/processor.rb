require 'conversions'

class DataMiner
  class Attribute
    class Processor
      def initialize(config)
        config.each do |key, value|
          self.send "#{key}=", value
        end
      end

      class Chars < Processor
        attr_accessor :chars

        def process(value)
          value[chars]
        end
      end

      class Split < Processor
        DEFAULT_PATTERN = /\s+/
        DEFAULT_KEEP = 0

        attr_accessor :split

        def initialize(config)
          super
          split.symbolize_keys!
        end

        def process(value, row)
          pattern = split.fetch :pattern, DEFAULT_SPLIT_PATTERN
          keep = split.fetch :keep, DEFAULT_SPLIT_KEEP
          value = value.to_s.split(pattern)[keep].to_s
        end
      end

      class NullifyBlankStrings < Processor
        attr_accessor :column_type, :nullify_blank_strings

        def process(value, row)
          if value.blank? and (not stringlike_column? or nullify_blank_strings)
            return
          else
            value
          end
        end

        def stringlike_column?
          column_type == :string
        end
      end
      class Nullify < NullifyBlankStrings; end

      class CompressWhitespace < Processor
        def process(value, row)
          DataMiner::Utility.compress_whitespace value
        end
      end

      class Upcase < Processor
        def process(value, row)
          DataMiner::Utility.upcase value
        end
      end

      class Convert < Processor
        attr_accessor :from_units, :to_units, :units,
          :units_field_name, :units_field_number

        def initialize(options)
          super
          self.to_units ||= options[:units]
        end

        def process(value, row)
          if convert?
            final_from_units = from_units || DataMiner::Utility.units_field(row, units_field_name, units_field_number)
            final_to_units = to_units || DataMiner::Utility.units_field(row, units_field_name, units_field_number)
            if final_from_units.blank? or final_to_units.blank?
              fail MissingUnitsError, final_from_units.inspect, final_to_units.inspect
            end
            value = value.to_f.convert final_from_units, final_to_units
          else
            value
          end
        end

        def convert?
          from_units.present? or units_field_name.present? or units_field_number.present?
        end
      end

      class Sprintf < Processor
        attr_accessor :sprintf

        def process(value, row)
          if sprintf.end_with?('f')
            value = value.to_f
          elsif sprintf.end_with?('d')
            value = value.to_i
          end
          sprintf % value
        end
      end  

      class Dictionary < Processor
        def initialize(config)
          @dictionary_mutex = Mutex.new
          refresh
        end

        def refresh
          @dictionary_mutex.synchronize do
            @dictionary = DataMiner::Dictionary.new(config)
          end
        end

        def process(value, row)
          @dictionary.lookup(value)
        end
      end
    end
  end
end
