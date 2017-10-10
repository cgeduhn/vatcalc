# A Base Element Object inherits from GNV
#@see Vatcalc::GNV
#
# A BaseElement always needs an VAT percentage and an amount
# if no VAT Percentage is given it takes the default VAT Percentage
module Vatcalc    
  class BaseElement < GNV

    attr_reader :vat_percentage

    #Initalizes a new Object of an BaseElement
    #@param amount = [Money,Numeric]
    #@param options = [Hash]
    # Assumes that the amount is a gross value but you can pass a net value as well if you pass the 
    # option net: true 
    #@example 
    # => b = BaseElement.new 10.00, vat_percentage: 19, currency: "EUR"
    #    b.net.to_f = 8.40
    # => b = BaseElement.new 10.00, vat_percentage: 7,  currency: "USD"
    #    b.net.to_f = 9.35
    # => b = BaseElement.new 10.00, vat_percentage: 7,  currency: "USD", net: true
    # => b.gross = 10.70
    def initialize(amount,options={})
      opt = options.to_h

      amount =  Util.convert_to_money(amount || 0)

      @vat_percentage = (vp = (opt[:vat_percentage] || opt[:percentage])) ? VATPercentage.new(vp) : Vatcalc.vat_percentage

      # is the amount a net value or a gross value
      if opt[:net] == true
        super(amount * vat_percentage, amount, (opt[:currency] || opt[:curr]))
      else
        super(amount, amount / vat_percentage, (opt[:currency] || opt[:curr]))
      end
    end


    alias :percentage :vat_percentage
    #TODO delegate + and - to: to_base 
    delegate :+,:-,:*, to: :to_gnv

    def to_base(quantity=1)
      Base.new.insert(self,quantity)
    end


    def inspect
      "#<#{self.class.name} vat_percentage:#{vat_percentage} gross:#{gross} net: #{net} vat:#{vat} >"
    end

  end
end