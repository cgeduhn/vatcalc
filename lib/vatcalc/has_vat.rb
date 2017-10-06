module Vatcalc
  module HasVat
    def self.included(mod)
      mod.extend(ClassMethods)
    end


    module ClassMethods

      def is_a_vat_object(amount_method, options={})

        define_method :vat_object do

        end

      end

      def is_a_service_object
        
      end

    end
  end
end