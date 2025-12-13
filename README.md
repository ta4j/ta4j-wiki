# Ta4j — Technical Analysis for Java

<img src="https://github.com/ta4j/ta4j-wiki/blob/master/img/ta4j_main_chart.png?raw=true" alt="Example chart built with ta4j" />

Welcome to the ta4j wiki, the living handbook for building, evaluating, and deploying TA-driven trading systems on the JVM.  
The wiki now follows a task-focused layout:

- **Start Here** – [Getting Started](Getting-started.md), [FAQ](FAQ.md), and [Release Notes](Release-notes.md) bring new users up to speed quickly.
- **Core Concepts** – Deep dives into [Bar Series & Bars](Bar-series-and-bars.md), [Num](Num.md), and [Technical Indicators](Technical-indicators.md) explain how ta4j models data and calculations.
- **Build Strategies** – Learn how to [compose rules and strategies](Trading-strategies.md), [backtest them](Backtesting.md), and study [usage examples](Usage-examples.md).
- **Deploy & Operate** – Guidance for [live trading setups](Live-trading.md), logging, and bot automation.
- **Project & Community** – [How to contribute](How-to-contribute.md), [Branching model](Branching-model.md), [Roadmap & Tasks](Roadmap-and-Tasks.md), and [Found a bug?](Found-a-bug.md).

### What's new for 0.19

Release 0.19 focuses on production-ready workflows:

- **Accelerated backtesting** with the new `BacktestExecutor`, runtime reports, and streaming top-K selection.
- **Strategy serialization & presets** via `StrategySerialization` and compact `NamedStrategy` formats for sharing parameterized strategies.
- **Expanded indicator set** including Renko brick helpers, MACDV, Net Momentum, plus vote-based rules for ensemble strategies.
- **Deeper analytics** like drawdown Monte Carlo simulation, commission impact, and capital utilization metrics.

Browse the [Release Notes](Release-notes.md) for the full annotated list.

### Need help or want to collaborate?

- Join the [community Discord](https://discord.gg/HX9MbWZ) to discuss trading ideas, ask questions, or showcase projects.
- Explore the [ta4j-examples](https://github.com/ta4j/ta4j/tree/master/ta4j-examples) module for runnable samples referenced throughout the wiki.
- Open issues or PRs in the [main ta4j repository](https://github.com/ta4j/ta4j) when you spot bugs or have improvements in mind.

