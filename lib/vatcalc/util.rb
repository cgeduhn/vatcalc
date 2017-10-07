
require "money"


module Vatcalc 
  class Util
    GN  =  [:gross,:net].freeze
    GNV =  [:gross,:net,:vat].freeze

    class << self

      def convert_to_money(obj,curr=nil)
        curr ||= Vatcalc.currency
        case obj
        when Fixnum
          Money.new(obj,curr)
        when Float
          Money.new(obj*100,curr)
        when Money
          obj
        else
          raise InvalidAmountError.new "#{obj.class.name} => #{obj}"
        end
      end

      def convert_to_percentage_value(obj)
        case obj
        when Float,Fixnum
          case obj
          when 0..0.99
            return (obj + 1.00).round(2)
          when 1.01..1.99
            return obj.to_f
          when 1
            return obj.is_a?(Fixnum) ? 1.01 : 1.00
          when 2..100.00
            return (obj.to_f / 100 ).round(2) + 1.00
          end
        when String 
          #call itself
          convert_to_vat_percentage(obj.to_f)
        end
        raise InvalidPercentageError.new(obj)
      end
    end

    class PercentageHash < Hash
      def [](arg)
        super Util.convert_to_percentage_value(arg)
      end

      def []=(arg1,arg2)
        super Util.convert_to_percentage_value(arg1), arg2
      end

      def has_key?(arg)
        super Util.convert_to_percentage_value(arg)
      end
    end
  end

  class InvalidPercentageError < ArgumentError 
    def initialize(obj)
      super ("Invalid object #{obj} #{obj.class.name}")
    end
  end

  class InvalidAmountError < ArgumentError
  end
end