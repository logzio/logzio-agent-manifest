#!/bin/bash

scp -i "mac-script.pem" ../mac.bash ec2-user@ec2-54-227-68-220.compute-1.amazonaws.com:tests

############################################ TestRunScriptWithRequiredArgs_StatusCode0 ##########################################

ssh -i "mac-script.pem" ec2-user@ec2-54-227-68-220.compute-1.amazonaws.com << 'EOF'
    tests/mac.bash --url api.logz.io --id 123 --test 1
    exit $?
EOF

status_code=$?
if [ $status_code -eq 0 ]; then
    echo "TestRunScriptNoURL: Success"
else
    echo "TestRunScriptNoURL: Failed - Status Code $status_code"
    exit 1
fi

echo "########################################################################################"

#################################################################################################################################

############################################ TestRunScriptNoRequiredArgs_StatusCode1 ############################################

ssh -i "mac-script.pem" ec2-user@ec2-54-227-68-220.compute-1.amazonaws.com << 'EOF'
    tests/mac.bash --test 1
    exit $?
EOF

status_code=$?
if [ $status_code -eq 1 ]; then
    echo "TestRunScriptNoArgs: Success"
else
    echo "TestRunScriptNoArgs: Failed - Status Code $status_code"
    exit 1
fi

echo "########################################################################################"

#################################################################################################################################

################################################# TestRunScriptNoURL_StatusCode1 ################################################

ssh -i "mac-script.pem" ec2-user@ec2-54-227-68-220.compute-1.amazonaws.com << 'EOF'
    tests/mac.bash --id 123 --test 1
    exit $?
EOF

status_code=$?
if [ $status_code -eq 1 ]; then
    echo "TestRunScriptNoURL: Success"
else
    echo "TestRunScriptNoURL: Failed - Status Code $status_code"
    exit 1
fi

echo "########################################################################################"

#################################################################################################################################

source ../mac_functions.bash

get_arguments "$@"
echo "test"

