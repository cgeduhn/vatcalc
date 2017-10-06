require "spec_helper"

RSpec.describe Vatcalc do
  it "has a version number" do
    expect(Vatcalc::VERSION).not_to be nil
  end

  it "converty values correctly to percentage" do 
  	u = Vatcalc::Util
  	expect(u.convert_to_percentage_value(1.19)).to eq(1.19)
  	expect(u.convert_to_percentage_value(0.19)).to eq(1.19)
  	expect(u.convert_to_percentage_value(19)).to eq(1.19)

  	expect(u.convert_to_percentage_value(7)).to eq(1.07)
  	expect(u.convert_to_percentage_value(1.07)).to eq(1.07)
  	expect(u.convert_to_percentage_value(0.07)).to eq(1.07)

  	expect(u.convert_to_percentage_value(1)).to eq(1.01)
  	
  	expect(u.convert_to_percentage_value(0)).to eq(1.00)
  	expect(u.convert_to_percentage_value(0.00)).to eq(1.00)
  end
end
