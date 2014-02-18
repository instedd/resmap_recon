  module Configurable
    extend ActiveSupport::Concern

    included do
      serialize :config, Hash
    end

    module ClassMethods
      def config_property(name)
        define_method(name) {
          config["#{name}"]
        }
        define_method("#{name}=".to_sym) { |value|
          config["#{name}"] = value
        }
      end
    end
  end
