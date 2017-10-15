require "vatcalc/version"
require 'active_support'
require 'active_support/core_ext'

require "vatcalc/util"
require "vatcalc/vat_percentage"

require "vatcalc/gnv"
require "vatcalc/base_element"

require "vatcalc/service_element"
require "vatcalc/bill"

require "vatcalc/acts_as_bill_element"

module Vatcalc
  mattr_accessor :currency

  class << self

    def vat_percentage
      @vat_percentage
    end

    def vat_percentage=(v)
      @vat_percentage = VATPercentage.new(v)
    end

    alias :percentage :vat_percentage
    alias :percentage= :vat_percentage=


    def vat_of(v,**args)
      BaseElement.new(v,**args).vat
    end

    def net_of(v,**args)
      BaseElement.new(v,**args).net
    end

    def gross_of(v,**args)
      BaseElement.new(v,**args).gross
    end

  end

  #German Standard Settings
  self.currency = "EUR"
  self.vat_percentage= 19.00

end
