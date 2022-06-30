#!/bin/bash

sed "s/##DATE##/$(date +%Y-%m-%d)/" xerdiff.v > xerdiff_pre.v
sed "s/##DATE##/$(date +%Y-%m-%d)/" xerdump.v > xerdump_pre.v
sed "s/##DATE##/$(date +%Y-%m-%d)/" xertask.v > xertask_pre.v
sed "s/##DATE##/$(date +%Y-%m-%d)/" xerpred.v > xerpred_pre.v
sed "s/##DATE##/$(date +%Y-%m-%d)/" xer2json.v > xer2json_pre.v

echo "building xerdiff (linux)..."
v -prod -d prebuilt xerdiff_pre.v -o ../bin/linux/xerdiff

echo "building xerdump (linux)..."
v -prod -d prebuilt xerdump_pre.v -o ../bin/linux/xerdump

echo "building xertask (linux)..."
v -prod -d prebuilt xertask_pre.v -o ../bin/linux/xertask

echo "building xerpred (linux)..."
v -prod -d prebuilt xerpred_pre.v -o ../bin/linux/xerpred

echo "building xer2json (linux)..."
v -prod -d prebuilt xer2json_pre.v -o ../bin/linux/xer2json

echo "building xerdiff (windows)..."
v -prod -d prebuilt xerdiff_pre.v -os windows -o ../bin/windows/xerdiff

echo "building xerdump (windows)..."
v -prod -d prebuilt xerdump_pre.v -os windows -o ../bin/windows/xerdump

echo "building xertask (windows)..."
v -prod -d prebuilt xertask_pre.v -os windows -o ../bin/windows/xertask

echo "building xerpred (windows)..."
v -prod -d prebuilt xerpred_pre.v -os windows -o ../bin/windows/xerpred

echo "building xer2json (windows)..."
v -prod -d prebuilt xer2json_pre.v -os windows -o ../bin/windows/xer2json

rm *_pre.v