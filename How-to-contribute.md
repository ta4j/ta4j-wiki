# How to Contribute

## What is a contribution?

In our terms a contribution is already to share a good analysed bug report [Found a bug?](Found-a-bug.md)
If you want to go deeper and you want to contribute test cases, e.g. for a quality contribution (identify a bug) or to help us to keep the lib clean and stable.
Or you have even a nice idea, which you would like to contribute as code?
You are always welcome. We suggest you before you contribute a bigger work to get prior permission, since we want to verify first if the contribution will bring the lib forward. We will give quickly a feedback if we will accept the contribution.

## What kind of contributions are we looking for?
While just about all contributions are welcome, some will receive higher priority than others:
1. Contributions that directly advance the [Roadmap](Roadmap-and-Tasks.md) will receive the highest priority.
2. Cleanly additive Indicators, Criterion, and Rules (i.e. can be incorporated without any side effects, overlap, or non-trivial impacts to existing code) will almost always be accepted.
3. Additional test cases and/or documentation for an existing feature. Follow the prevailing conventions and it's as good as merged.
4. Fixes to identified bugs - localized fix? 100% in. Spans multiple classes, abstraction layers, etc? Let's talk it through first.



5. As a library the reliability and predictablity of our core APIs is of paramount importance. No one wants to spend hours - perhaps days - refactoring their code just because they updated a dependency. If we are going to force an unexpected refactor cycle on people, it had better be for a damn good reason. To this end, all public API breaking changes (including package re-orgs, renames, method signature changes, etc) must pass a (very) high bar for value delivered. Unsolicited PRs of this nature will also have the lowest priority.
6. Most "code cleanup" - PRs that contain only variable renames, formatting differences, or other deck chair re-arranging changes will more than likely be rejected. 


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

* _Note_: If you have finished your work, please make sure to maintain the _CHANGELOG.md_ file if you have added, fixed or enhanced something.
* _Note_: Before submitting a pull request, please make sure you run the complete test suite on your branch using `mvn test`. There are github actions checking for code format and licence header as well.

**If you miss this step your changes will fail the CI build!**

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
First things first: Feel free to get involved! Do not hesitate to raise an issue because if you are having problems with an indicator (for example) it's very likely others are too. If there's a bug in some formula calculation we want to resolve it ASAP however We can't fix what we aren't aware of. 
Pull requests are always, always welcome. Don't worry if your code isn't "perfect", or even finished. Personally I'm a big fan of opening PRs very early on (as drafts) with the understanding that they are works-in-progress and that collaboration is welcome!

Four main rules to keep in mind:
1. Please prioritize clear & legible code over "clever" code.
2. Unit test code should be treated as first-class citizens rather than an afterthought to production code. Having a comprehensive suite of unit tests is the defining difference maker between a codebase where anyone can contribute (successfully) and a codebase where every change is followed by a vicious cycle of regressions. I cannot emphasize this enough.
3. Stay in scope of your pull request. Do not make changes all over the project in one pull request. For example if you want to add a new indicator add but you also found bugs or little enhancements on BarSeries and TradingRecord fix them in a new pull request.
4. Any breaking changes to public APIs must include an appropriate deprecation shim to preserve binary/source compatibility. For example if you move a class to another package, create a deprecation shim class in the original package. If you change a public method's signature, keep the original method signature available as a `@Deprecated` overload. The javadoc for all new public classes and methods should be annotated with a `@since <version>`

## Hints
* use `int startIndex = series.getBeginIndex()` instead of `int startIndex = 0` to get the first valid index of a `BarSeries`.
* ***Note the difference between `Decimal.min(other)` and` Decimal.minus(other)`***
* Use `series.numFactory()` to create values matching a series' numeric type. Do not store static references to `Num` implementations.
* **Use primitives as indicator parameters.** For example a timeFrame parameter should be an `int` and a percentage value parameter should be `double` (avoid `Num`). You can convert a `Number` into `Num` using `series.numFactory().numOf(...)`. This prevents that the user has to convert primitive input values to `Num` implementations manually.

## Indicators
If you want to add a new indicator to this repository, please open an issue first to discuss your plans.

* Every indicator needs a test class in the corresponding package:
    * src -> main -> java -> org -> ta4j -> core -> indicators -> NewIndicator.java
    * src -> test -> java -> org -> ta4j -> core -> indicators -> NewIndicatorTest.java

