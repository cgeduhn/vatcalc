require "spec_helper"

RSpec.describe Vatcalc::Util do
  let (:u){Vatcalc::Util}

  describe "converts" do 
    it "correctly to money" do 
      expect(u.convert_to_money(1.19)).to eq(Money.new(119,Vatcalc.currency))
      expect(u.convert_to_money(100)).to eq(Money.new(100,Vatcalc.currency))
      expect(u.convert_to_money(100.00)).to eq(Money.new(100*100,Vatcalc.currency))
      m = Money.new(1,Vatcalc.currency)
      expect(u.convert_to_money(m)).to eq(m)
    end

  end
end