# How to Contribute

## What is a contribution?

In our terms a contribution is already to share a good analysed bug report [Found a bug?](Found-a-bug.html)
If you want to go deeper and you want to contribute test cases, e.g. for a quality contribution (identify a bug) or to help us to keep the lib clean and stable.
Or you have even a nice idea, which you would like to contribute as code?
You are always welcome. We suggest you before you contribute a bigger work to get prior permission, since we want to verify first if the contribution will bring the lib forward. We will give quickly a feedback if we will accept the contribution.

## How to contribute?
In the most cases (e.g. bug fixes and little enhancements) you can create a pull request to the `master` branch. For bigger improvements please open an issue to discuss your plans.
* _Note_: **Pull requests with respect to items of the [Roadmap](Roadmap-and-Tasks.md) are very welcome!**


Take a look at the [branching model](Branching-model.md) to get an overview. You can fork and clone the repository and set up the master branch as follows:
```
// fork repositroy on Git UI from https://github.com/ta4j/ta4j.git to https://github.com/yourAccount/ta4j.git
git clone https://github.com/yourAccount/ta4j.git
cd ta4j
```

You should always create a new branch (forked from ``master`` branch) for enhancements or bug fixes:
```
git checkout -b feature/name-of-your-feature-branch
git push --set-upstream origin feature/*
```

* _Note_: **If you have finished your work, please make sure to maintain the _CHANGELOG.md_ file if you have added, fixed or enhanced something.**
* _Note_: **Before submitting a pull request, please make sure you run the complete test suite on your branch using `mvn test`. There are github actions checking for code format and licence header as well:**

```
// implement changes on your branch
// format code, add license header and run unit tests with maven:
mvn -B clean license:format formatter:format test
git add myNewFiles.java CHANGELOG.md
git commit
git push
```
The last step would be to do a pull request **from your branch to the `master` branch of the ta4j repository**. If you want to do a pull-request, the best way is to do is via Git UI:
* [Introduction-create a pull request](https://www.digitalocean.com/community/tutorials/how-to-create-a-pull-request-on-github). Your pull-request will be reviewed and changes could be requested. Please maintain your PR if necessary.

## Coding rules and conventions

### General
(in progress...)<br>
First things first: Feel free to write awesome code! Do not hesitate to open an issue or a pull request just because you fear making a mistake. Others can review your code, give you tips and can correct you.
* Be aware that your code is easily legible and transparent.
* Stay in scope of your pull request. Do not make changes all over the project in one pull request. For example if you want to add a new indicator add but you also found bugs or little enhancements on TimeSeries and TradingRecord **fix them in a new pull request**.

## Hints
* use `int startIndex = timeSeries.getBeginIndex()` instead of `int startIndex = 0` to get the first valid index of a TimeSeries.
* ***Note the difference between `Decimal.min(other)` and` Decimal.minus(other)`***
* It is not possible to store static references to ``Num`` implementations because they will be determined at runtime. If necessary store primitives and use the `numOf(Number n)` or the `numFunction` of series in the constructor. If you are using ``DoubleNum::valueOf`` or ``BigDecimalNum::valueOf`` you most probably do something wrong.
* **Use primitive as inidcator parameters.*** For example a timeFrame parameter should be an ``int`` and a percentage value parameter should be ``double`` (avoid ``Num``). You can **convert a ``Number`` into ``Num`` using the ``numOf`` function**. This prevents that the user has to convert primitive input values to ``Num`` implementations manually.

## Indicators
If you want to add a new indicator to this repository, please open an issue first to discuss your plans.

* Every indicator needs a test class in the corresponding package:
    * src -> main -> java -> org -> ta4j -> core -> indicators -> NewIndicator.java
    * src -> test -> java -> org -> ta4j -> core -> indicators -> NewIndicatorTest.java

