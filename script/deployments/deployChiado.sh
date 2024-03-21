#!/bin/bash

deploy_and_verify() {
  local contract_name=$1
  local precalculated_address=$2
  local deployment_output
  local deployed_address

  echo ""
  echo "Deploying ${contract_name}..."
  deployment_output=$(forge create \
    --rpc-url ${RPC_URL} \
    --private-key ${PRIVATE_KEY} \
    --optimizer-runs 200 \
    --chain-id 10200 \
    --verify \
    --verifier-url $VERIFIER_URL \
    --verifier $VERIFIER \
    --etherscan-api-key ${VERIFIER_API_KEY} \
    "${@:3}") # Passes all arguments beyond the second to forge create

  deployed_address=$(echo "$deployment_output" | grep "Deployed to:" | awk '{print $3}')
  echo "${contract_name} deployed at ${deployed_address}"

  # Verify that the deployed address matches the precalculated address
  if [ "$deployed_address" = "$precalculated_address" ]; then
    echo "Verification Successful: Deployed address matches the precalculated address for ${contract_name}."
  else
    echo "Verification Failed: Deployed address does not match the precalculated address for ${contract_name}."
    echo "Precalculated Address: $precalculated_address"
    echo "Deployed Address: $deployed_address"
    # exit the script if the addresses don't match
    exit 1
  fi
}

# Set the environment variables, also for use in node script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "$DIR/../../.env"

# declare Chiado constants
V1_HUB_ADDRESS='0xdbF22D4e8962Db3b2F1d9Ff55be728A887e47710'
# chiado v1 deployment time is 1675244965 unix time, 
# or 9:49:25 am UTC  |  Wednesday, February 1, 2023
# but like on mainnet we want to offset this to midnight to start day zero 
# on the Feb 1 2023, which has unix time 1675209600
INFLATION_DAY_ZERO=1675209600
# put a long bootstrap time for testing bootstrap 
BOOTSTRAP_ONE_YEAR=31540000
# fallback URI 
URI='https://fallback.aboutcircles.com/v1/circles/{id}.json'

# re-export the variables for use here and in the general calculation JS script
export PRIVATE_KEY=$PRIVATE_KEY_CHIADO
export RPC_URL=$RPC_URL_CHIADO
VERIFIER_URL=$BLOCKSCOUT_URL_CHIADO
VERIFIER_API_KEY=$BLOCKSCOUT_API_KEY
VERIFIER=$BLOCKSCOUT_VERIFIER

# Run the Node.js script to predict contract addresses
# Assuming predictAddresses.js is in the current directory
read HUB_ADDRESS_01 MIGRATION_ADDRESS_02 NAMEREGISTRY_ADDRESS_03 \
ERC20LIFT_ADDRESS_04 STANDARD_TREASURY_ADDRESS_05 BASE_GROUPMINTPOLICY_ADDRESS_06 \
<<< $(node predictDeploymentAddresses.js)

# Log the predicted deployment addresses
echo "Predicted deployment addresses:"
echo "==============================="
echo "Hub: ${HUB_ADDRESS_01}"
echo "Migration: ${MIGRATION_ADDRESS_02}"
echo "NameRegistry: ${NAMEREGISTRY_ADDRESS_03}"
echo "ERC20Lift: ${ERC20LIFT_ADDRESS_04}"
echo "StandardTreasury: ${STANDARD_TREASURY_ADDRESS_05}"
echo "BaseGroupMintPolicy: ${BASE_GROUPMINTPOLICY_ADDRESS_06}"

# Deploy the contracts

echo ""
echo "Starting deployment..."
echo "======================"

deploy_and_verify "Circles ERC1155 Hub" $HUB_ADDRESS_01 \
  src/hub/Hub.sol:Hub \
  --constructor-args $V1_HUB_ADDRESS \
  $NAMEREGISTRY_ADDRESS_03 $MIGRATION_ADDRESS_02 $ERC20LIFT_ADDRESS_04 \
  $STANDARD_TREASURY_ADDRESS_05 $INFLATION_DAY_ZERO \
  $BOOTSTRAP_ONE_YEAR $URI


# # Deploy the ERC1155 Hub
# MULTITOKEN_HUB=$(forge create \
#   --rpc-url ${RPC_URL} \
#   --private-key ${PRIVATE_KEY} \
#   src/hub/Hub.sol:Hub \
#   --constructor-args ${V1_HUB_ADDRESS} ${NAMEREGISTRY_ADDRESS_03} \
#   ${MIGRATION_ADDRESS_02} ${ERC20LIFT_ADDRESS_04} \
#   ${STANDARD_TREASURY_ADDRESS_05} ${INFLATION_DAY_ZERO} \
#   ${BOOTSTRAP_ONE_YEAR} ${URI})

# # Extract the deployed address from the output
# HUB_ADDRESS=$(echo "$MULTITOKEN_HUB" | grep "Deployed to:" | awk '{print $3}')
# echo "ERC1155 Hub deployed at ${HUB_ADDRESS}"

# MIGRATION = $(forge create \
#   --rpc-url ${RPC_URL} \
#   --private-key ${PRIVATE_KEY} \
#   src/migration/Migration.sol:Migration \
#   --constructor-args ${HUB_ADDRESS})

echo ""
echo "Summary:"
echo "========"
echo "Hub: ${HUB_ADDRESS}"
  
# echo "Deploying MintSplitter..."
# MINT_SPLITTER_DEPLOYMENT=$(forge create \
#   --rpc-url ${RPC_URL} \
#   --private-key ${PRIVATE_KEY} \
#   src/mint/MintSplitter.sol:MintSplitter \
#   --constructor-args ${V1_HUB_ADDRESS})

# MINT_SPLITTER_ADDRESS=$(echo "$MINT_SPLITTER_DEPLOYMENT" | grep "Deployed to:" | awk '{print $3}')
# echo "MintSplitter deployed at ${MINT_SPLITTER_ADDRESS}"

# echo "Deploying TimeCircle..."
# TIME_CIRCLE_DEPLOYMENT=$(forge create \
#   --rpc-url ${RPC_URL} \
#   --private-key ${PRIVATE_KEY} \
#   src/circles/TimeCircle.sol:TimeCircle)

# TIME_CIRCLE_ADDRESS=$(echo "$TIME_CIRCLE_DEPLOYMENT" | grep "Deployed to:" | awk '{print $3}')
# echo "TimeCircle deployed at ${TIME_CIRCLE_ADDRESS}"

# echo "Deploying GroupCircle..."
# GROUP_CIRCLES_DEPLOYMENT=$(forge create \
#   --rpc-url ${RPC_URL} \
#   --private-key ${PRIVATE_KEY} \
#   src/circles/GroupCircle.sol:GroupCircle)

# GROUP_CIRCLES_ADDRESS=$(echo "$GROUP_CIRCLES_DEPLOYMENT" | grep "Deployed to:" | awk '{print $3}')
# echo "GroupCircle deployed at ${GROUP_CIRCLES_ADDRESS}"

# echo "Deploying Graph..."
# GRAPH_DEPLOYMENT=$(forge create \
#   --rpc-url ${RPC_URL} \
#   --private-key ${PRIVATE_KEY} \
#   src/graph/Graph.sol:Graph \
#   --constructor-args ${MINT_SPLITTER_ADDRESS} '0x0000000000000000000000000000000000000000' ${TIME_CIRCLE_ADDRESS} ${GROUP_CIRCLES_ADDRESS})

# GRAPH_ADDRESS=$(echo "$GRAPH_DEPLOYMENT" | grep "Deployed to:" | awk '{print $3}')
# echo "Graph deployed at ${GRAPH_ADDRESS}"

# echo ""
# echo "Summary:"
# echo "========"
# echo "MintSplitter: ${MINT_SPLITTER_ADDRESS}"
# echo "TimeCircle: ${TIME_CIRCLE_ADDRESS}"
# echo "GroupCircle: ${GROUP_CIRCLES_ADDRESS}"
# echo "Graph: ${GRAPH_ADDRESS}"
