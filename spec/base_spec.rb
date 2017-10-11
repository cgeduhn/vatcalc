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


  it "can add and substract object with quantity 100" do 
    obj1 = Vatcalc::BaseElement.new(5.5,vat_percentage: 19)
    result = Vatcalc::Base.new.insert(obj1,100)
    expect(result.each_elem.size).to eq(1)
    expect(result.each_elem[0][1]).to eq(100)

    expect(result.gross.to_f).to eq(550.00)
    expect(result.net.to_f).to eq(462.00)
    expect(result.vat.to_f).to eq(88.00)

    obj2 = Vatcalc::BaseElement.new(5.5,vat_percentage: 19)

    

    h = {obj1 => 1}

    expect(obj1).to eq(obj2)
    expect(obj1.hash).to eq(obj2.hash)
    expect(obj1 > obj2).to eq(false)
    expect(obj1 < obj2).to eq(false)
    expect(obj1 <= obj2).to eq(true)
    expect(obj1 >= obj2).to eq(true)

    expect(h.has_key? obj1).to eq(true)
    expect(h.has_key? obj2).to eq(true)

    result.remove(obj2,50)

    expect(result.gross.to_f).to eq(275.00)
    expect(result.net.to_f).to eq(231.00)
    expect(result.vat.to_f).to eq(44.00)
    
    expect(result.each_elem.size).to eq(1)
    expect(result.each_elem[0][1]).to eq(50)

  end

  it "has correctly rates" do
    r = Proc.new{|it| rand(100000).to_f * (rand*100)}
    100.times do |i|
      b = Vatcalc::Base.new
      b.insert [r.call,0.00], 2
      b << [r.call,0.00]
      b.insert [r.call,19], 5
      b << [r.call,7]
      #p "#{b.human_rates}"

      d = (b.rates.values.sum.to_d(Vatcalc::Base::RoundPrecision))
      expect(1.00 - d).to be <= (Vatcalc::Base::Tolerance)
    end


  end
end
