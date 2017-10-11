module Vatcalc
  class ServiceElement < GNV


    attr_reader :vat_splitted

    delegate :rates,to: :@base

    def initialize(amount,options={})
      @base = options.fetch(:base,Base.new)

      calculate_splitted_values(amount)

      super amount, @net_splitted.values.sum , @base.currency
    end


    def calculate_splitted_values(amount=nil)
      @gross_splitted = @base.allocate(amount || self.gross)
      @vat_splitted = {}
      @net_splitted = {}

      @gross_splitted.each do |vp,splitted_gross|
        @net_splitted[vp] = splitted_gross / vp
        @vat_splitted[vp] = splitted_gross - @net_splitted[vp] 
      end
    end


    #TODO delegate + and - to: to_base 
    delegate :+,:-,:*, to: :to_gnv

    def hash
      #vector comes from GNV
      [@vector,@vat_splitted,@net_splitted,self.class].hash
    end

    def ==(oth)
      oth.is_a?(ServiceElement) ? (oth.vector == @vector) && (@vat_splitted == oth.vat_splitted) && (@net_splitted == oth.net_splitted) : false
    end


    def inspect
      "#<#{self.class.name} vat_splitted:#{vat_splitted} gross:#{gross} net: #{net} vat:#{vat} >"
    end



  end
end