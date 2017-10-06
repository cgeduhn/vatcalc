module Vatcalc    
  class BaseObject
    attr_reader :gross,:net,:vat,:percentage
    def initialize(amount,vat_percentage,curr=nil)
      @gross = Vatcalc::Util.convert_to_money(amount)
      percentage = Vatcalc::Util.convert_to_percentage_value(obj)
      @net = @gross / percentage
      @vat = @gross - @net
      @percentage = percentage
    end
  end
end