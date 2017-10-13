module Vatcalc
  class ServiceElement < GNV


    attr_reader :vat_splitted,:rates


    def initialize(amount,opt={})

      if opt[:net] == true
        @net_service = true
        super 0, amount, (opt[:currency] || opt[:curr])
      else
        @net_service = false
        super amount, 0, (opt[:currency] || opt[:curr])
      end

      change_rates opt.fetch(:rates,{})

    end

    def change_rates(arg)
      if arg.is_a? Hash

        v_splitted = {}
        new_net   = Money.new(0,@currency)
        new_gross = Money.new(0,@currency)

        # Allocates a amount to the vat_percentage rates
        # @return [Hash]
        # @example
        #   Vatcalc::Service.allocate(100.00) 
        #   => {1.19 => #<Money fractional:50 currency:EUR>, 1.07 => #<Money fractional:50 currency:EUR>}
        #
        # Using basically the allocate function of the Money gem here.
        # EXPLANATION FROM MONEY GEM: 
        #
        # Allocates money between different parties without losing pennies.
        # After the mathematical split has been performed, leftover pennies will
        # be distributed round-robin amongst the parties. This means that parties
        # listed first will likely receive more pennies than ones that are listed later
        
        # @param [Array<Numeric>] splits [0.50, 0.25, 0.25] to give 50% of the cash to party1, 25% to party2, and 25% to party3.
        
        # @return [Array<Money>]
        
        # @example
        #   Money.new(5,   "USD").allocate([0.3, 0.7])         #=> [Money.new(2), Money.new(3)]
        #   Money.new(100, "USD").allocate([0.33, 0.33, 0.33]) #=> [Money.new(34), Money.new(33), Money.new(33)]
        #
        if !arg.empty?
          to_allocate = @net_service ? net : gross

          arg.keys.zip(to_allocate.allocate(arg.values)).to_h.each do |vp,splitted|

            if @net_service 
              splitted_net   = splitted
              splitted_gross = splitted_net * vp
            else
              splitted_net   = splitted / vp
              splitted_gross = splitted
            end
            new_net   += splitted_net
            new_gross += splitted_gross

            v_splitted[vp] = splitted_gross - splitted_net
          end
        end

        @vat_splitted = v_splitted
        @vector = Vector[gross,new_net]
        @rates = arg
      else
        ArgumentError.new "Hash must be given not #{arg.class}"
      end
    end


    #TODO delegate + and - to: to_base 
    delegate :+,:-,:*, to: :to_gnv

    def hash
      #vector comes from GNV
      [@vector,@vat_splitted,@net_splitted,self.class].hash
    end

    def ==(oth)
      oth.is_a?(ServiceElement) ? (oth.vector == @vector) && (@vat_splitted == oth.vat_splitted) : false
    end


    def inspect
      "#<#{self.class.name} vat_splitted:#{vat_splitted} gross:#{gross} net: #{net} vat:#{vat} >"
    end


  end
end