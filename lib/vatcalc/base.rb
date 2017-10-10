
module Vatcalc    
  class Base 

    def initialize()
      @grouped_amounts = {}
      @elements = Hash.new(0)
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
      #building a abstract gnv object thats responds_to gross, net, vat
      gnv = (obj * quantity)

      #add or set gnv to the vat_percentage key
      @grouped_amounts[obj.vat_percentage] ? @grouped_amounts[obj.vat_percentage] += gnv : @grouped_amounts[obj.vat_percentage] = gnv

      #put quantity times the object in the elements array
      @elements[obj] += quantity

      @total ? @total += gnv : @total = gnv

      @rates_changed = true

      self
    end

    def [](arg)
      @grouped_amounts[(arg.is_a?(VATPercentage) ? arg : VATPercentage.new(arg))]
    end

    def each_element_with_quantity
      @elements.each { |elem, quantity| (yield elem, quantity) if block_given? }
    end

    delegate :gross,:net,:vat,:curr,:currency, to: :@total

    def vat_percentages
      @grouped_amounts.keys
    end

    alias :add :insert
    alias :percentages :vat_percentages

    alias :each_elem :each_element_with_quantity
    alias :each_element :each_element_with_quantity

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
      !rates_changed? && @rates ? @rates : rates!
    end

    #@see +rates+
    def rates!
      max_p = vat_percentages.max
      min_p = vat_percentages.min
      @rate_hash = Hash.new(0.00)
      if net != 0 
        
        @grouped_amounts.each { |(vp,gnv)| @rate_hash[vp] = (gnv.net/net).round(6) }
        #it can be that there is a small difference.
        #so it should be corrected here

        calc_diff = ->{ @rate_hash.values.sum.round(6) - 1.00 }
        diff = calc_diff.call
        l = @rate_hash.length
        tolerance = BigDecimal("1E-5")
        # the diff has to be negative so not over 1.00 and the absolut value has to be smaler than the tolerance 
        while diff.positive? || diff.abs >= tolerance
          # if diff is bigger than the tolerance it has to be allocated over all vat_percentage rates
          if diff.abs > tolerance
            eps = (diff / l) # if if negativ eps will be postive 
            @rate_hash.each { |k,v| @rate_hash[k] = (eps + v).round(6) }
          else
            #the diff is equal the tolerance or is positive. taking now the smallest 
            #vat vercentage value here and subtract the diff
            @rate_hash[min_p] = (@rate_hash[min_p] - diff).round(6)
          end
          diff = calc_diff.call
        end
      else
        @rate_hash = @grouped_amounts.each { |(vp,gnv)| @rate_hash[vp] = 0.00 }
        @rate_hash[max_p] = 1.00 if max_p
      end
      @rates_changed = false
      @rate_hash
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
      rates.inject({}){|h,(pr,v)| h[((pr.to_f-1.00)*100).round(2)] = (v*100).round(4); h}
    end


    def rates_changed?
      !!@rates_changed
    end


    private 
      def total
        @total || GNV.new(0,0)
      end

  end
end