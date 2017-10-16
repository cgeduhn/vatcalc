module Vatcalc


  def self.acts_as_bill_element?
    @acts_as_bill_element ||= ->(obj) { obj.class.respond_to?(:acts_as_bill_element) && obj.respond_to?(:as_vatcalc_bill_element) }
  end


  module ActsAsBillElement

    def self.included(mod)
      mod.extend(ClassMethods)
    end

    module ClassMethods
      def acts_as_bill_element(amount:, service: false, currency: nil, vat_percentage: nil, prefix: :bill)

        args_to_convert = {amount: amount, currency: currency}

        if service
           klass  = Vatcalc::ServiceElement
           delegate :vat_splitted, prefix: options[:prefix], to: m_name
        else
          klass  =  Vatcalc::BaseElement
          args_to_convert[:vat_percentage] = vat_percentage
          delegate :vat_percentage, prefix: prefix, to: m_name
        end
        delegate :gross,:net,:vat, prefix: prefix, to: m_name 
        v_name = :"@#{m_name}"

        define_method(:as_vatcalc_bill_element) do
          unless instance_variable_get(v_name)
            args = args_to_convert.inject({}) do |h,(k,v)|
              case v
              when Proc
                h[k] = v.call(self)
              when Symbol,String
                h[k] = send(v)
              end
              h
            end
            instance_variable_set v_name, klass.new( args.delete(:amount), **args)
          end
          instance_variable_get(v_name)
        end
      end


    end


  end
end