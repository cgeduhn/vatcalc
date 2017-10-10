module Vatcalc
  class Bill < Numeric

    include Comparable


    attr_accessor :base,:total,:services

    [:base=,:total=,:services=].each {|i| private i}


    def initialize(currency=nil)
      @base = Base.new
      @total = GNV.new(0,0,currency)
      @services = []
    end

    [:+,:-].each do |m_name|
      define_method(m_name) do |oth|
        case oth
        when BaseElement
          v = @vector.send(m_name,oth.vector)
        when Service
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

    #@see https://www.mutuallyhuman.com/blog/2011/01/25/class-coercion-in-ruby
    def coerce(oth)
      [self,oth]
    end




  end
end