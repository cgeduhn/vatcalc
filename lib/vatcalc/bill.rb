
module Vatcalc    
  class Bill 

    include Enumerable

    attr_reader :currency
    attr_reader :service_elements
    attr_reader :base_elements

    delegate :gross,:net,:vat, to: :total

    def initialize(elements: [],currency: nil)
      @base_elements = []
      @service_elements = []
      @currency = currency
      insert(elements)
    end

    def insert(obj, quantity = 1) 
      case obj
      when Array 
        return obj.each { |obj, quantity| insert(obj, quantity)}.last
      when Vatcalc.acts_as_bill_element? 
        gnv = obj.as_vatcalc_bill_element
      else raise ArgumentError.new ("Can't insert a #{obj.class} into #{self}. #{obj.class} must include Vatcalc::ActsAsBillElement")
      end

      if (quantity ||= 1) > 0 
        gnv.source = obj
        case gnv
        when BaseElement
          @base_elements    << [gnv,quantity]
          rates_changed!
        when ServiceElement
          @service_elements << [gnv,quantity]
          gnv.change_rates(rates)
        end
        @currency ||= gnv.currency
        reset_instance_variables!
      end
      self
    end

    def each
      elements.each do |gnv, quantity|
        r = gnv*quantity
        yield gnv.source, quantity, r.gross, r.net, r.vat, r.vat_splitted
      end
    end


    def elements
      @base_elements + @service_elements
    end

    def vat_percentages
      @vat_percentages ||= @base_elements.collect{|gnv,q| gnv.vat_p}.to_set
    end

    def base_total
      @base_total ||= @base_elements.inject(GNV.new(0,0,@currency)) {|sum, (gnv,q)| sum += (gnv * q)}
    end

    def services_total
      @services_total ||= @service_elements.inject(GNV.new(0,0,@currency)) {|sum, (gnv,q)| sum += (gnv * q)}
    end

    def total
      @total ||= base_total + services_total
    end

    def vat_splitted
      @vat_splitted ||= money_hash.tap do |h|
        elements.each {|gnv,q| gnv.vat_splitted.each {|vp,vat| h[vp] += q*vat} }
      end
    end

    # Output of rates in form of
    # key is VAT Percentage and Value is the rate 
    # "{1.0=>0.0092, 1.19=>0.8804, 1.07=>0.1104}"
    def rates
      @rates ||= rates!
    end


    RoundPrecision = 4
    #will only be used in rspec for test
    Tolerance = BigDecimal("1E-#{RoundPrecision}")
    #@see +rates+
    def rates!
      @rates = Hash.new(0.00)
      if base_total.net.to_f != 0 
        left_over = 1.00
        grouped_amounts = @base_elements.inject(money_hash){ |h,(gnv,q)| h[gnv.vat_p] += gnv.net * q; h}.sort

        grouped_amounts.each_with_index do |(vp,amount),i|
          if i == (grouped_amounts.length - 1)
            #last element
            @rates[vp] = left_over.round(RoundPrecision)
          else
            @rates[vp] = (amount / base_total.net).round(RoundPrecision)
            left_over -= @rates[vp]
          end
        end
      else
        max_p = vat_percentages.max
        @rates[max_p] = 1.00 if max_p
      end
      @rates = @rates.sort.reverse.to_h #sorted by vat percentage
    end


    # Output of rates in form of
    # key is VAT Percentage and Value is the rate in decimal form
    # {"19%"=>"69.81%", "7%"=>"21.74%", "0%"=>"8.45%"}
    def human_rates
      #example ((1.19 - 1.00)*100).round(2) => 19.0
      rates.inject({}){|h,(pr,v)| h[pr.to_s] = Util.human_percentage_value(v,RoundPrecision); h}
    end


    alias_method :percentages, :vat_percentages
    alias_method :vat_rates, :rates


    private 

    def money_hash
      Hash.new(new_money)
    end

    def new_money
      Money.new(0,@currency)
    end

    def reset_instance_variables!
      @total = nil
      @base_total = nil
      @services_total = nil
      @vat_splitted = nil
      @vat_percentages = nil
    end


    def rates_changed!
      @rates = nil
      rates! if service_elements.any?
      @service_elements.each do |gnv,q|
        gnv.change_rates(rates)
      end
    end





  end
end