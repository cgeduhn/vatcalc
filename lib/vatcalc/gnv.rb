require "matrix"

# A GNV Object consists basically of a 2D Vector
# First value is gross, second is net.
# Vat is calculated by gross - net
# 
# GNV is an abstract Object and should only used for internal calculations in this library.
#
#@example
# GNV.new(10.00,9.00)
#
# You can add or subtract two GNVs
# GNV.new(10.00,9.00) + GNV.new(9.00,0.00)
module Vatcalc
  class GNV 

    attr_reader :vector,:currency

    
    alias :curr :currency
    delegate :==, to: :@vector
    delegate :<,:>,:<=,:>=, to: :net

    def initialize(gross,net,curr=nil)
      @currency ||= (curr || Vatcalc.currency)
      @vector = Vector[*[gross,net].map{|i| Util.convert_to_money(i,@currency)}]
      raise ArgumentError.new "gross: #{gross.to_f} must >= net: #{net.to_f}" if self.gross.abs < self.net.abs
    end

    [:+,:-,:*].each do |m_name|
      define_method(m_name) do |oth|
        if oth.is_a?(GNV) && m_name != :*
          v = @vector.send(m_name,oth.vector)
        elsif oth.is_a?(Numeric) && m_name == :*
          v = @vector.send(m_name,oth)
        else
          #@see https://www.mutuallyhuman.com/blog/2011/01/25/class-coercion-in-ruby
          if oth.respond_to?(:coerce)
            a, b = other.coerce(self)
            return a.send(b)
          else
            raise TypeError.new "#{oth.class} can't be coerced into #{self.class}"
          end
        end
        self.class.init_by_vector(v)
      end
    end

    #For usage of => - GNV.new(100.00,90.00)
    def -@
      self.class.init_by_vector(-@vector)
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

    # Returns a Integer hash value based on the +value+
    # in order to use functions like & (intersection), group_by, etc.
    #
    # @return [Integer]
    #
    # @example
    #   GNV.new(19,11).hash #=> 908351
    def hash
      @vector.hash
    end

    #Always gross - net
    def vat
      gross - net
    end

    def to_gnv
      GNV.init_by_vector(@vector)
    end

    private 
    def self.init_by_vector(v)
      new(v[0],v[1],@currency)
    end


  end
end