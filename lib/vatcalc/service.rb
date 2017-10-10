module Vatcalc
  class Service


    attr_reader :gross
    def initialize(amount,options={})
      self.base = options[:base]
      @gross = Util.convert_to_money( amount || 0, currency )
    end

    delegate :rates,:rates_changed?,:currency,:vat_percentages, to: :base

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
      @base = b if b.is_a? Base
    end


    def vat_splitted
      return @vat_splitted if !rates_changed? && @vat_splitted
      @vat_splitted = allocate(@gross).inject({}) do |h,(vp,money)|
        h[vp] = money - (money / vp)
        h
      end
    end


    # Using the allocate function of the Money gem here.
    # EXPLANATION FROM MONEY GEM: 
    #
    # Allocates money between different parties without losing pennies.
    # After the mathematical split has been performed, leftover pennies will
    # be distributed round-robin amongst the parties. This means that parties
    # listed first will likely receive more pennies than ones that are listed later
    #
    # @param [Array<Numeric>] splits [0.50, 0.25, 0.25] to give 50% of the cash to party1, 25% to party2, and 25% to party3.
    #
    # @return [Array<Money>]
    #
    # @example
    #   Money.new(5,   "USD").allocate([0.3, 0.7])         #=> [Money.new(2), Money.new(3)]
    #   Money.new(100, "USD").allocate([0.33, 0.33, 0.33]) #=> [Money.new(34), Money.new(33), Money.new(33)]
    #
    def allocate(amount)
      rates.keys.zip(amount.allocate(rates.values)).to_h
    end


  end
end