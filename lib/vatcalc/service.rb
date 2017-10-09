module Vatcalc
  class Service

    def initialize(amount,options={})
      opt = options.to_h
      amount =  Util.convert_to_money(amount || 0)

      # is the amount a net value or a gross value
      if opt[:net] == true
        super(amount * vat_percentage, amount, (opt[:currency] || opt[:curr]))
      else
        super(amount, amount / vat_percentage, (opt[:currency] || opt[:curr]))
      end
    end


    def base
      @base || Base.new
    end

    def base=(b)
      @base = b if b.is_a?(Base)
    end


  end
end