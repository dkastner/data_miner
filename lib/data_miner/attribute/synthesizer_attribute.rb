require 'data_miner/attribute/standard_attribute'

class DataMiner
  class Attribute
    class SynthesizerAttribute < StandardAttribute
      attr_accessor :synthesize

      def read(row)
        synthesize.call(row)
      end
    end
  end
end
