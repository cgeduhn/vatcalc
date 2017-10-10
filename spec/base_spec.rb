require "spec_helper"

RSpec.describe Vatcalc::Base do
  let (:b) {Vatcalc::Base.new}
  it "inserts anything correctly" do
    b << ([100.00, 7])
    expect(b.each_elem.length).to eq(1)

    b << ([100])
    expect(b.each_elem.length).to eq(2)

    expect(b.gross.to_f).to eq(101.00)

    b << {percentage: 19.00,value: 100.00}

    expect(b.gross.to_f).to eq(201.00)
    expect(b.net.to_f).to eq(178.33)
    expect(b.vat.to_f).to eq((201.00 - 178.33).round(2))
    expect(b.percentages.length).to eq(2)
  end


  it "has correctly rates if net is 0" do
    b << [0,0.00]
    expect(b[0.00].gross.to_f).to eq(0.00)
    expect(b.percentages).to eq([Vatcalc::VATPercentage.new(0.00)])
    expect(b.rates).to eq({Vatcalc::VATPercentage.new(0.00) => 1.00})
  end


  it "can add an object with quantity 10" do 
    obj1 = Vatcalc::BaseElement.new(10.00,vat_percentage: 19)
    result = Vatcalc::Base.new.insert(obj1,10)

    expect(result.gross.to_f).to eq(100.00)
    expect(result.net.to_f).to eq(84.00)
    expect(result.vat.to_f).to eq(16.00)
  end


  it "can add an object with quantity 100" do 
    obj1 = Vatcalc::BaseElement.new(5.5,vat_percentage: 19)
    result = Vatcalc::Base.new.insert(obj1,100)

    expect(result.gross.to_f).to eq(550.00)
    expect(result.net.to_f).to eq(462.00)
    expect(result.vat.to_f).to eq(88.00)
  end

  it "has correctly rates" do
    r = Proc.new{|it| rand(100000).to_f * (rand*100)}
    100.times do |i|
      b = Vatcalc::Base.new
      b.insert [r.call,0.00], 2
      b << [r.call,0.00]
      b.insert [r.call,19], 5
      b << [r.call,7]
      vs = b.rates.values.collect{|s| (s*100).round(2)}
      rounded_sum = vs.inject(0){|s,i| s+=i}.round(4)
      # p "---#{b.rates}"
      #p "#{b.human_rates}"
      expect(rounded_sum).to eq(100)
    end


  end
end
