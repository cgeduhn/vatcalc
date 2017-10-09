
require "money"


module Vatcalc 
  class Util
    #Converts an Object into a Money object
    #@return [Money]
    #@example 
    # => Vatcalc::Util.convert_to_money(10.00) 
    def self.convert_to_money(obj,curr=nil)
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
  end


  class InvalidAmountError < TypeError
  end
end