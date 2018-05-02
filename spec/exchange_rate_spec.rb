module ExchangeRate
  describe ExchangeRate do
    def rate_comparison(from, to, date, actual)
      expect(described_class.at(date, from, to)).to be_within(0.0001).of(actual)
    end

    describe '#at' do
      let(:date) { Date.parse('2018-04-17') }

      it 'matches the provided rates when converting from EUR' do
        [ ['EUR', 1.0],   ['SEK', 10.3913],  ['NOK', 9.598]
        ].each do |currency, value|
          rate_comparison('EUR', currency, date, value)
        end
      end

      it 'reports a rate of 1.0 between the same currency' do
        rate_comparison('NOK', 'NOK', date, 1.0)
      end
    end

  end

  describe InvalidDateError do
    it 'raises an error when value is not a "Date" type' do
      expect {
        ExchangeRate.at('Wrong Type', 'EUR', 'NOK')
      }.to raise_error(InvalidDateError)
    end
  end

  describe MissingDateError do
    it 'raises an error for a date more than 90 days ago' do
      expect {
        ExchangeRate.at(Date.today - 90, 'EUR', 'NOK')
      }.to raise_error(MissingDateError)
    end

    it 'does not raise an error for a date less than 90 days ago' do
      expect {
        ExchangeRate.at(Date.today - 89, 'EUR', 'NOK')
      }.to_not raise_error
    end
  end

  describe MissingExchangeRateError do
    before do
      ExchangeRate.send(:get_rates)

      rates = ExchangeRate.instance_variable_get(:@rates)
      rates[Date.today.to_s]['NOK'] = nil

      ExchangeRate.instance_variable_set(:@rates, rates)
    end

    after do
      ExchangeRate.instance_variable_set(:@rates, nil)
    end

    it 'raises an error when data is missing' do
      expect {
        ExchangeRate.at(Date.today, 'EUR', 'NOK')
      }.to raise_error(MissingExchangeRateError)

      expect {
        ExchangeRate.at(Date.today, 'NOK', 'EUR')
      }.to raise_error(MissingExchangeRateError)
    end

    it 'does not raise an error if we have data available' do
      expect {
        ExchangeRate.at(Date.today, 'EUR', 'SEK')
      }.not_to raise_error

      expect {
        ExchangeRate.at(Date.today, 'SEK', 'EUR')
      }.not_to raise_error
    end
  end

  describe UnknownCurrencyError do
    it 'raises an error on an unsupported currency code' do
      expect {
        ExchangeRate.at('NOK', 'UNKNOWN')
      }.to raise_error(UnknownCurrencyError)

      expect {
        ExchangeRate.at('UNKNOWN', 'NOK')
      }.to raise_error(UnknownCurrencyError)
    end

    it 'does not raise an error for supported currency codes' do
      expect {
        ExchangeRate.at('EUR', 'NOK')
      }.not_to raise_error
    end
  end

end
