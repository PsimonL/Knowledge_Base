#!/bin/bash

SOURCE_FOLDER="/vagrant"
DESTINATION_FOLDER="/home/vagrant"

while true; do
    rsync -av --delete "$SOURCE_FOLDER/" "$DESTINATION_FOLDER/"
    inotifywait -r -e modify,create,delete,move "$SOURCE_FOLDER"
done
