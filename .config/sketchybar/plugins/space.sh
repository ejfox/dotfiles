#!/bin/bash

if [ "$SELECTED" = "true" ]; then
  sketchybar --set $NAME icon.color=0xffffffff icon.font="$FONT:Bold:14.0" icon.padding_left=10 icon.padding_right=10
else
  sketchybar --set $NAME icon.color=0xff666666 icon.font="$FONT:Regular:14.0" icon.padding_left=10 icon.padding_right=10
fi
