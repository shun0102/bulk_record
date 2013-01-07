require "bulk_record/version"
require 'active_support/all'
require 'mysql2'

module BulkRecord
  class Base
    mattr_accessor :configurations, instance_writer: false
    self.configurations = {}

    class_attribute :connection, instance_writer: false

    class_attribute :table_name_prefix
    self.table_name_prefix = ""

    class_attribute :table_name
    self.table_name = ""

    class_attribute :connection

    class_attribute :primary_keys

    class_attribute :fix_columns
    self.fix_columns = []

    class_attribute :columns
    self.columns = []

    class_attribute :rows
    self.rows = []

    class_attribute :columns_in_rows
    self.columns_in_rows = []

    module ConnectionHandling
      def establish_connection(env)
        conf = self.configurations[env]
        self.connection = mysql2_connection(conf)
      end

      def mysql2_connection(config)
        config[:username] = 'root' if config[:username].nil?
        return Mysql2::Client.new(config.symbolize_keys)
      end
    end

    module ClassMethods
      def initialize(option = nil)
        set_schema(option)
        set_primary_keys
      end

      def set_primary_keys
        query = "SHOW KEYS FROM #{self.full_table_name} WHERE Key_name = 'PRIMARY'"
        result = connection.query(query)
        self.primary_keys = []
        result.each do |row|
          self.primary_keys << row['Column_name']
        end
      end

      def set_table_name(name)
        self.table_name = name
      end

      def add(row)
        self.columns_in_rows = columns_in_rows | row.keys
        self.rows << row
      end

      def full_table_name
        if @table_name_prefix.nil?
          @table_name
        else
          @table_name_prefix + @table_name
        end
      end

      def set_schema(option)
        self.table_name = self.class.name.underscore.pluralize
        unless option.blank?
          unless option[:table_name_prefix].blank?
            self.table_name_prefix = option[:table_name_prefix]
          end
          unless option[:fix_columns].blank?
            self.fix_columns = option[:fix_columns]
          end
        end
        query = "DESC #{self.full_table_name}"
        connection.query(query).each do |r|
          unless r["Extra"] && r["Extra"] == "auto_increment"
            self.columns << r["Field"].to_sym
          end
        end
      end

      def import(option = nil)
        values = []
        update_columns = columns_in_rows & columns

        self.rows.each do |row|
          value = []
          self.columns.each do |col|
            value << format(row[col])
          end
          values << "(#{value.join(",")})"
        end
        query = "INSERT INTO #{self.full_table_name} (#{columns.join(',')}) VALUES #{values.join(",")}"

        if (!option.nil? && option[:on_duplicate_key_update])
          counter_columns = update_columns.select { |x| !fix_columns.include?(x) }
          update = " ON DUPLICATE KEY UPDATE " + counter_columns.map{ |x| "#{x} = #{x} + VALUES(#{x})"}.join(',')
          query += update
          connection.query(query)
        else
          connection.query(query)
        end
      end

      def format(value)
        formalized = ""
        if value.nil?
          formalized = "NULL"
        elsif value.respond_to?(:strftime)
          formalized = "'" + rawvalue.strftime('%Y-%m-%d %H:%M:%S') + "'"
        elsif value.is_a?(Array)
          formalized = value.map{|v| "'" + Mysql2::Client.escape(v.to_s) + "'" }.join(",")
        else
          formalized = "'" + Mysql2::Client.escape(value.to_s) + "'"
        end
      end

      # TODO: bulk insert useing LOAD DATA INFILE
      def load
      end

    end

    extend ConnectionHandling
    include ClassMethods
  end

end
