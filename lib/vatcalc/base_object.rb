require 'active_support/core_ext/hash'
require 'vatcalc/gnv_object'
module Vatcalc    
  class BaseObject < GNVObject

    def self.convert(obj)
      case obj
      when self
        obj
      when Fixnum,String,Money,Float
        new(obj)
      when Hash
        new(obj[:amount] || obj[:gross] || obj[:value],obj)
      when Array
        new(obj[0], percentage: obj[1],currency: obj[2])
      else
        raise ArgumentError.new "#{obj} can't be converted into an #{self}"
      end
    end

    attr_reader :vat_percentage

    def initialize(amount,options={})
      opt = options.to_h.with_indifferent_access
      amount =  Util.convert_to_money(amount || 0)
      vp = (opt[:vat_percentage] || opt[:percentage])

      
      @vat_percentage = vp ? VATPercentage.new(vp) : Vatcalc.vat_percentage

      # is the amount a net value or a gross value
      if opt[:net] == true
        super(amount * vat_percentage, amount, (opt[:currency] || opt[:curr]))
      else
        super(amount,amount / vat_percentage,(opt[:currency] || opt[:curr]))
      end
    end


    alias :percentage :vat_percentage
    delegate :+,:-, to: :to_gnv


    def inspect
      "#<#{self.class.name} vat_percentage:#{vat_percentage} gross:#{gross} net: #{net} vat:#{vat} >"
    end





  end
end