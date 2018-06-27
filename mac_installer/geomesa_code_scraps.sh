#!/usr/bin/env bash


spark-submit --jars $GEOMESA_FS_HOME/dist/spark/geomesa-fs-spark-runtime_2.11-$GEOMESA_VERSION.jar /Users/hugh.saalmans/git/iag_geo/geomesa_tools/mac_installer/geomesa_convert.py --target-s3-bucket <myBucket>