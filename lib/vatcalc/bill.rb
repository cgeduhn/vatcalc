
module Vatcalc    
  class Bill 

    

    attr_reader :base_elements
    attr_reader :service_elements
    attr_reader :currency

    delegate :gross,:net,:vat, to: :total

    def initialize(opt={})
      @base_elements = []
      @service_elements = []
      @currency = (opt[:currency])

      insert_base_element(opt.fetch(:base,[]))
      insert_service_element(opt.fetch(:services,[]))

    end

    def insert_base_element(raw_obj, quantity = 1)
      insert(raw_obj, quantity, BaseElement)
    end

    def insert_service_element(raw_obj, quantity = 1)
      insert(raw_obj, quantity, ServiceElement)
    end


    def insert(raw_obj, quantity = 1, gnv_klass = BaseElement) 
      case raw_obj
      when Vatcalc.acts_as_service_element? 
      when Vatcalc.acts_as_base_element? 
      when Hash then quantity = raw_obj.fetch(:quantity,quantity || 1).to_i
      when Array
        raw_obj.each { |obj, quantity| insert(obj, quantity, gnv_klass)}
        return self
      when nil then raise ArgumentError.new ("Can't insert a #{raw_obj.class} into #{self}")
      end

      quantity ||= 1

      if quantity > 0

        gnv = obj_to_gnv(gnv_klass,raw_obj)

        case gnv
        when BaseElement
          @base_elements    << [raw_obj,quantity,gnv]
          rates_changed!
        when ServiceElement
          @service_elements << [raw_obj,quantity,gnv]
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
      @vat_percentages ||= @base_elements.collect{|obj,q,gnv| gnv.vat_p}.to_set
    end

    Totals = {total: :elements, base_total: :base_elements, services_total: :service_elements}
    Totals.each do |m_name,elem_name|
      define_method(m_name) do
        instance_variable_get("@#{m_name}") || instance_variable_set("@#{m_name}", send(elem_name).inject(GNV.new(0,0,@currency)) {|sum, (obj,q,gnv)| sum += (gnv * q)})
      end
    end

    def vat_splitted
      @vat_splitted ||= money_hash.tap do |h|
        @base_elements.each {|elem,q,gnv| h[gnv.vat_p] += (gnv*q).vat}
        @service_elements.each {|elem,q,gnv| gnv.vat_splitted.each {|vp,vat| h[vp] += q*vat} }
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
      base_net = @base_elements.inject(new_money) { |sum,(elem,q,gnv)| sum += gnv.net * q}
      if base_net.to_f != 0 
        left_over = 1.00
        grouped_amounts = @base_elements.inject(money_hash){ |h,(elem,q,gnv)| h[gnv.vat_p] += gnv.net * q; h}.sort

        grouped_amounts.each_with_index do |(vp,amount),i|
          if i == (grouped_amounts.length - 1)
            #last element
            @rates[vp] = left_over.round(RoundPrecision)
          else
            @rates[vp] = (amount / base_net).round(RoundPrecision)
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

    def obj_to_gnv(klass,obj,klass_options={})
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
        klass.new(obj[:amount] || obj[:gross] || obj[:value], obj.merge(klass_options))
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
      Totals.keys.each {|m_name| instance_variable_set("@#{m_name}",nil)}
      @vat_splitted = nil
      @vat_percentages = nil
    end


    def rates_changed!
      @rates = nil
      rates! if service_elements.any?
      @service_elements.each do |elem,q,gnv|
        gnv.change_rates(rates)
      end
    end





  end
end