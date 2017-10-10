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

    def insert(obj,quantity=1)
      case oth
      when Service
        v = @vector.send(m_name,oth)
      else
        @base.insert(obj,quantity)
      end
    end
    

    #@see https://www.mutuallyhuman.com/blog/2011/01/25/class-coercion-in-ruby
    def coerce(oth)
      [self,oth]
    end




  end
end