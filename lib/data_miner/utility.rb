class DataMiner
  module Utility
    extend self

    INNER_SPACE = /[ ]+/

    def downcase(str)
      defined?(::UnicodeUtils) ? ::UnicodeUtils.downcase(str) : str.downcase
    end

    def upcase(str)
      defined?(::UnicodeUtils) ? ::UnicodeUtils.upcase(str) : str.upcase
    end

    def compress_whitespace(str)
      str.gsub(INNER_SPACE, ' ').strip
    end

    def units_field(row, field_name, field_number)
      field = field_name || field_number
      if field && units = row[field]
        compress_whitespace(units).underscore.to_sym
      end
    end
  end
end
