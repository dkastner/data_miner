require 'data_miner/attribute/field_number_attribute'
require 'data_miner/attribute/matcher_attribute'
require 'data_miner/attribute/processor'
require 'data_miner/attribute/row_hash_attribute'
require 'data_miner/attribute/standard_attribute'
require 'data_miner/attribute/static_attribute'
require 'data_miner/attribute/synthesizer_attribute'

class DataMiner
  # A mapping between a local model column and a remote data source column.
  #
  # @see DataMiner::ActiveRecordClassMethods#data_miner Overview of how to define data miner scripts inside of ActiveRecord models.
  # @see DataMiner::Step::Import#store Telling an import step to store a column with DataMiner::Step::Import#store
  # @see DataMiner::Step::Import#key Telling an import step to key on a column with DataMiner::Step::Import#key
  class Attribute
    class InvalidOptionsError < ArgumentError
      def initialize(attribute, errors)
        @attribute = attribute.inspect
        @errors = errors
      end

      def message
        %{[data_miner] Errors on #{@attribute}: #{@errors.join(';')}}
      end
    end
    class MissingUnitsError < RuntimeError
      def initialize(from, to)
        @from = from
        @to = to
      end

      def message
        "[data_miner] Missing units (from=#{from}, to=#{to}"
      end
    end

    class << self
      # @private
      def check_options(options)
        errors = []
        if options[:dictionary].is_a?(Dictionary)
          errors << %{:dictionary must be a Hash of options}
        end
        if (invalid_option_keys = options.keys - VALID_OPTIONS).any?
          errors << %{Invalid options: #{invalid_option_keys.map(&:inspect).to_sentence}}
        end
        if (units_options = options.select { |k, _| k.to_s.include?('units') }).any? and VALID_UNIT_DEFINITION_SETS.none? { |d| d.all? { |required_option| options[required_option].present? } }
          errors << %{#{units_options.inspect} is not a valid set of units definitions. Please supply a set like #{VALID_UNIT_DEFINITION_SETS.map(&:inspect).to_sentence}".}
        end
        errors
      end

      def create(name, options = {})
        options = DEFAULT_OPTIONS.merge options
        name = name.to_sym
        options[:field_name] ||= name

        klass = if options[:matcher]
          MatcherAttribute
        elsif options[:synthesize]
          SynthesizerAttribute
        elsif options.key?(:static)
          StaticAttribute
        elsif options[:field_number]
          FieldNumberAttribute
        elsif options[:field_name] == :row_hash
          RowHashAttribute
        else
          StandardAttribute
        end
        klass.new name, options.slice(*klass.instance_methods)
      end
    end

    # Valid options for an Attribute
    # *synthesize*: Synthesize a value by passing a proc that will receive +row+ and should return a final value.
    #
    # +row+ will be a +Hash+ with string keys or (less often) an +Array+
    #
    # *matcher*: An object that will be sent +#match(row)+ and should return a final value.
    #
    # Can be specified as a String which will be constantized into a class and an object of that class instantized with no arguments.
    #
    # +row+ will be a +Hash+ with string keys or (less often) an +Array+
    #
    # *static*: A static value to be used.
    #
    # *field_number*: Index of where to find the data in the row, starting from zero.
    #
    # If you pass a +Range+, then multiple fields will be joined together.
    #
    # *field_name*: Where to find the data in the row.
    #
    # *delimiter*: A delimiter to be used when joining fields together into a single final value. Used when +:field_number+ is a +Range+.
    #
    # *to_units*: Final units. May invoke a conversion using https://github.com/seamusabshere/conversions
    #
    # If a local column named +[name]_units+ exists, it will be populated with this value.
    #
    # *from_units*: Initial units. May invoke a conversion using https://github.com/seamusabshere/conversions
    #
    # *units_field_number*: If every row specifies its own units, index of where to find the units. Zero-based.
    #
    # *units_field_name*: If every row specifies its own units, where to find the units.
    #
    # *sprintf*: A +sprintf+-style format to apply.
    #
    # *nullify_blank_strings*: Only meaningful for string columns. Whether to store blank input ("    ") as NULL. Defaults to DEFAULT_NULLIFY_BLANK_STRINGS.
    #
    # *overwrite*: Whether to overwrite the value in a local column if it is not null. Defaults to DEFAULT_OVERWRITE.
    VALID_OPTIONS = [
      :from_units,
      :to_units,
      :static,
      :dictionary,
      :matcher,
      :field_name,
      :delimiter,
      :split,
      :units,
      :sprintf,
      :nullify, # deprecated
      :nullify_blank_strings,
      :overwrite,
      :upcase,
      :units_field_name,
      :units_field_number,
      :field_number,
      :chars,
      :synthesize,
    ]
    DEFAULT_OPTIONS = {
      :compress_whitespace => true,
      :delimiter => ', ',
      :nullify_blank_strings => false,
      :overwrite => true,
      :upcase => false
    }

    AVAILABLE_PROCESSORS = [
      :chars,
      :split,
      :blank,
      :compress_whitespace,
      :upcase,
      :convert,
      :sprintf,
      :dictionary
    ]

    DEFAULT_PROCESSORS = {
      :compress_whitespace => true,
      :convert => true
    }

    VALID_UNIT_DEFINITION_SETS = [
      [:units],
      [:from_units, :to_units],
      [:units_field_name],
      [:units_field_name, :to_units],
      [:units_field_number],
      [:units_field_number, :to_units],
    ]
  end
end
