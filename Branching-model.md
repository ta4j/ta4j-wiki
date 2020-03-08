# Branching model
Enhancements, new features and fixes should be pushed to a [fork](https://help.github.com/articles/fork-a-repo/) of the develop branch. Once completed they will be merged with the develop branch during a [pull request](https://help.github.com/articles/about-pull-requests/). Bevore making a release the develop branch (containig all the updates) will be merged into the master branch and the final release version will get a corresponding tag.

* **Only the develop branch can be modified by pull requests from other forked develop branches**
* **Only the content of the master branch is going to become a release.**
* **There is no release branch**


![branch model](http://nvie.com/img/git-model@2x.png)


## Snapshots
A SNAPSHOT is the develop version of the **next** release version. For instance a 0.14-Snapshot is the current build that should become the next 0.14 release. You can use the current SNAPSHOT version by adding the following dependency to your `pom.xml` file:
```
<dependency>
  <groupId>org.ta4j</groupId>
  <artifactId>ta4j-core</artifactId>
  <version>0.14-SNAPSHOT</version>
</dependency>
```

The SNAPSHOT version contains all fixes, enhancements and new features that have been added to the develop build so far and that will be part of the next release.

Please note that a SNAPSHOT version can be changed in any way at any time.

See also:
* http://nvie.com/posts/a-successful-git-branching-model/
* https://help.github.com/articles/about-pull-requests/
* https://help.github.com/articles/fork-a-repo/