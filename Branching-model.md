# Branching model
Enhancements, new features and fixes should be pushed to a [fork](https://help.github.com/articles/fork-a-repo/) of the master branch. Once completed they will be merged with the master branch during a [pull request](https://help.github.com/articles/about-pull-requests/). GitHub actions are configured to run the tests, validate the licence header and source code format. After the PR has been merged a new SNAPSHOT will be deployed.

This development process is similar to  [github flow](https://docs.github.com/en/get-started/quickstart/github-flow)

* **Only the content of the master branch is going to become a release.**
* **There is no release branch nor a mandatory develop branch**



## Snapshots
A SNAPSHOT is the latest version of the **next** release. For instance a 0.22.0-SNAPSHOT is the current build that should become the next 0.22.0 release. You can use the current SNAPSHOT version by adding the following dependency to your `pom.xml` file:
```
<dependency>
  <groupId>org.ta4j</groupId>
  <artifactId>ta4j-core</artifactId>
  <version>0.22.0-SNAPSHOT</version>
</dependency>
```

The SNAPSHOT version contains all fixes, enhancements and new features that have been added to the master build so far and that will be part of the next release.

Please note that a SNAPSHOT version can be changed in any way at any time.

See also:
* http://nvie.com/posts/a-successful-git-branching-model/
* https://help.github.com/articles/about-pull-requests/
* https://help.github.com/articles/fork-a-repo/