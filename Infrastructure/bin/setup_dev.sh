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

echo "JENKINS: Setting up proper Jenkins permission to manage projects, no permission no talk..."
oc policy add-role-to-user view --serviceaccount=default -n ${GUID}-parks-dev
oc policy add-role-to-user edit system:serviceaccount:${GUID}-jenkins:jenkins -n ${GUID}-parks-dev

echo "MONGODB: Create new persistent mongodb using params file, sssshhh secrets in here..."
oc new-app --template=mongodb-persistent --param-file=params_file/mongodb.params -n ${GUID}-parks-dev

echo "APPS: Create necessary buildConfigs for all three apps... "

echo "MLBParks: Starting setting up and configuring MLBParks, you know where player shut up and pitch ..."
oc new-build --name="mlbparks" --binary=true  jboss-eap70-openshift:1.7 -n ${GUID}-parks-dev
oc new-app --name=mlbparks ${GUID}-parks-dev/mlbparks:0.0-0 --param-file=params_file/mlbparks.params --allow-missing-imagestream-tags=true -n ${GUID}-parks-dev
oc rollout pause dc/mlbparks -n ${GUID}-parks-dev
oc start-build mlbparks -n ${GUID}-parks-dev

echo "MLBParks: Configuring configMap..."
oc create configmap mlbparks --from-literal=APPNAME="MLB Parks (Dev)" -n ${GUID}-parks-dev
oc set env --from=configmap/mlbparks dc/mlbparks -n ${GUID}-parks-dev

echo "MLBParks: Using properties file to populate mongoDB configs..."
oc create configmap mongodb-configs --from-file=configMaps/mongo.properties -n ${GUID}-parks-dev
oc set env --from=configmap/mongodb-configs dc/mlbparks -n ${GUID}-parks-dev
oc rollout resume dc/mlbparks -n ${GUID}-parks-dev
echo "MLBParks: Exposing service with label..."
oc expose svc/mlbparks --labels='type=parksmap-backend' -n ${GUID}-parks-dev

echo "MLBParks: We dont want sick patient running around and infect everyone else with disease, assigned doctor to the patient..."
oc set probe dc/mlbparks --readiness --get-url=http://:8080/ws/healthz/ --initial-delay-seconds=10 -n ${GUID}-parks-dev

echo "MLBParks: Brain without data, identical to a headless hoooman, pumping some..."
oc set deployment-hook dc/mlbparks -n ${GUID}-parks-dev --post -- curl http://mlbparks.${GUID}-parks-dev.svc:8080/ws/data/load/

echo "MLBParks: Done configuring MLBParks, taking some sleep for 2 secs, just because I can..."
sleep 2

printf '%*s\n' 100 | tr ' ' '*'

echo "NationalParks: Preparing place for animals to sleep and play..."
oc new-build --name="nationalparks" --binary=true  jboss-eap70-openshift:1.7 -n ${GUID}-parks-dev
oc new-app --name=nationalparks ${GUID}-parks-dev/nationalparks:0.0-0 --param-file=params_file/nationalparks.params --allow-missing-imagestream-tags=true -n ${GUID}-parks-dev
oc start-build nationalparks -n ${GUID}-parks-dev
oc rollout pause dc/nationalparks -n ${GUID}-parks-dev

echo "NationalParks: Configuring configMap, config that being mapped..."
oc create configmap nationalparks --from-literal=APPNAME="National Parks (Dev)" -n ${GUID}-parks-dev
oc set env --from=configmap/nationalparks dc/nationalparks -n ${GUID}-parks-dev
oc set env --from=configmap/mongodb-configs dc/nationalparks -n ${GUID}-parks-dev
oc rollout resume dc/nationalparks -n ${GUID}-parks-dev

echo "NationalParks: Exposing service with label,because label is gold on OpenShift..."
oc expose svc/nationalparks --labels='type=parksmap-backend' -n ${GUID}-parks-dev

echo "NationalParks: We dont want sick patient running around and infect everyone else with disease, assigned doctor to the patient..."
oc set probe dc/nationalparks --readiness --get-url=http://:8080/ws/healthz/ --initial-delay-seconds=10 -n ${GUID}-parks-dev
oc set deployment-hook dc/nationalparks -n ${GUID}-parks-dev --post -- curl http://nationalparks.${GUID}-parks-dev.svc:8080/ws/data/load/

echo "ParksMap: Continue to configure ParksMap, im stronger than before, no need to sleep..."
oc new-build --binary=true --name="parksmap" redhat-openjdk18-openshift:1.2 -n ${GUID}-parks-dev
oc new-app ${GUID}-parks-dev/parksmap:0.0-0 --name=parksmap  --allow-missing-imagestream-tags=true -n ${GUID}-parks-dev
oc start-build parksmap -n ${GUID}-parks-dev
oc rollout pause dc/parksmap
oc create configmap parksmap --from-literal=APPNAME="ParksMap (Dev)" --param-file=params_file/parksmap.params -n ${GUID}-parks-dev
oc set env --from=configmap/parksmap dc/parksmap -n ${GUID}-parks-dev
oc policy add-role-to-user view --serviceaccount=default
oc rollout resume dc/parksmap