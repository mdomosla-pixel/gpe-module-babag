#!/bin/bash

BEAKER_provision=no BEAKER_destroy=no \
    bundle exec rake beaker
#rake acceptance
