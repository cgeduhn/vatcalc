require "matrix"

#A GNV Object consists basically of a 2D Vector
#first value is gross, second is net.
#vat is calculated by gross - net
#gross is always greater or equal net
#
#example
#GNVObject.new(10.00,9.00)
#you can add or subtract two GNVObjects
#GNVObject.new(10.00,9.00) + GNVObject.new(9.00,0.00)
module Vatcalc
  class GNVObject 

    attr_reader :vector,:currency
    alias :curr :currency
    def initialize(gross,net,currency=nil)
      @currency ||= Vatcalc.currency
      @vector = Vector[*[gross,net].map{|i| Util.convert_to_money(i,@currency)}]
      raise ArgumentError.new "gross: #{gross.to_f} must >= net: #{net.to_f}" if self.gross.abs < self.net.abs
    end

    delegate :==, to: :@vector
    delegate :addition_klass,to: :class


    [:+,:-].each do |m_name|
      define_method(m_name) do |oth|
        if oth.is_a?(GNVObject)
          v = @vector.send(m_name,oth.vector)
        elsif oth < Numeric
          v = @vector.send(m_name,oth)
        elsif oth.respond_to?(:coerce)
          #@see https://www.mutuallyhuman.com/blog/2011/01/25/class-coercion-in-ruby
          a, b = other.coerce(self)
          return a.send(b)
        else
          raise TypeError, "#{oth.class} can't be coerced into #{self.class}"
        end
        init_by_vector(v)
      end
    end

    #For usage of => - GNVObject.new(100.00,90.00)
    def -@
      init_by_vector(-@vector)
    end

    #@see https://www.mutuallyhuman.com/blog/2011/01/25/class-coercion-in-ruby
    def coerce(oth)
      [self,oth]
    end

    def gross
      @vector[0]
    end

    def net
      @vector[1]
    end

    #Always gross - net
    def vat
      gross - net
    end

    def to_gnv
      GNVObject.init_by_vector(@vector)
    end

    delegate :init_by_vector, to: :class

    private 
    def self.init_by_vector(v)
      new(v[0],v[1])
    end


  end
end