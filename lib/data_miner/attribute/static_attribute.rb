require 'data_miner/attribute/standard_attribute'

class DataMiner
  class Attribute
    class StaticAttribute < StandardAttribute
      attr_accessor :static

      def value(row)
        static
      end
    end
  end
end
