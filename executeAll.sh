#!/bin/bash
set -e
tar -xf demo-project.tar.xz
git clone https://github.com/DaGeRe/peass.git && \
	cd peass && \
	DEMO_HOME=$(pwd)/../demo-project && \
	./mvnw clean install -DskipTests=true -V

# If minor updates to the project occur, the version name may change
VERSION="b02c92af73e3297be617f4c973a7a63fb603565b"
PREVIOUS_VERSION="e80d8a1bf747d1f70dc52260616b36cac9e44561"

DEMO_PROJECT_PEASS=../demo-project_peass
EXECUTE_FILE=results/execute_demo-project.json

# It is assumed that $DEMO_HOME is set correctly and PeASS has been built!
echo ":::::::::::::::::::::SELECT:::::::::::::::::::::::::::::::::::::::::::"
./peass select -folder $DEMO_HOME

if [ ! -f $EXECUTE_FILE ]
then
	echo "Main Logs"
	ls $DEMO_PROJECT_PEASS
	ls $DEMO_PROJECT_PEASS/logs/

	echo "projektTemp"
	ls ../demo-project_peass/projectTemp/

	echo "projectTemp/tree_"$VERSION"_peass:"
    ls $DEMO_PROJECT_PEASS/projectTemp/tree_"$VERSION"_peass/

    echo "projectTemp/tree_"$PREVIOUS_VERSION"_peass:"
    ls $DEMO_PROJECT_PEASS/projectTemp/tree_"$PREVIOUS_VERSION"_peass/

	echo "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
    echo "cat $DEMO_PROJECT_PEASS/projectTemp/tree_"$VERSION"_peass/logs/$VERSION/*/*"
    echo "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
    cat $DEMO_PROJECT_PEASS/projectTemp/tree_"$VERSION"_peass/logs/$VERSION/*/*

    echo "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
    echo "cat $DEMO_PROJECT_PEASS/projectTemp/tree_"$PREVIOUS_VERSION"_peass/logs/$PREVIOUS_VERSION/*/*"
    echo "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
    cat $DEMO_PROJECT_PEASS/projectTemp/tree_"$PREVIOUS_VERSION"_peass/logs/$PREVIOUS_VERSION/*/*
	exit 1
fi

echo ":::::::::::::::::::::MEASURE::::::::::::::::::::::::::::::::::::::::::"
./peass measure -executionfile $EXECUTE_FILE -folder $DEMO_HOME -iterations 1 -warmup 0 -repetitions 1 -vms 2

echo "::::::::::::::::::::GETCHANGES::::::::::::::::::::::::::::::::::::::::"
./peass getchanges -data $DEMO_PROJECT_PEASS -dependencyfile results/deps_demo-project.json

#Check, if changes_demo-project.json contains the correct commit-SHA
test_sha=$(grep -A1 'versionChanges" : {' results/changes_demo-project.json | grep -v '"versionChanges' | grep -Po '"\K.*(?=")')
if [ "$VERSION" != "$test_sha" ]
then
    echo "commit-SHA is not equal to the SHA in changes_demo-project.json!"
    cat results/statistics/demo-project.json
    exit 1
else
    echo "changes_demo-project.json contains the correct commit-SHA."
fi

echo "::::::::::::::::::::SEARCHCAUSE:::::::::::::::::::::::::::::::::::::::"
./peass searchcause -vms 5 -iterations 1 -warmup 0 -version $VERSION -test de.test.CalleeTest\#onlyCallMethod1 -folder $DEMO_HOME -executionfile $EXECUTE_FILE

echo "::::::::::::::::::::VISUALIZERCA::::::::::::::::::::::::::::::::::::::"
./peass visualizerca -data $DEMO_PROJECT_PEASS -propertyFolder results/properties_demo-project/

#Check, if a slowdown is detected for innerMethod
state=$(grep '"call" : "de.test.Callee#innerMethod",\|state' results/$VERSION/de.test.CalleeTest_onlyCallMethod1.js | grep "innerMethod" -A 1 | grep '"state" : "SLOWER",' | grep -o 'SLOWER')
if [ "$state" != "SLOWER" ]
then
    echo "State for de.test.Callee#innerMethod in de.test.CalleeTest#onlyCallMethod1.html has not the expected value SLOWER, but was $state!"
    cat results/$VERSION/de.test.CalleeTest_onlyCallMethod1.js
    exit 1
else
    echo "Slowdown is detected for innerMethod."
fi

sourceMethodLine=$(grep "de.test.Callee.method1_" results/$VERSION/de.test.CalleeTest_onlyCallMethod1.js -A 3 | head -n 3 | grep innerMethod)
if [[ "$sourceMethodLine" != *"innerMethod();" ]]
then
    echo "Line could not be detected - source reading probably failed."
    echo "Line: "
    echo $sourceMethodLine
    exit 1
fi
