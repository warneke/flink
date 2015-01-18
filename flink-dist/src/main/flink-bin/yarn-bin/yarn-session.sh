#!/usr/bin/env bash
################################################################################
#  Licensed to the Apache Software Foundation (ASF) under one
#  or more contributor license agreements.  See the NOTICE file
#  distributed with this work for additional information
#  regarding copyright ownership.  The ASF licenses this file
#  to you under the Apache License, Version 2.0 (the
#  "License"); you may not use this file except in compliance
#  with the License.  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
# limitations under the License.
################################################################################



bin=`dirname "$0"`
bin=`cd "$bin"; pwd`

# get Flink config
. "$bin"/config.sh

if [ "$FLINK_IDENT_STRING" = "" ]; then
        FLINK_IDENT_STRING="$USER"
fi

# find the location of the yarn command
if [ -n ${HADOOP_YARN_HOME+x} ]; then
	if [ -f "$HADOOP_YARN_HOME/bin/yarn" ]; then
		HADOOP_YARN_BIN=$HADOOP_YARN_HOME/bin/yarn
	fi
fi
if [[ -z ${HADOOP_YARN_BIN+x} && -n ${HADOOP_HOME+x} ]]; then
	if [ -f "$HADOOP_HOME/bin/yarn" ]; then
		HADOOP_YARN_BIN=$HADOOP_HOME/bin/yarn
	fi
fi
if [ -z ${HADOOP_YARN_BIN+x} ]; then
	yarn_tmp=`which yarn`
	if [ $? -eq 0 ]; then
		HADOOP_YARN_BIN=$yarn_tmp
	fi
fi
if [ -z ${HADOOP_YARN_BIN+x} ]; then
	echo "Cannot find 'yarn' command. Please set HADOOP_YARN_HOME to point to your YARN installation or make sure the 'yarn' command is defined in your standard path." >&2
	exit 1
fi

FLINK_UBER_JAR=`find $FLINK_LIB_DIR -name *yarn-uberjar.jar`
if [ "$FLINK_UBER_JAR" = "" ]; then
	echo "Cannot locate the Flink uberjar on the library path $FLINK_LIB_DIR. Please check your Flink installation." >&2
	exit 2
fi

YARN_LOG_DIR=$FLINK_LOG_DIR
YARN_LOGFILE=$FLINK_LOG_DIR/flink-$FLINK_IDENT_STRING-yarn-session-$HOSTNAME.log
YARN_CLIENT_OPTS="-Dlog.file="$YARN_LOGFILE" -Dlog4j.configuration=file:"$FLINK_CONF_DIR"/log4j-yarn-session.properties -Dlogback.configurationFile=file:"$FLINK_CONF_DIR"/logback-yarn.xml"

export FLINK_CONF_DIR
export YARN_CLIENT_OPTS
export YARN_LOG_DIR
export YARN_LOGFILE

$HADOOP_YARN_BIN jar $FLINK_UBER_JAR org.apache.flink.yarn.Client -ship $bin/../ship/ -confDir $FLINK_CONF_DIR -j $FLINK_UBER_JAR $*

