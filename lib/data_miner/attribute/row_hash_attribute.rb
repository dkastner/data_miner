require 'data_miner/attribute/standard_attribute'

class DataMiner
  class Attribute
    class RowHashAttribute < StandardAttribute
      def value(row)
        row.row_hash
      end
    end
  end
end
