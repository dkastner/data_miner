require 'data_miner/attribute/standard_attribute'

class DataMiner
  class Attribute
    class Matcher < StandardAttribute
      def initialize(name, options)
        super
        self.matcher = matcher.is_a?(::String) ? matcher.constantize.new : matcher
      end

      def read(row)
        matcher.match(row)
      end
    end
  end
end
