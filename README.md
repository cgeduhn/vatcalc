# Vatcalc

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/vatcalc`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'vatcalc'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install vatcalc

## Include

Include Vatcalc::ActsAsBillElement in your models / Classes

```ruby

class Product < ActiveRecord::Base
  include Vatcalc::ActsAsBillElement
  
  acts_as_bill_element(amount: price, vat_percentage: :my_vat_percentage_field, currency: "EUR", prefix: :bill)
  
  #you can pass the following key value pairs
  
  # amount: the price for the product [required]
  #     you can pass:
  #         symbol => for a method 
  #         lambda => ->(obj) {obj.price * 3}
  #         Float, Integer for a fix amount.
  #     NOTE: 
  #         if the value is an Integer it is assumed that the amount is given in cents.
  # 
  #
  # currency: 
  #     self-descriptive [optional] 
  #     standard value is the money default currency
  #     => https://github.com/RubyMoney/money
  #
  #     you can pass: 
  #         symbol => for a method 
  #         lambda => ->(obj) {obj.other_object.find_my_currency}
  #         String => "EUR", "USD"
  #
  #
  # vat_percentage: 
  #     the VAT percentage for the given product. [optional]
  #     This option will be ignored if you set the service option to true. +see below+
  #     Default is Vatcalc.vat_percentage => @see section "Configuration"
  #     you can pass: 
  #         symbol => for a method 
  #         lambda => ->(obj) {obj.find_my_currency}
  #         String => "EUR", "USD"
  #     NOTE: 
  #         if the value is between 1 and 100 the value will be divided by 100. 
  #         For example if you pass a value like 19 it is assumed that you mean 19% 
  #         if the value is between 0 and 100 the value won't be divided. 
  #
  # prefix: the prefix to call gross,vat,net,vat_splitted, and vat_percentage on your object.
  #        @see below.
  #
  #
  # net: 
  #     is the amount given as net amount ? [optional]
  #     Default => false
  #
  #
  #
  # service:
  #     is the object a service like a Coupon or a Fee ? If this option is set to true
  #     the object has not a fix VAT percentage.
  #     the vat will be calculated by the non-service object net rates in a bill.
  
  
  ....
  
  #now you can call 
  product.bill_gross #=> #<Money fractional:1000 currency:EUR>
  product.bill_net #=> #<Money fractional:840 currency:EUR> 
  product.bill_vat #=> #<Money fractional:160 currency:EUR> 
  
  
  product.bill_vat_splitted #=> {#<Vatcalc::VATPercentage vat_percentage:19%> => #<Money fractional:160 currency:EUR>}
  # the key in the result hash is a Vatcalc::VATPercentage object it responds to to_f, to_s, to_d
  # @example
  #     vp.to_s => "19%"
  #     vp.to_f => 1.19
  #     vp.to_d => #<BigDecimal:7f7ee20989a0,'0.119E1',18(36)>
  
  
end
```

## Bill

Creating a new bill object
```ruby

bill = Vatcalc::Bill.new(elements: [product1,product2,fee])

#NOTE: 
#    If you pass an Array of 2D arrays it is assumed that the first element in 2D Array is the object
#    and the second element is the quantity.
#    @example elements: 
#            [ 
#                [ product1, 2 ],
#                [ product2, 1 ] 
#            ]

#now you can call
bill.gross
bill.vat
bill.net
bill.vat_splitted #=> 

bill.rates # => 

bill.each do |obj, quantity, gross, vat, net|
    # do stuff .. 
end





```


## Configuration

```ruby
gem 'vatcalc'
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/vatcalc. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Vatcalc project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/vatcalc/blob/master/CODE_OF_CONDUCT.md).
