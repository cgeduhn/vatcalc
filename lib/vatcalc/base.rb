
module Vatcalc    
  class Base 

    attr_reader :elements
    def initialize()
      @grouped_amounts = {}
      @elements = []
      @total = GNV.new(0,0)
    end

    def <<(obj)
      insert(obj,1)
    end

    def insert(obj,quantity=1)
      obj = case obj
      when BaseElement
        obj
      when Numeric,Money
        BaseElement.new(obj,currency: currency)
      when Hash
        BaseElement.new(obj[:amount] || obj[:gross] || obj[:value],obj.tap{|h| h[:currency] ||= currency})
      when Array
        BaseElement.new(obj[0], percentage: obj[1],currency: obj[2])
      else
        raise TypeError.new "#{obj} can't be converted into a BaseElement"
      end

      gnv = (obj * quantity)

      @grouped_amounts[obj.vat_percentage] ? @grouped_amounts[obj.vat_percentage] += gnv : @grouped_amounts[obj.vat_percentage] = gnv

      @elements.fill(obj, @elements.size, quantity) 

      @total += gnv

      rates!

      self
    end

    def [](arg)
      @grouped_amounts[(arg.is_a?(VATPervcentage) ? arg : VATPercentage.new(arg))]
    end

    delegate :gross,:net,:vat,:curr,:currency, to: :@total

    def vat_percentages
      @grouped_amounts.keys
    end


    alias :collection :elements

    alias :add :insert
    alias :percentages :vat_percentages

    # Output of rates in form of
    # key is VAT Percentage and Value is the rate 
    # "{1.0=>0.0092, 1.19=>0.8804, 1.07=>0.1104}"
    # "{1.0=>0.4927, 1.19=>0.0168, 1.07=>0.4905}"
    # "{1.0=>0.1284, 1.19=>0.6933, 1.07=>0.1783}"
    # "{1.0=>0.8215, 1.19=>0.1618, 1.07=>0.0167}"
    # "{1.0=>0.531,  1.19=>0.0866, 1.07=>0.3824}"
    # "{1.0=>0.1152, 1.19=>0.0113, 1.07=>0.8735}"
    # "{1.0=>0.1927, 1.19=>0.4567, 1.07=>0.3506}"
    # "{1.0=>0.797,  1.19=>0.1609, 1.07=>0.0421}"
    # "{1.0=>0.2525, 1.19=>0.0036, 1.07=>0.7439}"
    # "{1.0=>0.2475, 1.19=>0.3371, 1.07=>0.4154}"
    # "{1.0=>0.1739, 1.19=>0.5261, 1.07=>0.3}"
    def rates
      @rates || rates!
    end

    #@see +rates+
    def rates!
      max_p = vat_percentages.max
      rate_hash = Hash.new(0.00)
      if net != 0 
        @grouped_amounts.each { |(vp,gnv)| rate_hash[vp] = (gnv.net/net).round(4) }
        #it can be that there is a small difference.
        #so it should be corrected her
        if diff = 1.00 - rate_hash.values.sum.round(4)
          rate_hash[max_p] = (rate_hash[max_p] + diff).round(4)
        end
      else
        rate_hash = @grouped_amounts.each { |(vp,gnv)| rate_hash[vp] = 0.00 }
        rate_hash[max_p] = 1.00 if max_p
      end
      @rates = rate_hash
    end

    alias :vat_rates :rates

    # Output of rates in form of
    # key is VAT Percentage and Value is the rate in decimal form
    # {0.0=>75.77, 19.0=>20.91, 7.0=>3.32}
    # {0.0=>60.29, 19.0=>2.61,  7.0=>37.1}"
    # {0.0=>12.17, 19.0=>83.0,  7.0=>4.83}"
    # {0.0=>75.82, 19.0=>5.07,  7.0=>19.11}"
    # {0.0=>32.42, 19.0=>22.93, 7.0=>44.65}"
    # {0.0=>0.26,  19.0=>32.83, 7.0=>66.91}"
    # {0.0=>40.38, 19.0=>51.67, 7.0=>7.95}"
    # {0.0=>11.56, 19.0=>10.71, 7.0=>77.73}"
    def human_rates
      #example ((1.19 - 1.00)*100).round(2) => 19.0
      rates.inject({}){|h,(pr,v)| h[((pr.to_f-1.00)*100).round(2)] = (v*100).round(2); h}
    end



  end
end