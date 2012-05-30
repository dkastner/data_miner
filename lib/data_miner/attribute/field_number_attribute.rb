require 'data_miner/attribute/standard_attribute'

class DataMiner
  class Attribute
    class FieldNumberAttribute < StandardAttribute
      attr_accessor :field_number

      def value(row)
        if field_number.is_a?(::Range)
          field_number.map { |n| row[n] }.join(delimiter)
        else
          row[field_number]
        end
      end
    end
  end
end
