require "vatcalc/version"
require 'active_support'
require 'active_support/core_ext'

require "vatcalc/util"
require "vatcalc/vat_percentage"

require "vatcalc/gnv"
require "vatcalc/base_element"
require "vatcalc/base"
require "vatcalc/service"

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


    def vat_of(v,vp=nil)
      BaseElement.new(v,percentage: vp).vat
    end

    def net_of(v,vp=nil)
      BaseElement.new(v,percentage: vp).net
    end

  end

  #German Standard Settings
  self.currency = "EUR"
  self.vat_percentage= 19.00

end
