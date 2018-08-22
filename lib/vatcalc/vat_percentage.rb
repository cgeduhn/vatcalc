module Vatcalc
  class VATPercentage < Numeric

    include Comparable

    attr_reader :value

    #Init a VATPercentage object by
    # => Integer
    #   => VATPercentage.new 19
    # => Float
    #   => VATPercentage.new 0.19
    # => String
    #   =>  VATPercentage.new 19%
    #   =>  VATPercentage.new 19,1%
    #   =>  VATPercentage.new 19,1%
    #   =>  VATPercentage.new 19.1%
    def initialize(obj)
      @value = case obj
      when VATPercentage
        obj.value
      when 0.00..0.99
        as_d(obj.to_f + 1.00)
      when 1..100.00
        as_d((obj.to_f / 100 ) + 1.00)
      else
        if obj.is_a?(String) && obj.match(/[0-9]{0,2}\.|\,{0,1}[0-9]{0,2}/)
          as_d((obj.gsub("," , ".").to_f / 100) + 1.00)
        else
          raise TypeError.new("Can't convert #{obj.class} #{obj} to an valid #{self.class}")
        end
      end
    end

    delegate :to_i,:to_f, to: :to_d


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
    [:/,:*].each do |m_name|

      define_method(m_name) do |other|

        case other
        when Money
          other.send(m_name,@value)
        when Numeric
          Util.convert_to_money(other).send(m_name,@value)
        when VATPercentage
          raise TypeError.new "Can't '#{m_name}' a VATPercentage by another VATPercentage"
        else
          if other.respond_to?(:coerce)
            a,b = other.coerce(self)
            a * b
          else
            raise TypeError.new "Can't '#{m_name}' #{other.class} by VATPercentage"
          end
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
      "#<#{self.class.name} vat_percentage:#{to_s}>"
    end

    # Returns a Integer hash value based on the +value+
    # in order to use functions like & (intersection), group_by, etc.
    #
    # @return [Integer]
    #
    # @example
    #   VATPercentage.new(19).hash #=> 908351
    def hash
      [@value,self.class].hash
    end

    def to_s 
      Util.human_percentage_value(@value-1.00)
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