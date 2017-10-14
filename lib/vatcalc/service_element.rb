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

    # Allocates net or gross by new vat_percentage rates and calculates the vat splitted by given rates
    # @param rates [Hash]
    # =>
    # 
    # @return [Hash]
    # @example
    #   => {#<Vatcalc::VATPercentage vat_percentage:19%>=>#<Money fractional:64 currency:EUR>,
    #       #<Vatcalc::VATPercentage vat_percentage:7%>=>#<Money fractional:39 currency:EUR>}
    #
    def change_rates(new_rates)
      if new_rates.is_a? Hash
        if !new_rates.empty?
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
          if @net_service 
            allocated = net.allocate(new_rates.values)
            gn_vector = ->(vp,splitted) { Vector[splitted * vp,splitted ] }
          else
            allocated = gross.allocate(new_rates.values)
            gn_vector = ->(vp,splitted) { Vector[splitted, splitted / vp] }
          end
          # Init new vector after the allocate calculation
          # Comes from superclass GNV
          init_vector(0,0)
          @vat_splitted = {}
          new_rates.keys.zip(allocated).each do |vp,splitted|
            vec = gn_vector[vp,splitted]
            @vector += vec
            @vat_splitted[vp] = vec[0] - vec[1] 
          end
          @rates = new_rates
        else
          @vat_splitted = {}
        end
        @rates = new_rates
      else
        ArgumentError.new "Hash must be given not #{arg.class}"
      end
    end

    def hash
      #vector comes from GNV
      [@vector,@vat_splitted].hash
    end

    def ==(oth)
      oth.is_a?(ServiceElement) && oth.gross == gross && oth.net == net && (@vat_splitted == oth.vat_splitted)
    end


    def inspect
      "#<#{self.class.name} vat_splitted:#{vat_splitted} gross:#{gross} net: #{net} vat:#{vat} currency: #{@currency}>"
    end


  end
end