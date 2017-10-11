module Vatcalc
  class Service


    attr_reader :gross
    def initialize(amount,options={})
      self.base = options[:base]
      @gross = Util.convert_to_money( amount || 0, currency )
    end

    delegate :rates,:rates_changed?,:currency,:vat_percentages,:allocate, to: :base

    def net
      @gross - vat
    end

    def vat
      vat_splitted.values.sum
    end

    def base
      @base || Base.new
    end

    def base=(b)
      if b.is_a? Base
        @vat_splitted = nil
        @base = b
      else
        nil
      end
      @base = b if b.is_a? Base
    end


    def vat_splitted
      return @vat_splitted if !rates_changed? && @vat_splitted
      @vat_splitted = allocate(@gross).inject({}) do |h,(vp,splitted_money)|
        h[vp] = splitted_money - (splitted_money / vp)
        h
      end
    end


  end
end