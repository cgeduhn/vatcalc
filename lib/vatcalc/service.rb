module Vatcalc
  class Service < GNV


    attr_reader :vat_splitted

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



  end
end