# Projekt Roadmap

The hard truth we have to accept is that we can't be everything to everyone. 

Indicators and analysis metrics are the only two areas that can be considered standardized as they have well-defined, widely accepted formulae (i.e. everyone calculates RSI or Sharpe Ratio the same way). Differences in usage are accounted for by configurable 
parameters. For more obscure and exotic indicators where there may not be widespread consensus on calculation we simply need to adopt a variant as convention on a case by case basis. 
In every other area - trading, back-testing, reporting, and even business object models there can and are wildly different approaches, with none objectively better or worse than the others, only better or worse for a particular user preference, strategy, and client application.
If we accept this premise then it logically follows that these areas have very little opportunity for standardization, nor would doing so be desirable. As previously asserted, Ta4j cannot be everything for everyone so attempting to please everyone will inevitably 
lead to constant disagreements, bickering, and ultimately no one will be happy.

Ta4j's forward vision can be summed up as 2 principles:

1. Continuous expansion of our Indicator and Analysis libraries. We should strive to provide our userbase the most comprehensive and well-organized technical analysis toolset available.
2. Focus on core interfaces and push specific implementations to the client app

Instead of expanding Ta4j's scope with detailed and opinionated back-testing, trading, model, etc implementations, we need to do the opposite and instead focus on generalizing and genericizing our core interfaces. 
In other words, we need to focus on making our core interfaces (BarSeries, Bar, etc) flexible and interoperable, provide a basic no-frills "base" implementation (BaseBarSeries, BaseBar, etc), and rather than an endless cycle of push-and-pull PRs tweaking how the implementations behave, we simply provide an interface ecosystem that provides interoperability, but leaves as much of the implementation details to the user as possible.

Going forward our mental framework for change proposals needs to shift from, "How can we modify base class ABC so that it does X?" to "How can we modify interface EFG such that it can support an implementation that does X?". It can be a subtle distinction but will have a dramatic impact on Ta4j's development path forward. No doubt there will be challenging aspects that require creative thinking and perhaps re-architecture but hey, that's half the fun. Most importantly it will result in a laser focused product with clear value proposition and a sustainable path forward.

The following is a draft wish-list of features and is laid out as three independent/concurrent tracks of development. Most of these are carryovers from before the new, simplified project vision so they may ultimately not fit. Still, I leave them here to serve as a springboard for 
discussion. 

Unless stated otherwise, line items within each track are order dependent, sequencing from top to bottom. At the moment there are only high level descriptions, however as the approaches are finalized the tracks will be populated with links to Issues containing the details and/or Pull Requests containing the active development.

Thoughts, suggestions, contributions, etc toward any of these items would be greatly appreciated.


| Indicators & Analysis                                      
|----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|**Expand indicator and criteria library -** Additional (unique) indicators and analysis criteria are always welcome. We should strive to be as comprehensive as possible as this is a core value proposition of the Ta4j library.                                                                     |                                            
<br />

| Tech Debt
|----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|**Resolve inconsistent "return" representation -** Currently a 10% gain can be represented as both 0.1 and 1.1 depending on the addBase param in ReturnCriterion. This leads to ambiguity and inconsistency when comparing criteria, especially since ReturnCriterion can be used as a building block within other criteria. The definition of "return" should be standardized across the library to a percentage represntation non-inclusive of the base.  A separate, base-inclusive criteria should be added for use cases where such representation is desirable.                                                                                                   |
|**Indicator stability and propogation -** Converge on a universal and consistent API for "unstable" indicator values.                          |
|**Performance improvements -** Profile and remove unnnecessary features, precision, etc. Pursue alternative concurrency and caching approaches |
<br />


| New Features
|----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|**TradingRecord QoL -** Enhance TradingRecord to allow multiple, open positions. Model funds/principal.                                        |
|**Order book models & analysis -** New model classes representing order books along with tools to analyze them.                                |
|**Options models & analysis -** New model classes representing options contracts along with tools to analyze them.                             |
|**Futures models & analysis -** New model classes representing futures contracts along with tools to analyze them.                             |
|**Strategy (& Rule) serialization API -** Add ability to serialize/deserialize strategies so they can be saved and restored.                   |
<br />