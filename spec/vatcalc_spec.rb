require "spec_helper"

RSpec.describe Vatcalc do
  it "has a version number" do
    expect(Vatcalc::VERSION).not_to be nil
  end

  describe "converts" do 
    let (:u){Vatcalc::Util}
    it "correctly to percentage" do 
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

    it "correctly to money" do 
      expect(u.convert_to_money(1.19)).to eq(Money.euro(119))
      expect(u.convert_to_money(100)).to eq(Money.euro(100))
      expect(u.convert_to_money(100.00)).to eq(Money.euro(100*100))

      m = Money.euro(1)
      expect(u.convert_to_money(m)).to eq(m)
    end
  end
end
