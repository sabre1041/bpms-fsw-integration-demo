#!/bin/sh 
DEMO="JBoss BPM Suite & JBoss FSW Integration Demo"
AUTHORS="Kenny Peeples, Eric D. Schabell"
PROJECT="git@github.com:eschabell/bpms-fsw-integration-demo.git"
PRODUCT="JBoss BPM Suite & JBoss FSW Integration Demo"
JBOSS_HOME=./target/jboss-eap-6.1
JBOSS_HOME_FSW=./target/jboss-eap-6.1.fsw
SERVER_DIR=$JBOSS_HOME/standalone/deployments/
SERVER_CONF=$JBOSS_HOME/standalone/configuration/
SERVER_BIN=$JBOSS_HOME/bin
SERVER_BIN_FSW=$JBOSS_HOME_FSW/bin
SRC_DIR=./installs
SUPPORT_DIR=./support
PRJ_DIR=./projects
PRJ_DTGOVWF=$JBOSS_HOME_FSW/dtgov-data
BPMS=jboss-bpms-installer-6.0.2.GA-redhat-5.jar
FSW=jboss-fsw-installer-6.0.0.GA-redhat-4.jar
DTGOVWF=dtgov-workflows-1.0.1.Final-redhat-8.jar
BPMS_VERSION=6.0.2
FSW_VERSION=6.0.0

# wipe screen.
clear 

echo
echo "####################################################################"
echo "##                                                                ##"   
echo "##  Setting up ${DEMO}       ##"
echo "##                                                                ##"   
echo "##                                                                ##"   
echo "##     ####   ####    #   #    ###       ####   ####  #     #     ##"
echo "##     #   #  #   #  # # # #  #      #   #     #      #     #     ##"
echo "##     ####   ####   #  #  #   ##   ###  ###    ###   #  #  #     ##"
echo "##     #   #  #      #     #     #   #   #         #  # # # #     ##"
echo "##     ####   #      #     #  ###        #     ####    #   #      ##"
echo "##                                                                ##"   
echo "##                                                                ##"   
echo "##  brought to you by,                                            ##"   
echo "##             ${AUTHORS}                    ##"
echo "##                                                                ##"   
echo "##  ${PROJECT}        ##"
echo "##                                                                ##"   
echo "####################################################################"
echo

command -v mvn -q >/dev/null 2>&1 || { echo >&2 "Maven is required but not installed yet... aborting."; exit 1; }

# make some checks first before proceeding.	
if [ -r $SRC_DIR/$BPMS ] || [ -L $SRC_DIR/$BPMS ]; then
	echo JBoss product sources, $BPMS present...
		echo
else
		echo Need to download $BPMS package from the Customer Portal 
		echo and place it in the $SRC_DIR directory to proceed...
		echo
		exit
fi

# make some checks first before proceeding.	
if [ -r $SRC_DIR/$FSW ] || [ -L $SRC_DIR/$FSW ]; then
	echo JBoss product sources, $FSW present...
		echo
else
		echo Need to download $FSW package from the Customer Portal 
		echo and place it in the $SRC_DIR directory to proceed...
		echo
		exit
fi

# Move the old JBoss instance, if it exists, to the OLD position.
if [ -x $JBOSS_HOME ]; then
		echo "  - existing JBoss product install detected and removed..."
		echo
		rm -rf ./target
fi

echo "  - modify FSW installer script with full path."
echo
sed -i "" "s:<installpath>.*</installpath>:<installpath>$(pwd)/target</installpath>:" $SUPPORT_DIR/installation-fsw 

# Run FSW installer.
java -jar $SRC_DIR/$FSW $SUPPORT_DIR/installation-fsw -variablefile $SUPPORT_DIR/installation-fsw.variables
mv $JBOSS_HOME $JBOSS_HOME_FSW

echo "  - copy in property for monitoring dtgov queries..."
echo 
cp $SUPPORT_DIR/dtgov.properties $JBOSS_HOME_FSW/standalone/configuration

# Run BPM Suite installer.
echo Product installer running now...
echo
java -jar $SRC_DIR/$BPMS $SUPPORT_DIR/installation-bpms -variablefile $SUPPORT_DIR/installation-bpms.variables

echo "  - enabling demo accounts role setup in application-roles.properties file..."
echo
cp $SUPPORT_DIR/application-roles.properties $SERVER_CONF

echo "  - setting up demo projects..."
echo
cp -r $SUPPORT_DIR/bpm-suite-demo-niogit $SERVER_BIN/.niogit

echo "  - setting up standalone.xml configuration adjustments..."
echo
cp $SUPPORT_DIR/standalone.xml $SERVER_CONF/standalone.xml

# Add execute permissions to the standalone.sh script.
echo "  - making sure standalone.sh for server is executable..."
echo
chmod u+x $JBOSS_HOME/bin/standalone.sh

# cp pom to dtgovwf, mvn package, cli upload + type
echo "  - copy modified pom to dtgov workflow project and build..."
echo
cp $SUPPORT_DIR/dtgovwf-pom.xml $PRJ_DTGOVWF/pom.xml
mvn -f $PRJ_DTGOVWF/pom.xml package
cp $PRJ_DTGOVWF/target/$DTGOVWF $SUPPORT_DIR

# Final instructions to user to start and run demo.
echo
echo "==========================================================================================="
echo "=                                                                                         =" 
echo "=  Start JBoss BPM Suite server:                                                          ="
echo "=                                                                                         =" 
echo "=    $ $SERVER_BIN/standalone.sh -Djboss.socket.binding.port-offset=100    ="
echo "=                                                                                         =" 
echo "=  In seperate terminal start JBoss FSW server:                                           ="
echo "=                                                                                         =" 
echo "=    $ $SERVER_BIN_FSW/standalone.sh                                       ="
echo "=                                                                                         =" 
echo "=                                                                                         =" 
echo "=  *************** BPM GOVERNANCE DEMO ***************                                    ="
echo "=                                                                                         =" 
echo "=  After starting server you need to upload the DTGOV workflows with following command:   ="
echo "=                                                                                         =" 
echo "=    $ $SERVER_BIN_FSW/s-ramp.sh -f support/sramp-dtgovwf-upload.txt       ="
echo "=                                                                                         =" 
echo "=  Now open Business Central to build & deploy BPM process in your browser at:            ="
echo "=                                                                                         =" 
echo "=    http://localhost:8180/business-central     (u:erics/p:bpmsuite1!)                    ="
echo "=                                                                                         =" 
echo "=  As a developer you have a modified project pom.xml (found in projects/customer)        ="
echo "=  which includes an s-ramp wagon and s-ramp repsitory locations for transporting any     ="
echo "=  artifacts we build with 'mvn deploy'.                                                  ="
echo "=                                                                                         =" 
echo "=    $ mvn deploy -f projects/customer/evaluation/pom.xml                                 ="
echo "=                                                                                         =" 
echo "=  The rewards project now has been deployed in s-ramp repository where you can view      =" 
echo "=  the artifacts and see that the governance process in the s-ramp was automatically      ="
echo "=  started. Claim the approval task in dashboard available in your browser and see the    ="
echo "=  rewards artifact deployed in /tmp/dev copied to /tmp/qa upon approval:                 ="
echo "=                                                                                         =" 
echo "=    http://localhost:8080/s-ramp-ui            u:erics/p:jbossfsw1!                      ="
echo "=                                                                                         =" 
echo "=                                                                                         =" 
echo "=  *************** FSW SERVICE WITH EXTERNAL BPM PROCESS DEMO ***************             ="
echo "=                                                                                         =" 
echo "=  Deploying the camel route in JBoss Fuse Serivce Works as follows:                      ="
echo "=                                                                                         ="
echo "=    - start the JBoss FSW with:                                                          ="
echo "=                                                                                         ="
echo "=        $SERVER_BIN_FSW/standalone.sh                                     ="
echo "=                                                                                         ="
echo "=        (TODO: Kenny as discussed, here we need to have Switchyard app build and         ="
echo "=               leverage a camel route based on the on in projects/fuse-integration.)     ="
echo "=                                                                                         ="
echo "=   $DEMO Setup Complete.                          ="
echo "=                                                                                         ="
echo "==========================================================================================="
echo

