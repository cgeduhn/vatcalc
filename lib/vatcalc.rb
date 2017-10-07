require "vatcalc/version"
require 'active_support'
require 'active_support/core_ext'

require "vatcalc/util"
require "vatcalc/base_object"
require "vatcalc/base"


module Vatcalc
  mattr_accessor :currency
  mattr_accessor :vat_percentage

  #German Standard Settings
  self.currency = "EUR"
  self.vat_percentage = 1.19




  class << self
    alias :percentage :vat_percentage
    alias :percentage= :vat_percentage=


    def vat_percentage
      @vat_percentage 
    end

    def vat_percentage=(v)
      @vat_percentage = Util.convert_to_percentage_value(v)
    end


    def vat_of(v,vp=nil)
      BaseObject.new(value: v,percentage: vp).vat
    end

    def net_of(v,vp=nil)
      BaseObject.new(value: v,percentage: vp).net
    end

  end


end
