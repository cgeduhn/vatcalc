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

        if @net_service 
          to_allocate = net
          new_gross = Money.new(0,self.currency)
          new_net = net
        else
          to_allocate = gross
          new_gross = gross
          new_net = Money.new(0,self.currency)
        end
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
          arg.keys.zip(to_allocate.allocate(arg.values)).to_h.each do |vp,splitted|
            if @net_service 
              splitted_net   = splitted
              splitted_gross = splitted_net * vp
              new_gross += splitted_gross
            else
              splitted_net   = splitted / vp
              splitted_gross = splitted
              new_net   += splitted_net
            end
            v_splitted[vp] = splitted_gross - splitted_net
          end
        end
        @vat_splitted = v_splitted
        init_vector(new_gross,new_net)
        @rates = arg
      else
        ArgumentError.new "Hash must be given not #{arg.class}"
      end
    end


    #TODO delegate + and - to: to_base 
    delegate :+,:-,:*, to: :to_gnv

    def hash
      #vector comes from GNV
      [gross,net].hash
    end

    def ==(oth)
      oth.is_a?(ServiceElement) ? oth.gross == gross && oth.net == net && (@vat_splitted == oth.vat_splitted) : false
    end


    def inspect
      "#<#{self.class.name} vat_splitted:#{vat_splitted} gross:#{gross} net: #{net} vat:#{vat} >"
    end


  end
end