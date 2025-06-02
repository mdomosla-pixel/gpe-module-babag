#!/bin/bash

box=${1:-sut}
rake "beaker:ssh:default[${box}]"
