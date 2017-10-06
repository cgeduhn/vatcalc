require 'active_support/core_ext/hash'
module Vatcalc    
  class BaseObject
    GNV = [:gross,:net,:vat].freeze

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


    def net
      @net ||= @gross / vat_percentage
    end

    def vat
      @vat ||= @gross - net
    end


    alias :percentage :vat_percentage
    alias :percentage= :vat_percentage=
    alias :curr :currency



    [:+,:-].each do |add_method|
      define_method(add_method) do |oth|
        oth = self.class.convert(oth)
        raise ArgumentError.new "Can't add two instances of #{self} with different VAT percentage" unless oth.percentage == percentage
        self.class.new(percentage: percentage).tap do |new_object|
          GNV.each {|m| new_object.send(:"#{m}=",send(m) + oth.send(m)) }
        end
      end
    end

    protected

    GNV.each do |m|
      define_method(:"#{m}=") do |arg|
        instance_variable_set(:"@#{m}",Util.convert_to_money(arg,@currency))
      end
    end


  end
end