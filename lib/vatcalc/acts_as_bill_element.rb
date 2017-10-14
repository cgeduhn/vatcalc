module Vatcalc

  def self.acts_as_service_element?
    ->(obj) { obj.respond_to?(as_service_element_method) }
  end

  def self.acts_as_base_element?
    ->(obj) { obj.respond_to?(as_base_element_method) }
  end

  def self.as_service_element_method
    :as_vatcalc_service_element
  end

  def self.as_base_element_method
    :as_vatcalc_base_element
  end

  module ActsAsBillElement

    def self.included(mod)
      mod.extend(ClassMethods)
    end



    module ClassMethods
      def acts_as_bill_element(amount_method, options={})

        if options.to_h.delete(:service) == true
           m_name = Vatcalc.as_service_element_method
           klass  = ServiceElement
        else
          m_name =  Vatcalc.as_base_element_method
          klass  =  BaseElement
        end

        define_method(m_name) do
          v_name = :"@#{m_name}"
          unless instance_variable_get(v_name)
            args = [amount_method,options[:currency],options[:vat_percentage]].collect do |it|
              case it
              when Proc
                it.call(self)
              when Symbol,String
                self.send(it)
              when nil
                nil
              else
                raise ArgumentError.new
              end
            end
            instance_variable_set v_name, klass.new( args[0], { currency: args[1], vat_percentage: args[2] })
          end
          instance_variable_get(v_name)
        end

        delegate :gross,:net,:vat, prefix: options[:prefix], to: m_name 

      end
    end


  end
end