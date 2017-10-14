# A Base Element Object inherits from GNV
#@see Vatcalc::GNV
#
# A BaseElement always needs an VAT percentage and an amount
# if no VAT Percentage is given it takes the default VAT Percentage
module Vatcalc    
  class BaseElement < GNV

    include Comparable


    attr_reader :vat_percentage
    alias_method :percentage, :vat_percentage
    alias_method :vat_p, :vat_percentage
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

      @currency = (opt[:currency] || opt[:curr])

      amount =  Util.convert_to_money(amount || 0, @currency)

      @vat_percentage = (vp = (opt[:vat_percentage] || opt[:percentage])) ? VATPercentage.new(vp) : Vatcalc.vat_percentage

      # is the amount a net value or a gross value
      if opt[:net] == true
        super(amount * vat_percentage, amount, @currency)
      else
        super(amount, amount / vat_percentage, @currency)
      end
    end

    def hash
      #vector comes from GNV
      [@vector,@vat_percentage].hash
    end

    def ==(oth)
      oth.is_a?(BaseElement) && (oth.vector == @vector) && (vat_p == oth.vat_p)
    end


    def inspect
      "#<#{self.class.name} vat_percentage:#{vat_p} gross:#{gross} net: #{net} vat:#{vat} currency:#{@currency}>"
    end

  end
end