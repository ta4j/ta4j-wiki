# Maven Notes

### Check license headers

```bash
mvn license:check
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

```bash
(check existing tags)
mvn clean
mvn release:clean release:prepare -Darguments=-Dgpg.passphrase=thephrase  -Psonatype-oss-release

mvn release:perform -Psonatype-oss-release
```

### Internal notes

  * http://central.sonatype.org/pages/ossrh-guide.html
  * http://central.sonatype.org/pages/releasing-the-deployment.html
  * http://datumedge.blogspot.de/2012/05/publishing-from-github-to-maven-central.html