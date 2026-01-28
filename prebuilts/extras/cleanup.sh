#!/system/bin/sh

sleep 0.5

rm -rf /data/dalvik-cache/*
rm -rf /data/app/*/*/oat/*/* 
rm -rf /data/system/package_cache/*
rm -rf /data/data/*/app_ads_cache    
rm -rf /data/data/*/*cache
rm -rf /data/data/*/*cache*
rm -rf /data/data/*/cache*
rm -rf /data/data/*/code_cache
rm -rf /data/data/*/code_cache*
rm -rf /data/data/*/*code_cache
rm -rf /data/data/*/*code_cache*
rm -rf /sdcard/Android/data/*/cache*/*
rm -rf /sdcard/Android/data/*/*cache/*
rm -rf /sdcard/Android/data/*/*cache*/*

rm -rf /data/tombstones/*
rm -rf /data/system/dropbox/*
rm -rf /data/log/*

rm -rf /cache/*

rm -rf /tmp/scripts
