module Vatcalc
  class Bill < Numeric

    include Comparable

    delegate :rates,:rates_changed?,:currency,:vat_percentages, to: :base

    attr_accessor :base,:total,:services

    [:base=,:total=,:services=].each {|i| private i}


    def initialize()
      @base = Base.new
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