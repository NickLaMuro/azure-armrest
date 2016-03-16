# Azure namespace
module Azure
  # Armrest namespace
  module Armrest
    # Base class for managing virtual machine images
    class VirtualMachineImageService < ArmrestService
      # The location used in requests when gathering VM image information.
      attr_accessor :location

      # The publisher used in requests when gathering VM image information.
      attr_accessor :publisher

      # Create and return a new VirtualMachineImageService instance.
      #
      # This subclass accepts the additional :location, :provider, and
      # :publisher options as well.
      #
      def initialize(configuration, options = {})
        super(configuration, 'locations/publishers', 'Microsoft.Compute', options)

        @location  = options[:location]
        @publisher = options[:publisher]
      end

      # Return a list of VM image offers from the given +publisher+ and +location+.
      #
      # Example:
      #
      #   vmis.offers('eastus', 'Canonical')
      #
      def offers(location = @location, publisher = @publisher)
        raise ArgumentError, "No location specified" unless location
        raise ArgumentError, "No publisher specified" unless publisher

        url = build_url(location, 'publishers', publisher, 'artifacttypes', 'vmimage', 'offers')

        JSON.parse(rest_get(url)).map { |hash| Azure::Armrest::Offer.new(hash) }
      end

      # Return a list of VM image publishers for the given +location+.
      #
      # Example:
      #
      #   vmis.publishers('eastus')
      #
      def publishers(location = @location)
        raise ArgumentError, "No location specified" unless location

        url = build_url(location, 'publishers')

        JSON.parse(rest_get(url)).map { |hash| Azure::Armrest::Publisher.new(hash) }
      end

      # Return a list of VM image skus for the given +offer+, +location+,
      # and +publisher+.
      #
      # Example:
      #
      #   vmis.skus('UbuntuServer', 'eastus', 'Canonical')
      #
      def skus(offer, location = @location, publisher = @publisher)
        raise ArgumentError, "No location specified" unless location
        raise ArgumentError, "No publisher specified" unless publisher

        url = build_url(
          location, 'publishers', publisher, 'artifacttypes',
          'vmimage', 'offers', offer, 'skus'
        )

        JSON.parse(rest_get(url)).map { |hash| Azure::Armrest::Sku.new(hash) }
      end

      # Return a list of VM image versions for the given +sku+, +offer+,
      # +location+ and +publisher+.
      #
      # Example:
      #
      #   vmis.versions('15.10', 'UbuntuServer', 'eastus', 'Canonical').map(&:name)
      #
      #   # sample output
      #   => ["15.10.201511111", "15.10.201511161", "15.10.201512030"]
      #
      def versions(sku, offer, location = @location, publisher = @publisher)
        raise ArgumentError, "No location specified" unless location
        raise ArgumentError, "No publisher specified" unless publisher

        url = build_url(
          location, 'publishers', publisher, 'artifacttypes',
          'vmimage', 'offers', offer, 'skus', sku, 'versions'
        )

        JSON.parse(rest_get(url)).map { |hash| Azure::Armrest::ImageVersion.new(hash) }
      end

      private

      # Builds a URL based on subscription_id an resource_group and any other
      # arguments provided, and appends it with the api_version.
      #
      def build_url(location, *args)
        url = File.join(
          Azure::Armrest::COMMON_URI,
          configuration.subscription_id,
          'providers',
          provider,
          'locations',
          location
        )

        url = File.join(url, *args) unless args.empty?
        url << "?api-version=#{@api_version}"
      end
    end # VirtualMachineImageService
  end # Armrest
end # Azure
