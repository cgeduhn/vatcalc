
module Vatcalc    
  class Bill 

    attr_reader :currency
    attr_reader :service_elements
    attr_reader :base_elements

    delegate :gross,:net,:vat, to: :total

    def initialize(base: [], services: [], currency: nil)
      @base_elements = []
      @service_elements = []
      @currency = currency

      insert_base_element(base)
      insert_service_element(services)

    end

    def insert_base_element(raw_obj, quantity = 1)
      insert(raw_obj, quantity, BaseElement)
    end

    def insert_service_element(raw_obj, quantity = 1)
      insert(raw_obj, quantity, ServiceElement)
    end


    def insert(raw_obj, quantity = 1, gnv_klass = nil) 
      case raw_obj
      when Hash then quantity = (raw_obj.delete(:quantity) || 1).to_i
      when Array 
        return raw_obj.each { |obj, quantity| insert(obj, quantity, gnv_klass)}.last
      when Vatcalc.acts_as_bill_element? then gnv_klass = raw_obj.as_vatcalc_bill_element.class

      when BaseElement then gnv_klass = BaseElement
      when ServiceElement then gnv_klass = ServiceElement
      when Numeric #nothin todo
      else raise ArgumentError.new ("Can't insert a #{raw_obj.class} into #{self}")
      end

      if (quantity ||= 1) > 0 && !gnv_klass.nil?

        gnv = obj_to_gnv(gnv_klass,raw_obj)
        gnv.source = raw_obj

        case gnv
        when BaseElement
          @base_elements    << [gnv,quantity]
          rates_changed!
        when ServiceElement
          @service_elements << [gnv,quantity]
        end
        @currency ||= gnv.currency

        reset_instance_variables!
      end

      self
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
        @base_elements.each {|gnv,q| h[gnv.vat_p] += (gnv*q).vat}
        @service_elements.each {|gnv,q| gnv.vat_splitted.each {|vp,vat| h[vp] += q*vat} }
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

    def obj_to_gnv(klass,obj)
      klass_options = {currency: @currency}
      klass_options[:rates] = rates if klass == ServiceElement

      case obj
      when BaseElement
        obj
      when ServiceElement
        obj.change_rates(klass_options[:rates])
        obj
      when Numeric,Money
        klass.new(obj,klass_options)
      when Hash
        klass.new(obj.delete(:amount), obj.merge(klass_options))
      else
        raise TypeError.new "#{obj} can't be converted into a #{klass}"
      end
    end

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