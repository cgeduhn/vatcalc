module Vatcalc
  class Service


    attr_reader :gross
    def initialize(amount,options={})
      opt = options.to_h
      self.base = options[:base]
      @gross = Util.convert_to_money( amount || 0, currency )
    end

    delegate :rates,:rates_changed?,:currency,:vat_percentages, to: :base

    def base
      @base || Base.new
    end

    def base=(b)
      @base = b if b.is_a? Base
    end


    def net

    end

    def vat
      @gross - net
    end



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
    def gross_splitted

    end


  end
end