# Amazon FPGA Hardware Development Kit
#
# Copyright 2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Amazon Software License (the "License"). You may not use
# this file except in compliance with the License. A copy of the License is
# located at
#
#    http://aws.amazon.com/asl/
#
# or in the "license" file accompanying this file. This file is distributed on
# an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or
# implied. See the License for the specific language governing permissions and
# limitations under the License.

# Script must be sourced from a bash shell or it will not work
# When being sourced $0 will be the interactive shell and $BASH_SOURCE_ will contain the script being sourced
# When being run $0 and $_ will be the same.

script=${BASH_SOURCE[0]}
if [ $script == $0 ]; then
  echo "ERROR: You must source this script"
  exit 2
fi

full_script=$(readlink -f $script)
script_name=$(basename $full_script)
script_dir=$(dirname $full_script)

instance_id=`curl http://169.254.169.254/latest/meta-data/instance-id`
instance_type=`curl http://169.254.169.254/latest/meta-data/instance-type`

echo "Test Running on INSTANCE ID: $instance_id INSTANCE TYPE: $instance_type"

if [ ":$WORKSPACE" == ":" ]; then
    export WORKSPACE=$(git rev-parse --show-toplevel)
fi
export WORKON_HOME=$WORKSPACE/.virtualenvs

$script_dir/install_python_venv.sh

# Setup default environment to work on
source $WORKSPACE/.virtualenvs/python2/bin/activate

export PYTHONPATH=$WORKSPACE/shared/lib:$PYTHONPATH

export AWS_DEFAULT_REGION=us-east-1
