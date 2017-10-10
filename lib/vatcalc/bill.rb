module Vatcalc
  class Bill < Numeric

    include Comparable

    delegate :rates,:rates_changed?,:currency,:vat_percentages, to: :base

    attr_accessor :base,:total,:services

    [:base=,:services=].each {|i| private i}


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




  end
end