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

    include Comparable

    attr_reader :vector,:currency
    attr_accessor :source

    def initialize(gross,net,cur=nil)
      @currency ||= (cur || Vatcalc.currency)
      init_vector(gross,net)
    end

    [:+,:-].each do |m_name|
      define_method(m_name) do |oth|
        gnv = oth.is_a?(GNV) ? to_gnv(@vector.send(m_name,oth.vector)) : raise(TypeError.new) 
        gnv.tap do |g|
          g.vat_splitted = oth.vat_splitted.merge(self.vat_splitted) {|vp,m1,m2| m1 + m2}
        end
      end
    end

    def *(oth)
      gnv = oth.is_a?(Numeric) ? to_gnv(@vector * oth) : raise(TypeError.new) 
      gnv.tap do |g|
        h = new_money_hash
        self.vat_splitted.each {|vp,m| h[vp] = m*oth}
        g.vat_splitted = h
      end
    end

    #For usage of => - GNV.new(100.00,90.00)
    def -@
      to_gnv(-@vector)
    end


    def ==(oth)
      oth.is_a?(GNV) && oth.vector == @vector
    end

    alias_method :eql?, :==

    def <=>(other)
      if other.respond_to?(:net)
        net <=> other.net
      else
        net <=> other
      end
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

    def vat_splitted
      @vat_splitted ||= new_money_hash
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

    def to_gnv(v=@vector)
      GNV.new(v[0],v[1],@currency)
    end

    protected

    def vat_splitted=(h)
      @vat_splitted = h
    end

    private 

    def init_vector(g,n)
      @vector = Vector[*[g,n].map{|i| Util.to_money(i,@currency)}]
    end

    def new_money_hash
      Hash.new(Money.new(0,@currency))
    end


  end
end