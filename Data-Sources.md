# Data Sources

The `ta4j-examples` module provides a comprehensive set of data sources for loading historical OHLCV (Open, High, Low, Close, Volume) data into `BarSeries` objects. All data sources implement the `BarSeriesDataSource` interface, which provides a unified, domain-driven API for loading data using business concepts like ticker symbols, intervals, and date ranges.

## Overview

The `BarSeriesDataSource` interface abstracts away implementation details (files, APIs, databases) and allows you to work with trading domain concepts:

```java
// All data sources share the same interface
BarSeriesDataSource yahoo = new YahooFinanceHttpBarSeriesDataSource(true); // With caching
BarSeriesDataSource csv = new CsvFileBarSeriesDataSource();
BarSeriesDataSource json = new JsonFileBarSeriesDataSource();

// Same interface, different implementations

// retrieve AAPL Daily OHLC data from Yahoo Finance's API
BarSeries aapl = yahoo.loadSeries("AAPL", Duration.ofDays(1), 
    Instant.parse("2023-01-01T00:00:00Z"),
    Instant.parse("2023-12-31T23:59:59Z"));

// retrieve BTC-USD Daily OHLC data from a local CSV file using domain-level criteria (file system abstracted away)
BarSeries btc = csv.loadSeries("BTC-USD", Duration.ofDays(1),
    Instant.parse("2023-01-01T00:00:00Z"),
    Instant.parse("2023-12-31T23:59:59Z"));

// of course you can also retrieve by filename
BarSeries eth = json.loadSeries("Coinbase-ETH-USD-PT1D-20241105_20251020.json");

```

## Core Interface

### `BarSeriesDataSource`

The base interface for all data sources provides three main methods:

#### `loadSeries(String ticker, Duration interval, Instant start, Instant end)`

Loads a `BarSeries` using business domain concepts. This is the primary method for loading data.

**Parameters:**
- `ticker` - The ticker symbol or identifier (e.g., "AAPL", "BTC-USD", "MSFT")
- `interval` - The bar interval (e.g., `Duration.ofDays(1)` for daily bars, `Duration.ofHours(1)` for hourly bars)
- `start` - The start date/time for the data range (inclusive)
- `end` - The end date/time for the data range (inclusive)

**Returns:** A `BarSeries` containing the loaded data, or `null` if no matching data is found or loading fails

**Throws:** `IllegalArgumentException` if any parameter is invalid (e.g., null ticker, negative interval, start after end)

#### `loadSeries(String source)`

Loads a `BarSeries` directly from a known source identifier. This method bypasses the search/fetch logic and loads directly from the specified source.

**Parameters:**
- `source` - The source identifier (filename, resource name, URL, etc.)

**Returns:** A `BarSeries` containing the loaded data, or `null` if loading fails

**Throws:** `IllegalArgumentException` if the source parameter is invalid or unsupported

#### `loadSeries(InputStream inputStream)`

Loads a `BarSeries` from an `InputStream`. This method is optional - implementations that don't support `InputStream` loading throw `UnsupportedOperationException`.

**Parameters:**
- `inputStream` - The input stream containing the data

**Returns:** A `BarSeries` containing the loaded data, or `null` if loading fails

**Throws:** `UnsupportedOperationException` if this data source doesn't support `InputStream` loading

## HTTP-Based Data Sources

HTTP-based data sources fetch data from remote APIs. They extend `AbstractHttpBarSeriesDataSource` which provides common functionality like response caching, pagination, and HTTP client management.

### Yahoo Finance Data Source

`YahooFinanceHttpBarSeriesDataSource` loads historical price data from Yahoo Finance's public API without requiring an API key. It supports stocks, ETFs, and cryptocurrencies.

#### Features

- **No API key required** - Uses Yahoo Finance's public API
- **Automatic pagination** - Splits large requests into multiple API calls
- **Response caching** - Optional disk-based caching for faster subsequent requests (see [Response Caching](#response-caching-http-sources))
- **Multiple intervals** - Supports 1m, 5m, 15m, 30m, 1h, 4h, 1d, 1wk, 1mo
- **Rate limit handling** - Conservative limits to avoid temporary bans

#### Supported Intervals

The `YahooFinanceInterval` enum provides the following intervals:

- `MINUTE_1` - 1 minute bars
- `MINUTE_5` - 5 minute bars
- `MINUTE_15` - 15 minute bars
- `MINUTE_30` - 30 minute bars
- `HOUR_1` - 1 hour bars
- `HOUR_4` - 4 hour bars
- `DAY_1` - 1 day bars
- `WEEK_1` - 1 week bars
- `MONTH_1` - 1 month bars

#### Basic Usage

**Static Methods (Quick & Simple):**

```java
// Load 1 year of daily data for Apple stock (using days)
BarSeries series = YahooFinanceHttpBarSeriesDataSource.loadSeries("AAPL", 365);

// Load 500 bars of hourly data for Bitcoin (using bar count)
BarSeries btcSeries = YahooFinanceHttpBarSeriesDataSource.loadSeries("BTC-USD", 
    YahooFinanceInterval.HOUR_1, 500);

// Load data for a specific date range
Instant start = Instant.parse("2023-01-01T00:00:00Z");
Instant end = Instant.parse("2023-12-31T23:59:59Z");
BarSeries msftSeries = YahooFinanceHttpBarSeriesDataSource.loadSeries("MSFT", 
    YahooFinanceInterval.DAY_1, start, end);
```

**Instance Methods (With Caching & Customization):**

```java
// Create an instance with caching enabled
YahooFinanceHttpBarSeriesDataSource loader = new YahooFinanceHttpBarSeriesDataSource(true);
BarSeries series = loader.loadSeriesInstance("AAPL", YahooFinanceInterval.DAY_1, start, end);

// Or with custom cache directory (caching automatically enabled)
YahooFinanceHttpBarSeriesDataSource loader = new YahooFinanceHttpBarSeriesDataSource("/my/cache/dir");
BarSeries series = loader.loadSeriesInstance("AAPL", YahooFinanceInterval.DAY_1, start, end);
```

#### Using the Interface

```java
// Using the BarSeriesDataSource interface
BarSeriesDataSource yahoo = new YahooFinanceHttpBarSeriesDataSource();
BarSeries series = yahoo.loadSeries("AAPL", Duration.ofDays(1), start, end);
```

#### Static vs Instance Methods

HTTP-based data sources provide two ways to load data:

**Static `loadSeries` Methods:**
- **When to use:** Quick, one-off data loads where you don't need caching or custom configuration
- **Features:**
  - Simple, no instance creation required
  - Uses a default instance with caching **disabled**
  - No dependency injection support
  - No custom cache directory support
- **Example:**
  ```java
  // Quick one-off load - no caching
  BarSeries series = YahooFinanceHttpBarSeriesDataSource.loadSeries("AAPL", 365);
  ```

**Instance `loadSeriesInstance` Methods:**
- **When to use:** When you need caching, custom configurations, dependency injection for testing, or multiple loads with the same configuration
- **Features:**
  - Support for response caching (enabled via constructor)
  - Custom cache directories (caching automatically enabled when directory is specified)
  - Dependency injection for unit testing (mock HttpClientWrapper)
  - Optional `notes` parameter for cache file naming (useful for test isolation)
  - Reuse the same instance for multiple loads with consistent configuration
- **Example:**
  ```java
  // Create instance with caching
  YahooFinanceHttpBarSeriesDataSource loader = new YahooFinanceHttpBarSeriesDataSource(true);
  
  // Multiple loads using the same cached instance
  BarSeries aapl = loader.loadSeriesInstance("AAPL", YahooFinanceInterval.DAY_1, start1, end1);
  BarSeries msft = loader.loadSeriesInstance("MSFT", YahooFinanceInterval.DAY_1, start2, end2);
  
  // Or with custom cache directory (caching automatically enabled)
  YahooFinanceHttpBarSeriesDataSource loader = new YahooFinanceHttpBarSeriesDataSource("/my/cache");
  BarSeries series = loader.loadSeriesInstance("AAPL", YahooFinanceInterval.DAY_1, start, end);
  
  // For unit testing with mock HTTP client
  HttpClientWrapper mockClient = mock(HttpClientWrapper.class);
  YahooFinanceHttpBarSeriesDataSource loader = new YahooFinanceHttpBarSeriesDataSource(mockClient);
  BarSeries series = loader.loadSeriesInstance("AAPL", YahooFinanceInterval.DAY_1, start, end);
  ```

**Recommendation:** Use static methods for quick scripts and one-off loads. Use instance methods when you need caching, are making multiple requests, or need custom configurations.

#### API Limits and Pagination

Yahoo Finance's unofficial API has practical limits:
- **Rate limits:** ~2000 requests/hour per IP (may result in temporary bans if exceeded)
- **Data range limits (approximate):**
  - Intraday (1m-4h): Typically 60-90 days maximum per request
  - Daily (1d): Typically 2-5 years maximum per request
  - Weekly/Monthly (1wk, 1mo): Can request many years per request

The implementation uses conservative limits and automatically paginates large requests:
- **Intraday (1m-4h):** 30 days per chunk
- **Hourly (1h, 4h):** 60 days per chunk
- **Daily (1d):** 1 year per chunk
- **Weekly/Monthly (1wk, 1mo):** 5 years per chunk

Pagination is automatic - you don't need to do anything special. See [Automatic Pagination](#automatic-pagination) for more details.

### Coinbase Data Source

`CoinbaseHttpBarSeriesDataSource` loads historical price data from Coinbase's Advanced Trade API. It supports all Coinbase trading pairs (e.g., BTC-USD, ETH-USD).

#### Features

- **No authentication required** - Uses Coinbase's public market data endpoint
- **Automatic pagination** - Splits requests exceeding 350 candles into multiple API calls
- **Response caching** - Optional disk-based caching for faster subsequent requests (see [Response Caching](#response-caching-http-sources))
- **Multiple intervals** - Supports 1m, 5m, 15m, 30m, 1h, 2h, 4h, 6h, 1d
- **Rate limit handling** - Built-in delays between paginated requests

#### Supported Intervals

The `CoinbaseInterval` enum provides the following intervals:

- `ONE_MINUTE` - 1 minute bars
- `FIVE_MINUTE` - 5 minute bars
- `FIFTEEN_MINUTE` - 15 minute bars
- `THIRTY_MINUTE` - 30 minute bars
- `ONE_HOUR` - 1 hour bars
- `TWO_HOUR` - 2 hour bars
- `FOUR_HOUR` - 4 hour bars
- `SIX_HOUR` - 6 hour bars
- `ONE_DAY` - 1 day bars

#### Basic Usage

**Static Methods (Quick & Simple):**

```java
// Load 1 year of daily data for Bitcoin (using days)
BarSeries series = CoinbaseHttpBarSeriesDataSource.loadSeries("BTC-USD", 365);

// Load 500 bars of hourly data for Ethereum (using bar count)
BarSeries ethSeries = CoinbaseHttpBarSeriesDataSource.loadSeries("ETH-USD", 
    CoinbaseInterval.ONE_HOUR, 500);

// Load data for a specific date range
Instant start = Instant.parse("2023-01-01T00:00:00Z");
Instant end = Instant.parse("2023-12-31T23:59:59Z");
BarSeries btcSeries = CoinbaseHttpBarSeriesDataSource.loadSeries("BTC-USD", 
    CoinbaseInterval.ONE_DAY, start, end);
```

**Instance Methods (With Caching & Customization):**

```java
// Create an instance with caching enabled
CoinbaseHttpBarSeriesDataSource loader = new CoinbaseHttpBarSeriesDataSource(true);
BarSeries series = loader.loadSeriesInstance("BTC-USD", CoinbaseInterval.ONE_DAY, start, end);

// Or with custom cache directory (caching automatically enabled)
CoinbaseHttpBarSeriesDataSource loader = new CoinbaseHttpBarSeriesDataSource("/my/cache/dir");
BarSeries series = loader.loadSeriesInstance("BTC-USD", CoinbaseInterval.ONE_DAY, start, end);
```

#### Using the Interface

```java
// Using the BarSeriesDataSource interface
BarSeriesDataSource coinbase = new CoinbaseHttpBarSeriesDataSource();
BarSeries series = coinbase.loadSeries("BTC-USD", Duration.ofDays(1), start, end);
```

**Note:** See [Static vs Instance Methods](#static-vs-instance-methods) in the Yahoo Finance section for a detailed explanation of when to use static vs instance methods.

#### API Limits and Pagination

Coinbase API has a maximum of 350 candles per request. The implementation automatically paginates large requests, splitting them into chunks of 350 candles. Pagination includes a 100ms delay between requests to avoid rate limiting. See [Automatic Pagination](#automatic-pagination) for more details.

## File-Based Data Sources

File-based data sources load data from local files. They search for files matching the ticker, interval, and date range criteria in the classpath or configured directories.

### CSV Data Source

`CsvFileBarSeriesDataSource` loads OHLCV data from CSV files. It searches for CSV files matching the specified criteria in the classpath.

#### File Format

CSV files should have the following format:
- Header row (skipped)
- Columns: date, open, high, low, close, volume
- Date format: `yyyy-MM-dd` (e.g., "2023-01-01")

#### Filename Patterns

The data source searches for files matching these patterns:
- `{ticker}-{interval}-{startDateTime}_{endDateTime}.csv`
- `{ticker}-*-{startDateTime}_*.csv`
- `{ticker}-*.csv` (then filters by date range)

Where:
- `{ticker}` - Uppercase ticker symbol (e.g., "AAPL", "BTC-USD")
- `{interval}` - ISO 8601 duration string (e.g., "PT1D" for daily, "PT5M" for 5 minutes)
- `{startDateTime}` - Start date/time in format depending on interval:
  - Minutes: `yyyyMMddHHmm`
  - Hours: `yyyyMMddHH`
  - Days: `yyyyMMdd`
- `{endDateTime}` - End date/time in same format

#### Basic Usage

```java
// Load from a specific file
BarSeries series = CsvFileBarSeriesDataSource.loadSeriesFromFile("AAPL-PT1D-20130102_20131231.csv");

// Load using domain-driven interface (searches for matching file)
BarSeriesDataSource csv = new CsvFileBarSeriesDataSource();
Instant start = Instant.parse("2023-01-01T00:00:00Z");
Instant end = Instant.parse("2023-12-31T23:59:59Z");
BarSeries series = csv.loadSeries("AAPL", Duration.ofDays(1), start, end);

// Load directly by filename
BarSeries series = csv.loadSeries("AAPL-PT1D-20130102_20131231.csv");
```

#### Example CSV File

```csv
date,open,high,low,close,volume
2023-01-01,150.00,152.50,149.50,151.25,1000000
2023-01-02,151.25,153.00,150.75,152.00,1200000
2023-01-03,152.00,154.50,151.50,153.75,1100000
```

### JSON Data Source

`JsonFileBarSeriesDataSource` loads OHLCV data from JSON files. It supports multiple exchange formats including Binance and Coinbase formats using an adaptive type adapter.

#### Supported Formats

- **Coinbase format** - Coinbase Advanced Trade API response format
- **Binance format** - Binance API response format

The `AdaptiveBarSeriesTypeAdapter` automatically detects and parses the appropriate format.

#### Filename Patterns

The data source searches for files matching these patterns:
- `{Exchange}-{ticker}-{interval}-{startDateTime}_{endDateTime}.json`
- `{ticker}-{interval}-{startDateTime}_{endDateTime}.json` (without exchange prefix)

Where:
- `{Exchange}` - Exchange prefix: "Coinbase-" or "Binance-"
- `{ticker}` - Uppercase ticker symbol (e.g., "BTC-USD", "ETH-USD")
- `{interval}` - ISO 8601 duration string (e.g., "PT1D", "PT5M")
- `{startDateTime}` - Start date/time in format depending on interval
- `{endDateTime}` - End date/time in same format

#### Basic Usage

```java
// Load from a specific file
BarSeriesDataSource json = new JsonFileBarSeriesDataSource();
BarSeries series = json.loadSeries("Coinbase-BTC-USD-PT1D-20230101_20231231.json");

// Load using domain-driven interface (searches for matching file)
Instant start = Instant.parse("2023-01-01T00:00:00Z");
Instant end = Instant.parse("2023-12-31T23:59:59Z");
BarSeries series = json.loadSeries("BTC-USD", Duration.ofDays(1), start, end);

// Load from InputStream
try (InputStream is = Files.newInputStream(Paths.get("data.json"))) {
    BarSeries series = json.loadSeries(is);
}
```

#### Example JSON File (Coinbase Format)

```json
{
  "candles": [
    {
      "start": "2023-01-01T00:00:00Z",
      "low": "149.50",
      "high": "152.50",
      "open": "150.00",
      "close": "151.25",
      "volume": "1000000"
    },
    {
      "start": "2023-01-02T00:00:00Z",
      "low": "150.75",
      "high": "153.00",
      "open": "151.25",
      "close": "152.00",
      "volume": "1200000"
    }
  ]
}
```

### Bitstamp Trades CSV Data Source

`BitStampCsvTradesFileBarSeriesDataSource` loads trade-level data from Bitstamp CSV files and aggregates them into OHLCV bars. This is different from other data sources as it reads trade data (timestamp, price, volume) and aggregates it into bars.

#### File Format

CSV files should have the following format:
- Header row (skipped)
- Columns: timestamp (Unix seconds), price, volume
- Trades are aggregated into 5-minute bars by default

#### Filename Patterns

The data source searches for files matching these patterns:
- `Bitstamp-{ticker}-{interval}-{startDateTime}_{endDateTime}.csv`
- `Bitstamp-{ticker}-*-{startDateTime}_*.csv`
- `Bitstamp-{ticker}-*.csv` (then filters by date range)

#### Basic Usage

```java
// Load from a specific file
BarSeries series = BitStampCsvTradesFileBarSeriesDataSource.loadBitstampSeries(
    "Bitstamp-BTC-USD-PT5M-20131125_20131201.csv");

// Load using domain-driven interface (searches for matching file)
BarSeriesDataSource bitstamp = new BitStampCsvTradesFileBarSeriesDataSource();
Instant start = Instant.parse("2023-01-01T00:00:00Z");
Instant end = Instant.parse("2023-12-31T23:59:59Z");
BarSeries series = bitstamp.loadSeries("BTC-USD", Duration.ofMinutes(5), start, end);

// Load directly by filename
BarSeries series = bitstamp.loadSeries("Bitstamp-BTC-USD-PT5M-20131125_20131201.csv");
```

#### Example CSV File

```csv
timestamp,price,volume
1385337600,150.00,1.5
1385337610,150.25,2.0
1385337620,150.50,1.0
1385337630,150.75,3.5
```

**Note:** The trades are aggregated into bars based on the requested interval. If the file contains 5-minute bars but you request 1-hour bars, the data source will attempt to filter but may not re-aggregate correctly. It's recommended to use files that match the requested interval.

## Advanced Features

### Response Caching (HTTP Sources)

HTTP-based data sources support optional response caching to disk. When enabled:

1. **Cache Location:** Default is `temp/responses`, but can be customized
2. **Cache Validity:**
   - Historical data (end date in the past): Cached indefinitely
   - Current data: Cache expires after the interval duration (e.g., daily data cached for the day)
3. **Cache File Naming:** `{sourceName}-{ticker}-{interval}-{start}-{end}.json`
4. **Cache Lookup:** Before making an API request, the data source checks for a valid cache file

#### Enabling Caching

```java
// Yahoo Finance with caching (using default cache directory)
YahooFinanceHttpBarSeriesDataSource yahoo = new YahooFinanceHttpBarSeriesDataSource(true);

// Coinbase with caching and custom directory (caching automatically enabled when directory is specified)
CoinbaseHttpBarSeriesDataSource coinbase = new CoinbaseHttpBarSeriesDataSource("/my/cache/dir");
```

#### Cache Management

All HTTP-based data sources provide cache management methods:

```java
// Delete all cache files for this data source
int deleted = loader.deleteAllCacheFiles();

// Delete cache files older than specified duration
int deleted = loader.deleteCacheFilesOlderThan(Duration.ofDays(7));

// Delete stale cache files (convenience method for 30 days)
int deleted = loader.deleteStaleCacheFiles();

// Delete stale cache files with custom age
int deleted = loader.deleteStaleCacheFiles(Duration.ofDays(14));
```

**Example:**
```java
// With caching enabled using default directory
YahooFinanceHttpBarSeriesDataSource loader = new YahooFinanceHttpBarSeriesDataSource(true);
int deleted = loader.deleteStaleCacheFiles(); // Deletes files older than 30 days

// With custom cache directory (caching automatically enabled)
CoinbaseHttpBarSeriesDataSource loader = new CoinbaseHttpBarSeriesDataSource("/my/cache/dir");
int deleted = loader.deleteStaleCacheFiles(); // Deletes files older than 30 days
```

### Automatic Pagination

HTTP-based data sources automatically handle pagination for large date ranges. The implementation:

1. Calculates if pagination is needed based on API limits
2. Splits the date range into chunks
3. Fetches each chunk sequentially
4. Merges results chronologically
5. Removes duplicates

Pagination is transparent - you don't need to do anything special:

```java
// This will automatically paginate if needed
Instant start = Instant.parse("2020-01-01T00:00:00Z");
Instant end = Instant.parse("2024-12-31T23:59:59Z");
BarSeries series = YahooFinanceHttpBarSeriesDataSource.loadSeries("AAPL", 
    YahooFinanceInterval.DAY_1, start, end);
```

**Provider-Specific Details:**
- **Yahoo Finance:** Uses conservative limits (30 days for intraday, 1 year for daily, etc.)
- **Coinbase:** Splits requests exceeding 350 candles into multiple API calls with 100ms delays between requests

### Unit Testing

All HTTP-based data sources support dependency injection for unit testing. You can inject a mock `HttpClientWrapper` to test your code without making actual API calls:

```java
// Create a mock HttpClientWrapper
HttpClientWrapper mockHttpClient = mock(HttpClientWrapper.class);

// Inject into data source (caching disabled by default)
YahooFinanceHttpBarSeriesDataSource loader = new YahooFinanceHttpBarSeriesDataSource(mockHttpClient);
// or
CoinbaseHttpBarSeriesDataSource loader = new CoinbaseHttpBarSeriesDataSource(mockHttpClient);

// Configure mock behavior
when(mockHttpClient.send(any(), any())).thenReturn(mockResponse);

// Test your code using instance methods (static methods won't use your mock)
BarSeries series = loader.loadSeriesInstance("AAPL", YahooFinanceInterval.DAY_1, start, end);
```

**Important:** Static `loadSeries` methods use a default instance and won't use your injected mock. Always use instance `loadSeriesInstance` methods when testing with mocks.

This approach allows you to:
- Test error handling scenarios
- Verify request parameters
- Simulate API responses
- Avoid rate limits during testing

### Error Handling

All data sources return `null` if loading fails. Always check for null before using the result:

```java
BarSeries series = yahoo.loadSeries("AAPL", Duration.ofDays(1), start, end);
if (series == null) {
    // Handle error - check logs for details
    LOG.error("Failed to load data for AAPL");
    return;
}
// Use series...
```

**Common failure reasons:**
- Network errors (HTTP sources)
- File not found (file sources)
- Invalid data format
- API rate limits exceeded
- Invalid parameters

Check the logs for detailed error messages when loading fails.

## Best Practices

1. **Use the Interface:** Prefer using `BarSeriesDataSource` interface to make your code data-source agnostic
2. **Enable Caching:** For HTTP sources, enable caching to reduce API calls and improve performance
3. **Handle Null:** Always check for null return values
4. **Use Appropriate Intervals:** Match the interval to your analysis needs (e.g., daily for long-term, hourly for short-term)
5. **Respect Rate Limits:** Be mindful of API rate limits, especially for Yahoo Finance
6. **Cache Management:** Periodically clean up old cache files to save disk space
7. **Error Logging:** Check logs for detailed error messages when loading fails

## Summary

The ta4j data sources provide a unified, domain-driven API for loading historical market data from various sources:

- **HTTP Sources:** Yahoo Finance, Coinbase (with caching and pagination)
- **File Sources:** CSV, JSON (with format detection), Bitstamp trades
- **Common Features:** Domain-driven interface, automatic pagination, response caching, unit testing support

All data sources implement `BarSeriesDataSource`, making it easy to switch between sources or support multiple sources in your application.
