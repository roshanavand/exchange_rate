# ExchangeRate

Get currency exchange rates using the European Central Bank's Euro
foreign exchange reference rates.

## Usage

To get the most recent exchange rate between two currencies:

    require_relative 'exchange_rate.rb'
    => true

    ExchangeRate.at(Date.today, 'EUR', 'NOK')
    => 9.662

    ExchangeRate.at(Date.today, 'NOK', 'EUR')
    => 0.10349824052991098

