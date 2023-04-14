
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

### Test deploying a snapshot

Replace the `<snapshotRepository>` with a local file path like:

```xml
	<distributionManagement>
		<snapshotRepository>
			<id>local</id>
			<name>local</name>
			<url>file:../local_repo/deploy</url>
		</snapshotRepository>
		<repository>
			<id>sonatype-nexus-staging</id>
			<name>Sonatype Nexus release repository</name>
			<url>https://oss.sonatype.org/service/local/staging/deploy/maven2/</url>
		</repository>
	</distributionManagement>
```
and run: `mvn clean deploy`

### Deploy a snapshot to Sonatype Nexus snapshot repository

```bash
mvn clean deploy
```

### Deploy a release

1. Adapt and Update CHANGELOG.md, README.md
2. Commit
3. make sure you have GPG and a personal key (otherwise the maven-gpg-plugin fails with error 127)
4. make sure you have added an personal ssh-key to your GitHub account (otherwise the maven-release-plugin will fail after prepare-commit)  
5. Release:
    ```
    (check existing tags)
    mvn clean test
    mvn release:clean release:prepare -Darguments=-Dgpg.passphrase=thephrase  -Psonatype-oss-release

    mvn release:perform -Psonatype-oss-release
    ```
6. Update Wiki with CHANGELOG.md and new Javadoc
7. Update CHANGELOG.md and README.md on develop branch

### Internal notes

  * http://central.sonatype.org/pages/ossrh-guide.html
  * http://central.sonatype.org/pages/releasing-the-deployment.html
  * http://datumedge.blogspot.de/2012/05/publishing-from-github-to-maven-central.html
