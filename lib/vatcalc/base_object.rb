require 'active_support/core_ext/hash'
module Vatcalc    
  class BaseObject
    attr_reader :gross,:net,:vat,:percentage
    def initialize(options={})
      opt = options.to_h.with_indifferent_access

      amount = (opt[:amount] || opt[:gross] || opt[:value] || 0)
      vp = (opt[:vat_percentage] || opt[:percentage] || Vatcalc.vat_percentage)
      curr = (opt[:currency] || opt[:curr] || Vatcalc.currency)

      @gross = Vatcalc::Util.convert_to_money(amount,curr)
      percentage = Vatcalc::Util.convert_to_percentage_value(vp)


      @net = @gross / percentage
      @vat = @gross - @net
      @percentage = percentage
    end
  end
end