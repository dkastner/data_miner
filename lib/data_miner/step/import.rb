require 'errata'
require 'remote_table'

class DataMiner
  class Step
    # A step that imports data from a remote source.
    #
    # Create these by calling +import+ inside a +data_miner+ block.
    #
    # @see DataMiner::ActiveRecordClassMethods#data_miner Overview of how to define data miner scripts inside of ActiveRecord models.
    # @see DataMiner::Script#import Creating an import step by calling DataMiner::Script#import from inside a data miner script
    # @see DataMiner::Attribute The Attribute class, which maps local columns and remote data fields from within an import step
    class Import < Step
      class InvalidSettingError < ArgumentError; end
      class DuplicateColumnError < StandardError
        def initialize(model, attribute)
          @model = model
          @attribute = attribute
        end

        def message
          "You should only call store or key once for #{@model.name}##{@attribute}"
        end
      end

      # The mappings of local columns to remote data source fields.
      # @return [Array<DataMiner::Attribute>]
      attr_reader :attributes

      # @private
      attr_reader :script

      # Description of what this step does.
      # @return [String]
      attr_reader :description
      
      # @private
      def initialize(script, description, table_and_errata_settings, &blk)
        table_and_errata_settings = table_and_errata_settings.symbolize_keys
        if table_and_errata_settings.has_key?(:table)
          raise InvalidSettingError, %{[data_miner] :table is no longer an allowed setting.}
        end
        if (errata_settings = table_and_errata_settings[:errata]) and not errata_settings.is_a?(::Hash)
          raise InvalidSettingError, %{[data_miner] :errata must be a hash of initialization settings to Errata}
        end
        @script = script
        @attributes = ::ActiveSupport::OrderedHash.new
        @description = description
        if table_and_errata_settings.has_key? :errata
          errata_settings = table_and_errata_settings[:errata].symbolize_keys
          errata_settings[:responder] ||= model
          table_and_errata_settings[:errata] = errata_settings
        end
        @table_settings = table_and_errata_settings.dup
        @table_settings[:streaming] = true
        @table_mutex = ::Mutex.new
        instance_eval(&blk)
      end

      # Store data into a model column.
      #
      # @see DataMiner::Attribute The actual Attribute class.
      #
      # @param [Symbol] attr_name The name of the local model column.
      # @param [optional, Hash] attr_options Options that will be passed to +DataMiner::Attribute.new+
      # @option attr_options [*] anything Any option for +DataMiner::Attribute+.
      #
      # @return [nil]
      def store(attr_name, attr_options = {})
        attr_name = attr_name.to_sym
        if attributes.has_key? attr_name
          fail DuplicateColumnError, model, attr_name
        end
        attributes[attr_name] = DataMiner::Attribute.create(attr_name, attr_options)
      end

      # Store data into a model column AND use it as the key.
      #
      # @see DataMiner::Attribute The actual Attribute class.
      #
      # Enables idempotency. In other words, you can run the data miner script multiple times, get updated data, and not get duplicate rows.
      #
      # @param [Symbol] attr_name The name of the local model column.
      # @param [optional, Hash] attr_options Options that will be passed to +DataMiner::Attribute.new+
      # @option attr_options [*] anything Any option for +DataMiner::Attribute+.
      #
      # @return [nil]
      def key(attr_name, attr_options = {})
        attr_name = attr_name.to_sym
        if attributes.has_key? attr_name
          fail DuplicateColumnError, model, attr_name
        end
        @key = attr_name
        store attr_name, attr_options
      end

      # @private
      def start
        table.each do |row|
          record = model.send "find_or_initialize_by_#{@key}", attributes[@key].read(row)
          attributes.each { |_, attr| attr.set_from_row record, row }
          record.save!
        end
        refresh
        nil
      end

      private

      def table
        @table || @table_mutex.synchronize do
          @table ||= ::RemoteTable.new(@table_settings)
        end
      end

      def refresh
        @table = nil
        attributes.each { |_, attr| attr.refresh }
        nil
      end
    end
  end
end
