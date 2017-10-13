
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

      def human_percentage_value(value,precision=2)
        #@example @value = 0.19 # => full = 19, fraction = 0.00 
        full, fraction = ((value.to_f)*100).to_f.round(precision).divmod(1)
        full.to_s + (fraction > 0.00 ? ("." + fraction.round(precision).to_s[2..-1]) : "") + "%"
      end

      alias_method :conv_to_money, :convert_to_money
      alias_method :conv_to_m, :convert_to_money
    end

  end


  class InvalidAmountError < TypeError
  end
end