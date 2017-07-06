#!/bin/sh

#  default.sh
#  BLESKELE
#
#  Created by Gregory Joseph on 2017-07-06.
#  Copyright © 2017 4iiii. All rights reserved.
FILE="${SRCROOT}/HockeySDK-iOS/BuildAgent"
if [ -f "$FILE" ]; then
"$FILE"
fi

for SCRIPT in ${PROJECT_DIR}/BuildScript/*
do
echo "Doing ${SCRIPT}"
chmod u+x ${SCRIPT}
"$SCRIPT"
done
