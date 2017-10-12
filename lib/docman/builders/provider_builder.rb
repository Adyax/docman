module Docman
  module Builders
    class ProviderBuilder < Builder

      register_builder :provider_builder

      def execute
        @provider.perform
      end

      def changed?
        @provider.changed?
      end

    end
  end
end
