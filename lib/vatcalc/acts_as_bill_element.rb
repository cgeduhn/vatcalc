module Vatcalc

  def self.acts_as_base_element?
    ->(obj) { obj.respond_to?(:as_vatcalc_base_element) }
  end

  def self.acts_as_service_element?
    ->(obj) { obj.respond_to?(:as_vatcalc_service_element) }
  end


  module ActsAsBillElement

    def self.included(mod)
      mod.extend(ClassMethods)
    end


    module ClassMethods
      def acts_as_bill_element(amount:, service: false, currency: nil, vat_percentage: nil, prefix: nil)

        if service
           m_name = :as_vatcalc_service_element
           klass  = ServiceElement

           delegate :vat_splitted, prefix: options[:prefix], to: m_name
        else
          m_name =  :as_vatcalc_base_element
          klass  =  BaseElement

          delegate :vat_percentage, prefix: prefix, to: m_name
        end
        delegate :gross,:net,:vat, prefix: prefix, to: m_name 

        define_method(m_name) do
          v_name = :"@#{m_name}"
          unless instance_variable_get(v_name)
            args = [amount,vat_percentage,currency].collect do |it|
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

        

      end
    end


  end
end