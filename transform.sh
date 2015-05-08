#!/bin/bash
cat $1 | jq -f transform.jq > $2