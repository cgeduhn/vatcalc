
require "money"


module Vatcalc 
  class Util
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

    end
  end


  class InvalidAmountError < ArgumentError
  end
end