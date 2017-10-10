module Vatcalc
  class Bill < Numeric

    include Comparable

    delegate :rates,:rates_changed?,:currency,:vat_percentages, to: :base

    attr_accessor :base,:total,:services

    [:base=,:services=].each {|i| private i}


    def initialize()
      @base = Base.new
      @services = Hash.new(0)
    end

    def insert(obj,quantity=1)
      case oth
      when Service
        @services[obj] += 1
      when BaseElement
        @base.insert(obj,quantity)
      else 
        # TODO definie if obj respond_to_ acts_as_vat_service or acts_as_base_element ? 
      end
      return self
    end


  end
end