
# Maven Notes

### Check license headers

```bash
mvn license:check
```

### Check source code format
```bash
mvn formatter:validate
```

### Format source code
```bash
mvn formatter:format
```

### Format license headers

```bash
mvn license:format
```

### Deploy a snapshot

```bash
mvn clean deploy
```

### Deploy a release

1. Merge `develop` into `master` branch
2. Adapt and Update CHANGELOG.md, README.md
3. Commit
4. make sure you have GPG and a personal key (otherwise the maven-gpg-plugin fails with error 127)
5. make sure you have added an personal ssh-key to your GitHub account (otherwise the maven-release-plugin will fail after prepare-commit)  
6. Release:
    ```
    (check existing tags)
    mvn clean test
    mvn release:clean release:prepare -Darguments=-Dgpg.passphrase=thephrase  -Psonatype-oss-release

    mvn release:perform -Psonatype-oss-release
    ```
7. Update Wiki with CHANGELOG.md and new Javadoc
8. Update CHANGELOG.md and README.md on develop branch

### Internal notes

  * http://central.sonatype.org/pages/ossrh-guide.html
  * http://central.sonatype.org/pages/releasing-the-deployment.html
  * http://datumedge.blogspot.de/2012/05/publishing-from-github-to-maven-central.html
