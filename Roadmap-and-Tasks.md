# Projekt Roadmap
The following table contains scheduled features, enhancements and ideas for the Ta4j project. Pull Requests regarding one of this topics are very welcome :)
If you have any further ideas feel free to contribute!

| Description                                       | 
|---------------------------------------------------|
|**Resolve inconsistent "return" representation -** Currently a 10% gain can be represented as both 0.1 and 1.1 depending on the addBase param in ReturnCriterion. This leads to ambiguity and inconsistency when comparing criteria, especially since ReturnCriterion can be used as a building block within other criteria. The definition of "return" should be standardized across the library to a percentage represntation non-inclusive of the base.  A separate, base-inclusive criteria should be added for use cases where such representation is desirable.|
|**Indicator stability and propogation -** Converge on a universal and consistent API for "unstable" indicator values.|
|**Expand indicator and criteria library -** Additional (unique) indicators and analysis criteria are always welcome. We should strive to be as comprehensive as possible as this is a core value proposition of the Ta4j library.|
|**Back-testing QoL -** Enhance TradingRecord to allow multiple, open positions. Model funds/principal.|
|**Performance improvements -** Profile and remove unnnecessary features, precision, etc. Pursue alternative concurrency and caching approaches |
|**Order book model classes & analysis -** New model classes representing order books along with tools to analyze them.|
|**Options model classes & analysis -** New model classes representing options contracts along with tools to analyze them.|
|**Futures model classes & analysis -** New model classes representing futures contracts along with tools to analyze them.|
|**Strategy (& Rule) serialization API -** Add ability to serialize/deserialize strategies so they can be saved and restored.|
