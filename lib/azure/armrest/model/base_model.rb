require 'active_support/core_ext/string/inflections'
require 'pp'
require_relative 'hash_model'

module Azure
  module Armrest
    class BaseModel < Azure::Armrest::HashModel
      attr_accessor :response_headers
      attr_accessor :response_code

      attr_writer :resource_group
      attr_writer :subscription_id

      def self.excl_list
        @excl_list ||= superclass.respond_to?(:excl_list, true) ? superclass.send(:excl_list) : Set.new
      end

      private_class_method :excl_list

      # Merge the declared exclusive attributes to the existing list.
      def self.attr_hash(*attrs)
        @excl_list = excl_list | Set.new(attrs.map(&:to_s))
      end

      # Defines attr_reader methods for the given set of attributes and
      # expected hash key.  Used to define methods that can be used internally
      # that avoid needing to use methods defined from
      # `add_accessor_methods`/`__setobj__`
      #
      # Example:
      #   class Vm < Azure::ArmRest::BaseModel
      #     attr_from_hash :name => :Name
      #   end
      #
      #   json_string = {'name' => 'Deathstar'}
      #
      #   vm = Vm.new(json_string)
      #   vm.name_from_hash
      #   #=> "Deathstar"
      #
      #   # If the attr_from_hash can also support multiple attrs in a single
      #   # call, and nested params
      #
      #   class Host < Azure::ArmRest::BaseModel
      #     attr_from_hash :name => :Name,
      #                    :address => [:Properties, :ipAddress],
      #   end
      #
      #   json_string = {'name' => 'Hoth', :Properties => {:ipAddress => '123.123.123.123'}}
      #
      #   host = Host.new(json_string)
      #   host.name_from_hash
      #   #=> "Hoth"
      #   host.address_from_hash
      #   #=> "123.123.123.123"
      #
      def self.attr_from_hash(attrs = {})
        file, line, _ = caller.first.split(":")
        attrs.each do |attr_name, keys|
          keys      = Array(keys)
          first_key = keys.shift
          method_def = [
            "def #{attr_name}_from_hash",
            "  return @#{attr_name}_from_hash if defined?(@#{attr_name}_from_hash)",
            "  @#{attr_name}_from_hash = @data[:#{first_key}] || @data[\"#{first_key}\"]",
            "end"
          ]
          keys.each do |hash_key|
            method_def.insert(-2, "  @#{attr_name}_from_hash = @#{attr_name}_from_hash[:#{hash_key}] || @#{attr_name}_from_hash[\"#{hash_key}\"]")
          end
          class_eval(method_def.join("; "), file, line.to_i)
        end
      end

      private_class_method :attr_from_hash

      def self.attr_excluded?(attr)
        excl_list.include?(attr)
      end

      def self.key_to_attribute(key)
        key = key.to_s.tr(' ', '_')
        key = key.tr('.', '_')
        key.underscore
      end

      private_class_method :attr_hash
      attr_hash :tags

      def resource_group
        # @resource_group ||= id[/resourcegroups\/(.*?[^\/]+)?/i, 1] rescue nil
        @resource_group ||= begin
                              id_from_hash[/resourcegroups\/(.*?[^\/]+)?/i, 1]
                            rescue
                              nil
                            end
      end

      def subscription_id
        # @subscription_id ||= id[/subscriptions\/(.*?[^\/]+)?/i, 1] rescue nil
        @subscription_id ||= begin
                               id_from_hash[/subscriptions\/(.*?[^\/]+)?/i, 1]
                             rescue
                               nil
                             end
      end

      def initialize(json_or_hash, skip_accessors_definition = false)
        @child_excl_list = self.class.send(:excl_list).map do |e|
          e.index('#') ? e[e.index('#') + 1..-1] : ''
        end

        super
      end

      alias to_str to_s

      def to_json(_opts = nil)
        to_h.to_json
      end

      def []=(key, value)
        @data[key] = value
        self.class.send(:convert_value, key, value, self.class)
      end

      def hash_to_model(klass_name, hash)
        model_klass =
          if self.class.const_defined?(klass_name, false)
            self.class.const_get(klass_name)
          else
            child_excl_list = @child_excl_list
            self.class.const_set(klass_name, Class.new(self.class) { attr_hash(*child_excl_list) })
          end
        model_klass.new(hash)
      end

      # Do not use this method directly.
      #
      # Will only attempt to fetch the id from the @hashobj once, so even it it
      # is nil, it will cache that value, and return that on subsequent calls.
      def id_from_hash
        return @id_from_hash if defined?(@id_from_hash)
        @id_from_hash = @data[:id] || @data["id"]
      end
    end

    # Initial class definitions. Reopen these classes as needed.

    class AvailabilitySet < BaseModel; end
    class Container < BaseModel; end
    class Event < BaseModel; end
    class ImageVersion < BaseModel; end
    class Location < BaseModel; end
    class Offer < BaseModel; end
    class Publisher < BaseModel; end
    class Resource < BaseModel; end
    class ResourceGroup < BaseModel; end
    class ResourceProvider < BaseModel; end
    class Sku < BaseModel; end
    class KeyVault < BaseModel; end

    module Billing
      class Usage < BaseModel; end
    end

    class ResponseBody < BaseModel; end

    class ResponseHeaders < BaseModel
      undef_method :response_headers
    end

    class StorageAccount < BaseModel; end
    class StorageAccountKey < StorageAccount
      attr_from_hash :key_name => :keyName,
                     :value    => :value

      def key1; key_name_from_hash == 'key1' ? value_from_hash : nil; end
      def key2; key_name_from_hash == 'key2' ? value_from_hash : nil; end
      def key; key1 || key2; end
    end

    class Subscription < BaseModel; end
    class Tag < BaseModel; end
    class TemplateDeployment < BaseModel
      #attr_hash 'properties#parameters', 'properties#outputs'
    end
    class TemplateDeploymentOperation < TemplateDeployment; end
    class Tenant < BaseModel; end
    class VirtualMachine < BaseModel; end
    class VirtualMachineInstance < VirtualMachine; end
    class VirtualMachineModel < VirtualMachine; end
    class VirtualMachineExtension < BaseModel; end
    class VirtualMachineImage < BaseModel; end
    class VirtualMachineSize < BaseModel; end

    module Insights
      class Alert < BaseModel; end
      class Diagnostic < BaseModel; end
      class Event < BaseModel; end
      class Metric < BaseModel; end
      class MetricDefinition < BaseModel; end
    end

    module Network
      class LoadBalancer < BaseModel; end
      class InboundNat < LoadBalancer; end
      class IpAddress < BaseModel; end
      class NetworkInterface < BaseModel; end
      class NetworkSecurityGroup < BaseModel; end
      class NetworkSecurityRule < NetworkSecurityGroup; end
      class RouteTable < BaseModel; end
      class Route < RouteTable; end
      class VirtualNetwork < BaseModel; end
      class Subnet < VirtualNetwork; end
    end

    module Role
      class Assignment < BaseModel; end
      class Definition < BaseModel; end
    end

    module Sql
      class SqlServer < BaseModel; end
      class SqlDatabase < BaseModel; end
    end

    module Storage
      class Disk < BaseModel; end
      class Image < BaseModel; end
      class Snapshot < BaseModel; end
    end
  end
end

require_relative 'storage_account'
require_relative 'virtual_machine'
