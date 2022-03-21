#!/bin/bash

set -e -o pipefail

xsh log info 'xsh list aws'
xsh list aws

# Only some of the utils under aws/gist are tested.
# Most of the other utils are not tested due to the costs of the AWS
# cloud resources.

xsh log info 'xsh aws/gist/ec2/linux/installer/supervisor'
# -i: initd script, -o: chkconfig on, -s: service start
xsh aws/gist/ec2/linux/installer/supervisor -ios

exit
