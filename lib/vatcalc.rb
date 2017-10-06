require "vatcalc/version"
require 'active_support'

require "vatcalc/util"
require "vatcalc/base_object"


module Vatcalc
  mattr_accessor :currency
  mattr_accessor :vat_percentage

  #German Standard Settings
  self.currency = "EUR"
  self.vat_percentage = 1.19

  def self.vat_percentage
    @vat_percentage 
  end

  def self.vat_percentage=(v)
    @vat_percentage = Util.convert_to_percentage_value(v)
  end


end
