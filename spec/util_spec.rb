require "spec_helper"

RSpec.describe Vatcalc::Util do
  let (:u){Vatcalc::Util}

  describe "converts" do 
    it "correctly to money" do 
      expect(u.convert_to_money(1.19)).to eq(Money.euro(119))
      expect(u.convert_to_money(100)).to eq(Money.euro(100))
      expect(u.convert_to_money(100.00)).to eq(Money.euro(100*100))
      m = Money.euro(1)
      expect(u.convert_to_money(m)).to eq(m)
    end

    it "calculates correctly net" do
      expect(Vatcalc.net_of(11.00).to_f).to eq(9.24)
    end

    it "calculates correctly net" do 
      expect(Vatcalc.vat_of(11.00).to_f).to eq(1.76)
    end
  end
end