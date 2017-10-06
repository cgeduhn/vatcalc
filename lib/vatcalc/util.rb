
require "money"


module Vatcalc 
  class Util
    def self.convert_to_money(obj,curr=nil)
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

    def self.convert_to_percentage_value(obj)
      case obj
      when Fixnum
        (0..100).include?(obj) ? (obj.to_f / 100 ) + 1.00 : (raise InvalidPercentageError.new("Invalid Range of #{obj} must between 0..100"))
      when Float
        case obj
        when 0..1.00
          return obj + 1.00
        when 1.00..2.00
          return obj
        else
          raise InvalidPercentageError.new("Invalid Range of #{obj} must between 0..1.00 or 1.00..2.00")
        end
      when String 
        #call itself
        convert_to_vat_percentage(obj.to_f)
      else
        raise InvalidPercentageError.new("Invalid object #{obj} #{obj.class.name}")
      end
    end
  end

  class InvalidPercentageError < ArgumentError 
  end

  class InvalidAmountError < ArgumentError
  end
end