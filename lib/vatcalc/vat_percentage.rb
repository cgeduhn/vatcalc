module Vatcalc
  class VATPercentage < Numeric
    attr_reader :value

    def initialize(obj)
      @value = case obj
      when VATPercentage
        obj.value
      when Numeric
        convert_numeric_to_value(obj)
      else
        raise TypeError.new("Can't convert #{obj.class} #{obj} to an valid #{self.class}")
      end
    end

    delegate :to_i, to: :to_d
    delegate :to_s, to: :to_f

    def coerce(other)
      [self,other]
    end

    def <=>(other)
      to_d <=> as_d(other)
    end

    def ==(other)
      case other 
      when VATPercentage
        @value == other.value
      when Numeric,Float,Rational
        @value == convert_numeric_to_value(other)
      else
        false
      end
    end

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

    def to_d
      as_d(@value)
    end

    def to_f
      @value
    end

    def inspect
      "#<#{self.class.name} vat_percentage:#{to_f}>"
    end



    private 
    def as_d(num)
      if num.respond_to?(:to_d)
        num.is_a?(Rational) ? num.to_d(5) : num.to_d
      else
        BigDecimal.new(num.to_s.empty? ? 0 : num.to_s)
      end
    end

    def convert_numeric_to_value(num)
      case num
      when 0.00..0.99
        as_d(num.to_f + 1.00).to_f
      when 1..100.00
        as_d((num.to_f / 100 ) + 1.00).to_f
      end
    end


  end
end