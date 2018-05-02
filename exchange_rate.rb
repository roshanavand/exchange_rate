require 'date'
require 'nokogiri'

module ExchangeRate
  DATA_SOURCE = 'files/eurofxref-hist-90d.xml'
  CURRENCIES = %w(EUR SEK NOK)

  class << self # Class methods
    def at(date = Date.today, base, counter)
      validate(base, counter, date)

      get_rates
      date = closest_available_date(date)

      1.0 / exchange_rate(of: base, at: date) *
        exchange_rate(of: counter, at: date)
    end

    private

    # Find the closest date with available data.
    #
    # Returns the requested date if data is available. If not, we search back
    # up to five days to see if there is available data. This is primarily
    # used to handle weekends and holidays when ECB does not publish data. We
    # will print a warning message (see +silence_warnings+) if we are using
    # a date other than the one specified.
    def closest_available_date(date)
      closest = date.to_date

      5.times do
        return closest if @rates.key?(closest.to_s)
        closest -= 1
      end

      raise MissingDateError.new(date)
    end

    # Grab the exchange rate for a currency on a particular date.
    def exchange_rate(opts)
      @rates[opts[:at].to_s][opts[:of]] ||
        MissingExchangeRateError.new(opts[:of])
      #unless rate = @rates[opts[:at].to_s][opts[:of]]
        #raise MissingExchangeRateError.new(opts[:of]) unless rate
      #end
    end

    def get_rates
      @rates ||= parse_data
    end

    def parse_data
      data = {}

      doc = File.open(DATA_SOURCE) { |f| Nokogiri::XML(f) }

      nodeset = doc.xpath('gesmes:Envelope/xmlns:Cube/xmlns:Cube')

      nodeset.each do |element|
        data.merge!(parse_element(element))
      end

      data
    end

    def parse_element(element)
      date = element.attribute('time').value
      data = {}

      element = element.xpath('xmlns:Cube')
      element.each do |entry|
        currency = entry.attribute('currency').value
        rate = entry.attribute("rate").value
        data[currency] = rate.to_f
      end

      data['EUR'] = 1.0

      { date => data }
    end

    # Raise errors for invalid currencies or missing data.
    def validate(base, counter, date)
      raise UnknownCurrencyError.new(base) if !CURRENCIES.include?(base)
      raise UnknownCurrencyError.new(counter) if !CURRENCIES.include?(counter)
      raise InvalidDateError if !date.respond_to?(:to_date)
    end

  end

  # Exceptions
  class InvalidDateError < StandardError
    def initialize
      super("Date must be a 'Date' type")
    end
  end

  class MissingDateError < StandardError
    def initialize(date)
      super("Foreign exchange reference rate for #{date.to_s} is missing.")
    end
  end

  # = ECB Missing Exchange Rate Error
  #
  # Raised when the data for a supported currency code is +nil+ or +zero?+.
  #
  # * +currency_code+ - the unsupported ISO 4217 Currency Code.
  class MissingExchangeRateError < StandardError
    def initialize(currency_code)
      raise super(
        "Foreign exchange reference rate for #{currency_code} is missing."
      )
    end
  end

  # = ECB Unknown Currency Error
  #
  # Raised when we try to grab data for an unsupported currency code.
  #
  # * +currency_code+ - the unsupported ISO 4217 Currency Code.
  class UnknownCurrencyError < StandardError
    def initialize(currency_code)
      super("#{currency_code} is not supported.")
    end
  end

end
