#!/bin/bash
set -e
tar -xvf demo-project.tar.xz
git clone https://github.com/DaGeRe/peass.git && \
	cd peass && \
	DEMO_HOME=$(pwd)/../demo-project && \
	mvn clean install -DskipTests=true

# It is assumed that $PEASS_HOME is set correctly and PeASS has been built!
echo ":::::::::::::::::::::SELECT:::::::::::::::::::::::::::::::::::::::::::"
./peass select -folder $DEMO_HOME

echo ":::::::::::::::::::::MEASURE::::::::::::::::::::::::::::::::::::::::::"
./peass measure -executionfile results/execute_demo-project.json -folder $DEMO_HOME -iterations 1 -warmup 0 -repetitions 1 -vms 2

echo "::::::::::::::::::::GETCHANGES::::::::::::::::::::::::::::::::::::::::"
./peass getchanges -data ../demo-project_peass/ -dependencyfile results/deps_demo-project.json

./peass searchcause -vms 2 -iterations 1 -warmup 0 -version 9caed514e0759dbfa4ef29acca78787e34d99975 -test de.test.CalleeTest\#onlyCallMethod1 -folder $DEMO_HOME -executionfile results/execute_demo-project.json 

./peass visualizerca -data $DEMO_HOME -propertyFolder results/properties_demo-project/