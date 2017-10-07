require 'active_support/core_ext/hash'
module Vatcalc    
  class BaseObject

    def self.convert(obj)
      case obj
      when self
        obj
      when Fixnum,String,Money,Float
        new(value: obj)
      when Hash
        new(obj)
      when Array
        new(value: obj[0], percentage: obj[1],currency: obj[2])
      else
        raise ArgumentError.new "#{obj} can't be converted into an #{self}"
      end
    end

    attr_reader :gross,:vat_percentage,:currency


    def initialize(options={})
      opt = options.to_h.with_indifferent_access
      @currency = (opt[:currency] || opt[:curr] || Vatcalc.currency)
      self.gross = (opt[:amount] || opt[:gross] || opt[:value] || 0)
      self.vat_percentage =(opt[:vat_percentage] || opt[:percentage] || Vatcalc.vat_percentage)
    end

    def vat_percentage=(vp)
      @vat_percentage = Util.convert_to_percentage_value(vp)
    end
    
    def gross=(g)
      @gross = Util.convert_to_money(g,@currency)
    end

    def net
      @gross / vat_percentage
    end

    def vat
      @gross - net
    end


    alias :percentage :vat_percentage
    alias :percentage= :vat_percentage=
    alias :curr :currency

    class Collection
      include Enumerable

      attr_reader :currency
      def initialize()
        @collection = []
        @vat_percentages = Set.new 
      end

      def vat_percentages
        @vat_percentages.to_a
      end

      alias :percentages :vat_percentages

      #META STUFF
      #Adding 
      #gross, vat, :net as methods here
      Util::GNV.each do |m|
        define_method(m) do 
          @collection.sum(&:"#{m}")
        end
      end

      def <<(arg)
        converted = BaseObject.convert(arg)
        @vat_percentages << converted.percentage
        @currency = converted.currency
        @collection << converted
        self
      end

      delegate :each,:length, :to => :@collection

    end

  end
end