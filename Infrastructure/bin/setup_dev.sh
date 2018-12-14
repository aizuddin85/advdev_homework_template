#!/bin/bash
# Setup Development Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Parks Development Environment in project ${GUID}-parks-dev"

# Code to set up the parks development project.

# To be Implemented by Student
echo "Ensure we are in the correct namespace: ${GUID}-parks-dev..."
oc project ${GUID}-parks-dev

oc policy add-role-to-user edit system:serviceaccount:90cd-jenkins:jenkins -n 90cd-parks-dev
oc new-app --template=mongodb-persistent --param-file=params_file/mongodb.params

cd ../../MLBParks
mvn -s ../nexus_settings.xml clean package -DskipTests=true
oc new-build --binary=true --name="mlbpark-dev-build"  --image-stream=jboss-eap70-openshift:1.7 -n 90cd-parks-dev -e MAVEN_MIRROR_URL=http://nexus3-90cd-nexus.apps.na311.openshift.opentlc.com/repository/maven-all-public
oc start-build mlbpark-dev-build --from-file=. --follow


cd ../Nationalparks
mvn -s ../nexus_settings.xml clean package -DskipTests=true
oc new-build --binary=true --name="nationalparks-dev-build"  --image-stream=jboss-eap70-openshift:1.7 -n 90cd-parks-dev -e MAVEN_MIRROR_URL=http://nexus3-90cd-nexus.apps.na311.openshift.opentlc.com/repository/maven-all-public
oc start-build nationalparks-dev-build --from-file=. --follow


cd ../ParksMap
mvn -s ../nexus_settings.xml clean package -DskipTests=true
oc new-build --binary=true --name="parksmap-dev-build"  --image-stream=jboss-eap70-openshift:1.7 -n 90cd-parks-dev -e MAVEN_MIRROR_URL=http://nexus3-90cd-nexus.apps.na311.openshift.opentlc.com/repository/maven-all-public
oc start-build parksmap-dev-build --from-file=. --follow


oc new-app 90cd-parks-dev/mlbpark-dev-tasks:0.0-0 --name=mlbpark-dev-tasks --allow-missing-imagestream-tags=true -n 90cd-parks-dev
oc set triggers dc/mlbpark-dev-tasks --remove-all -n 90cd-parks-dev
oc expose dc mlbpark-dev-tasks --port 8080 -n 90cd-parks-dev
oc expose svc mlbpark-dev-tasks -n 90cd-parks-dev
oc create configmap mlbpark-tasks-config --from-literal="APPNAME=MLB Parks (Dev)" --from-literal="application-users.properties=Placeholder" --from-literal="application-roles.properties=Placeholder" -n 90cd-parks-dev
oc set volume dc/mlbpark-dev-tasks --add --name=jboss-config --mount-path=/opt/eap/standalone/configuration/application-users.properties --sub-path=application-users.properties --configmap-name=tasks-config -n  90cd-parks-dev


