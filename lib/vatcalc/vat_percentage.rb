module Vatcalc
  class VATPercentage < Numeric

    include Comparable

    attr_reader :value

    def initialize(obj)
      @value = case obj
      when VATPercentage
        obj.value
      when 0.00..0.99
        as_d(obj.to_f + 1.00)
      when 1..100.00
        as_d((obj.to_f / 100 ) + 1.00)
      else
        raise TypeError.new("Can't convert #{obj.class} #{obj} to an valid #{self.class}")
      end
    end

    delegate :to_i,:to_s,:to_f, to: :to_d


    #For comparisaon between a value or a +VATPercentage+
    #@return [Intger]
    #@see module Comparable
    def <=>(other)
      to_d <=> as_d(other)
    end

    #Returns a gross value
    #@return [Money]
    #@example
    # => 10.00 * VATPercentage.new(19) #=> #<Money fractional:1190 currency:EUR> 
    def *(other)
      case other
      when Money
        other * @value
      when Numeric
        Util.convert_to_money(other) * @value
      when VATPercentage
        raise TypeError.new "Can't multiply a VATPercentage by another VATPercentage"
      else
        if other.respond_to?(:coerce)
          a,b = other.coerce(self)
          a * b
        else
          raise TypeError.new "Can't multiply #{other.class} by VATPercentage"
        end
      end
    end

    #@see https://www.mutuallyhuman.com/blog/2011/01/25/class-coercion-in-ruby
    #Basic usage of coerce. Now you can write:
    # + 10.00 * VATPercentage.new(19) + 
    # and:  
    # + VATPercentage.new(19) * 10.00 + 
    def coerce(other)
      [self,other]
    end

    def to_d
      @value
    end

    def inspect
      "#<#{self.class.name} vat_percentage:#{to_d}>"
    end

    # Returns a Integer hash value based on the +value+
    # in order to use functions like & (intersection), group_by, etc.
    #
    # @return [Integer]
    #
    # @example
    #   VATPercentage.new(19).hash #=> 908351
    def hash
      [@value,self.class.name].hash
    end





    private 
    def as_d(num)
      if num.respond_to?(:to_d)
        num.is_a?(Rational) ? num.to_d(5) : num.to_d
      else
        BigDecimal.new(num.to_s.empty? ? 0 : num.to_s)
      end
    end

  end
end