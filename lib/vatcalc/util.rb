
require "money"


module Vatcalc 
  class Util
    class << self

      #Converts an Object into a Money object
      #@return [Money]
      #@example 
      # => Vatcalc::Util.convert_to_money(10.00) 
      def convert_to_money(obj,curr=nil)
        curr ||= Vatcalc.currency
        case obj
        when Money
          obj
        when Fixnum
          Money.new(obj,curr)
        when Numeric
          Money.new(obj*100,curr)
        else
          raise InvalidAmountError.new "Can't convert #{obj.class} to an Money instance"
        end
      end

      # ALIAS for convert_to_money method
      alias_method :conv_to_money, :convert_to_money
      alias_method :conv_to_m, :convert_to_money
      alias_method :to_money, :convert_to_money

      #Converts an Object into an VATPercentage Object
      #@return [VATPercentage]
      #
      #@example
      # => Vatcalc::Util.to_vat_percentage
      def convert_to_vat_percentage(vat_percentage)
        case vat_percentage
        when VATPercentage
          vat_percentage 
        when nil
          Vatcalc.vat_percentage
        else
          VATPercentage.new(vat_percentage)
        end
      end

      # ALIAS for convert_to_vat_percentage method
      alias_method :to_vat_percentage, :convert_to_vat_percentage
      alias_method :to_vat_p, :convert_to_vat_percentage

      #Returns a human friendly percentage value
      #@param value = [Float,Integer,String]
      # => human_percentage_value(0.19) => 19% 
      def human_percentage_value(value,precision=2)
        full, fraction = ((value.to_f)*100).to_f.round(precision).divmod(1)
        full.to_s + (fraction > 0.00 ? ("," + fraction.round(precision).to_s[2..-1]) : "") + "%"
      end

    end

  end


  class InvalidAmountError < TypeError
  end
end