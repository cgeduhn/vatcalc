require "spec_helper"


RSpec.describe Vatcalc do
  it "has a version number" do
    expect(Vatcalc::VERSION).not_to be nil
  end

  it "calculates correctly net" do
    expect(Vatcalc.net_of(11.00).to_f).to eq(9.24)
  end

  it "calculates correctly vat" do 
    expect(Vatcalc.vat_of(11.00).to_f).to eq(1.76)
  end

  
end








