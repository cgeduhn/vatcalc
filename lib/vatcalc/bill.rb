
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
      when Hash
        quantity = raw_obj.fetch(:quantity,quantity || 1).to_i
      when Array
        raw_obj.each { |obj, quantity| insert(obj, quantity, gnv_klass)}
        return self
      # TODO ACTS AS SERVICE 
      # TODO ACTS AS BASE
      when nil
        raise ArgumentError.new ("Can't insert nil into #{self}")
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
    # {"19%"=>"67.65%", "7%"=>"31.35%", "0%"=>"1%"}
    # {"19%"=>"85.21%", "7%"=>"0.47%", "0%"=>"14.32%"}
    # {"19%"=>"64.08%", "7%"=>"22.28%", "0%"=>"13.64%"}
    # {"19%"=>"6.69%", "7%"=>"46.44%", "0%"=>"46.87%"}
    # {"19%"=>"16.68%", "7%"=>"6.96%", "0%"=>"76.36%"}
    # {"19%"=>"18.81%", "7%"=>"33.09%", "0%"=>"48.1%"}
    # {"19%"=>"0.39%", "7%"=>"24.39%", "0%"=>"75.22%"}
    # {"19%"=>"46.79%", "7%"=>"0.53%", "0%"=>"52.68%"}
    # {"19%"=>"58.88%", "7%"=>"10.39%", "0%"=>"30.73%"}
    # {"19%"=>"9.14%", "7%"=>"89.68%", "0%"=>"1.18%"}
    # {"19%"=>"41.13%", "7%"=>"5.91%", "0%"=>"52.96%"}
    # {"19%"=>"17.71%", "7%"=>"40.06%", "0%"=>"42.23%"}
    # {"19%"=>"7.72%", "7%"=>"27.34%", "0%"=>"64.94%"}
    # {"19%"=>"60.6%", "7%"=>"3.9%", "0%"=>"35.5%"}
    # {"19%"=>"23.31%", "7%"=>"25.05%", "0%"=>"51.64%"}
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