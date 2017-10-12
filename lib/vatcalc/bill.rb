
module Vatcalc    
  class Bill 

    

    attr_reader :base_elements
    attr_reader :service_elements
    attr_reader :elements
    attr_reader :total
    attr_reader :currency

    delegate :gross,:net,:vat, to: :total

    def initialize(options={})
      @vat_percentages = Set.new
      @base_elements    = insert_by_option_argument( options.to_h.fetch(:base),        :obj_to_base_element)
      @service_elements = insert_by_option_argument( options.to_h.fetch(:services,[]), :obj_to_service_element)
    end

    def elements 
      @base_elements + @service_elements
    end

    def vat_percentages
      @vat_percentages.to_a
    end

    def vat_splitted
      @vat_splitted ||= money_hash.tap do |result_hash|
        @base_elements.each {|elem,q| result_hash[elem.vat_p] += (elem*q).vat}
        @service_elements.each {|elem,q| elem.vat_splitted.each {|vp,vat| result_hash[vp] += vat} }
      end
    end

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
      @rates ||= rates!
    end


    RoundPrecision = 4
    #will only be used in rspec for test
    Tolerance = BigDecimal("1E-#{RoundPrecision}")
    #@see +rates+
    def rates!
      @rates = Hash.new(0.00)
      if net != 0 
        left_over = 1.00
        grouped_amounts = @base_elements.inject(money_hash){ |h,(elem,q)| h[elem.vat_p] += elem.net * q; h}.sort

        grouped_amounts.each_with_index do |(vp,amount),i|
          if i == (grouped_amounts.length - 1)
            #last element
            @rates[vp] = left_over.round(RoundPrecision)
          else
            @rates[vp] = (amount / net).round(RoundPrecision)
            left_over -= @rates[vp]
          end
        end
      else
        max_p = vat_percentages.max
        @rates = @grouped_amounts.each { |(vp,gnv)| @rates[vp] = 0.00 }
        @rates[max_p] = 1.00 if max_p
      end
      @rates
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
      rates.inject({}){|h,(pr,v)| h[((pr.to_f-1.00)*100).round(RoundPrecision-2)] = (v*100).round(RoundPrecision-2); h}
    end


    alias_method :percentages, :vat_percentages
    alias_method :vat_rates, :rates


    private 

    def insert_by_option_argument(arg,convert_method)
      case arg
      when Array
        arg.collect{|i| insert(i,convert_method) }
      else
        [insert(arg,convert_method)]
      end
    end


    def insert(obj, convert_method) 
      case obj
      when Hash
        quantity = obj[:quantity]
      when Array
        quantity = obj[1]
        obj = obj[0]
      end
      
      obj = send(convert_method,obj) 
      quantity ||= 1

      if quantity.to_i > 0
        gnv = quantity.to_i == 1 ? obj.to_gnv : obj.to_gnv * quantity

        @total ? @total += gnv : @total = gnv

        case obj
        when BaseElement
          @vat_percentages << obj.vat_percentage
        when ServiceElement
        end
        @currency = obj.currency

        #add or set gnv to the vat_percentage key
      else 
        raise ArgumentError.new "quantity must be != 0"
      end

      [obj,quantity]
    end

    def obj_to_base_element(obj)
      case obj
      when BaseElement
        obj
      when Numeric,Money
        BaseElement.new(obj)
      when Hash
        BaseElement.new(obj[:amount] || obj[:gross] || obj[:value], obj)
      else
        raise TypeError.new "#{obj} can't be converted into a BaseElement"
      end
    end

    def obj_to_service_element(obj)
      case obj
      when ServiceElement
        obj.rates = rates
        obj
      when Numeric,Money
        ServiceElement.new(obj,rates)
      when Hash
        ServiceElement.new(obj[:amount] || obj[:gross] || obj[:value],rates)
      else
        raise TypeError.new "#{obj} can't be converted into a ServiceElement"
      end
    end

    def money_hash
      Hash.new(Money.new(0,@currency))
    end



  end
end