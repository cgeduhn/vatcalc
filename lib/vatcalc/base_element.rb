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
    #
    # Assumes that the amount is a gross value but you can pass a net value as well if you pass the 
    # option net: true 
    #
    #@example 
    #
    # => b = BaseElement.new 10.00, vat_percentage: 19, currency: "EUR"
    #    b.net.to_f = 8.40
    # => b = BaseElement.new 10.00, vat_percentage: 7,  currency: "USD"
    #    b.net.to_f = 9.35
    # => b = BaseElement.new 10.00, vat_percentage: 7,  currency: "USD", net: true
    # => b.gross = 10.70
    def initialize(amount,currency: nil, vat_percentage: nil, net: false)
      @currency = currency || Vatcalc.currency
      amount = Util.to_money(amount,@currency)
      vp = Util.to_vat_percentage(vat_percentage)
      @vector = net ? Vector[amount * vp, amount] : Vector[amount, amount / vp] 
      @vat_percentage = vp
      @vat_splitted = {@vat_percentage => vat}
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