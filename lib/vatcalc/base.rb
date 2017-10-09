
module Vatcalc    
  class Base 

    attr_reader :collection

    def initialize()
      @collection = []
      @vat_percentages = Set.new 
    end

    def gnv
      @gnv || GNV.new(0,0)
    end
    delegate :gross,:net,:vat,:curr,:currency, to: :gnv

    def vat_percentages
      @vat_percentages.to_a
    end

    def <<(obj)
      insert(obj,1)
    end

    def insert(obj,quantity=1)
      converted = BaseElement.convert(obj)
      @vat_percentages << converted.percentage.to_f
      quantity.times do 
        c_dup = converted.dup
        @collection << c_dup
        @gnv ? @gnv += c_dup : @gnv = c_dup.to_gnv
      end
      self
    end

    alias :add :<<
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
      h = Hash.new 
      k = @vat_percentages.max
      if net != 0
        @collection.each do |elem|
          ek = elem.vat_percentage.to_f
          h[ek] = (h[ek] ? h[ek] + elem.net : elem.net)
        end
        h.each {|k,v| h[k] = (v/net).round(4)}
        #if there is a small difference correct it
        if diff = 1.00 - h.values.sum.round(4)
          h[k] = (h[k] + diff).round(4)
        end
        return h
      else
        #if the net is 0 then the highes percentage should have the full rate
        h[k] = 1.00 if k
        h
      end
    end

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
      rates.inject({}){|h,(pr,v)| h[((pr-1.00)*100).round(2)] = (v*100).round(2); h}
    end



  end
end