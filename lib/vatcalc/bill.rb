
module Vatcalc    
  class Bill 

    include Enumerable

    attr_reader :currency
    attr_reader :services
    attr_reader :base

    alias_method :service_elements, :services
    alias_method :base_elements, :base

    delegate :rates,:rates!,:human_rates,:vat_percentages, to: :@base
    delegate :each, to: :all

    def initialize(elements: [],currency: nil)
      @base = Base.new
      @services = Services.new
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
        @currency = gnv.currency
        case gnv
        when BaseElement
          @base.insert(gnv,quantity)
          # if an base element is inserted after services already in here.
          @services.rates_changed!(@base.rates) if @services.length > 0
        when ServiceElement
          @services.insert(gnv,quantity)
          # the service gets now the rates of the base
          gnv.change_rates(@base.rates)
        end

        @base.currency = @currency
        @services.currency = @currency
      end
      self
    end

    [:gross,:vat,:net].each do |m|
      define_method(m) { base.send(m) + services.send(m) }
    end

    def vat_splitted
      all.vat_splitted
    end

    def all
      (base + services) 
    end


    RoundPrecision = 4
    #will only be used in rspec for test
    Tolerance = BigDecimal("1E-#{RoundPrecision}")
    #@see +rates+

    alias_method :percentages, :vat_percentages
    alias_method :vat_rates, :rates
    alias_method :elements, :all

    # A GNVCollection consists basically of a an 2D Array of GNV 
    # GNV Objects +@see Vatcalc::GNV+
    # It's a helper class to calculate amounts and iterate through 
    # specific GNV objects.
    class GNVCollection
      include Enumerable

      attr_reader :collection
      attr_accessor :currency

      delegate :length, :first, :last, to: :@collection

      # which class can be inserted in the collection
      def self.for
        GNV
      end

      def initialize(col=[],currency = nil)
        @collection = col
        @currency = currency
      end
      
      def insert(gnv,quantity)
        raise(TypeError.new) unless gnv.is_a?(self.class.for)
        @currency = gnv.currency
        @vat_splitted = nil
        @collection << [gnv,quantity]
        self
      end

      def <<(arg)
        insert(arg,1) 
      end

      def vat_splitted
        @vat_splitted ||= @collection.inject(GNV.new(0,0,@currency)){|sum,(gnv,q)| sum += (gnv * q) }.vat_splitted
      end

      [:gross,:vat,:net].each do |it|
        define_method(it) { @collection.inject(new_money) {|sum,(gnv,q)| sum += (gnv.send(it) * q) } }
      end

      def +(other)
        raise(TypeError.new) unless other.is_a?(GNVCollection)
        GNVCollection.new(@collection + other.collection,@currency)
      end

      def each
        result = []
        @collection.each do |gnv,quantity|
          arr = [gnv.source, quantity, gross*quantity, net*quantity, vat*quantity]
          result << arr
          yield *arr
        end
        result 
      end

      def each_gnv
        @collection.each {|gnv,quantity| yield gnv, quantity }
      end

      private

      def money_hash
        Hash.new(new_money)
      end

      def new_money
        Money.new(0,@currency)
      end


    end


    class Base < GNVCollection

      attr_reader :vat_percentages

      def initialize(*args)
        super 
        @vat_percentages = Set.new 
      end

      def self.for
        BaseElement
      end

      def insert(gnv,quantity)
        super
        @rates = nil
        @vat_percentages << gnv.vat_p
        self
      end

      # Output of rates in form of
      # key is VAT Percentage and Value is the rate 
      # "{1.0=>0.0092, 1.19=>0.8804, 1.07=>0.1104}"
      def rates
        @rates ||= rates!
      end

      def rates!
        @rates = Hash.new(0.00)
        if net.to_f != 0 
          left_over = 1.00
          grouped_amounts = @collection.inject(money_hash){ |h,(gnv,q)| h[gnv.vat_p] += gnv.net * q; h}.sort

          grouped_amounts.each_with_index do |(vp,amount),i|
            if i == (grouped_amounts.length - 1)
              #last element
              @rates[vp] = left_over.round(4)
            else
              @rates[vp] = (amount / net).round(4)
              left_over -= @rates[vp]
            end
          end
        else
          max_p = @vat_percentages.max
          @rates[max_p] = 1.00 if max_p
        end
        @rates = @rates.sort.reverse.to_h #sorted by vat percentage
      end

      # Output of rates in form of
      # key is VAT Percentage and Value is the rate in decimal form
      # {"19%"=>"69.81%", "7%"=>"21.74%", "0%"=>"8.45%"}
      def human_rates
        #example ((1.19 - 1.00)*100).round(2) => 19.0
        rates.inject({}){|h,(pr,v)| h[pr.to_s] = Util.human_percentage_value(v,4); h}
      end

    end

    class Services < GNVCollection
      def self.for
        ServiceElement
      end

      def rates_changed!(rates)
        @vat_splitted = nil
        each_gnv {|gnv,_| gnv.change_rates(rates)}
      end
    end


  end
end