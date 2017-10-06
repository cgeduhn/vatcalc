require "vatcalc/version"
require 'active_support'

require "vatcalc/util"
require "vatcalc/base_object"


module Vatcalc
  mattr_accessor :currency
  self.currency = "EUR"
end
