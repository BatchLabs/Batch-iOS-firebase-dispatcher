all: framework

PROJECT=BatchFirebaseDispatcher.xcodeproj
SIMULATOR='platform=iOS Simulator,name=iPhone 11'
DERIVED_DATA=$(CURDIR)/DerivedData
SONAR_HOME=$(CURDIR)/.sonar
SONAR_WORKDIR=$(CURDIR)/.scannerwork/
SONAR_URL=https://sonarcloud.io

clean:
	rm -rf $(DERIVED_DATA) $(SONAR_WORKDIR)
	set -o pipefail && xcodebuild clean -project $(PROJECT) -scheme BatchFirebaseDispatcher | xcpretty

framework: clean
	set -o pipefail && xcodebuild build -project $(PROJECT) -scheme BatchFirebaseDispatcher -destination generic/platform=iOS | xcpretty

test: clean
	set -o pipefail && xcodebuild test -project $(PROJECT) -scheme BatchFirebaseDispatcher -destination $(SIMULATOR) | xcpretty

test-sonar: clean
	# Run tests and create Xcode coverage files
	mkdir -p $(DERIVED_DATA)
	$(SONAR_HOME)/build-wrapper-macosx-x86 --out-dir $(DERIVED_DATA)/compilation-database xcodebuild test -project $(PROJECT) -scheme BatchFirebaseDispatcher -destination $(SIMULATOR) -enableCodeCoverage YES -derivedDataPath $(DERIVED_DATA)

	# Convert xresult into SonarCloud format
	bash $(SONAR_HOME)/xccov-to-sonarqube-generic.sh $(DERIVED_DATA)/Logs/Test/*.xcresult/ > $(DERIVED_DATA)/sonarqube-generic-coverage.xml

	# Upload result to SonarCloud
	java -Djava.awt.headless=true \
		-Dproject.home=$(CURDIR) \
		-Dsonar.projectBaseDir=$(CURDIR) \
		-Dsonar.host.url=$(SONAR_URL) \
		-classpath $(CURDIR)/.sonar/sonar-scanner-cli-4.2.0.1873.jar \
		org.sonarsource.scanner.cli.Main
		
remove-package:
	# Xcode 13.3 break Package.resolved format, github action workaround : removing it
	rm -rf BatchFirebaseDispatcher.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved

carthage:
	carthage bootstrap --platform ios --use-xcframeworks

ci: carthage test

.PHONY: carthage test
