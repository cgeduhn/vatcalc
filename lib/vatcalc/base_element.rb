module Vatcalc    
  class BaseElement < GNV

    attr_reader :vat_percentage

    def initialize(amount,options={})
      opt = options.to_h
      amount =  Util.convert_to_money(amount || 0)
      vp = (opt[:vat_percentage] || opt[:percentage])


      @vat_percentage = vp ? VATPercentage.new(vp) : Vatcalc.vat_percentage

      # is the amount a net value or a gross value
      if opt[:net] == true
        super(amount * vat_percentage, amount, (opt[:currency] || opt[:curr]))
      else
        super(amount, amount / vat_percentage, (opt[:currency] || opt[:curr]))
      end
    end


    alias :percentage :vat_percentage
    delegate :+,:-, to: :to_gnv

    def to_base
      Base.new.insert(self)
    end


    def inspect
      "#<#{self.class.name} vat_percentage:#{vat_percentage} gross:#{gross} net: #{net} vat:#{vat} >"
    end

  end
end