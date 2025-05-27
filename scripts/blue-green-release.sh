#!/usr/bin/env bash
set -xe

function change_waights(){
    local blue=$1
    local green=$2
    local app=$3
    argocd app set --helm-set weights.blue="$blue" --helm-set weights.green="$green" "$app"
    echo "App ${app} sync"
    argocd app sync "$app"
}

function rollback_to_latest_stable(){
    local blue=$1
    local green=$2
    local app=$3
    argocd app set --helm-set weights.blue="$blue" --helm-set weights.green="$green"
    echo "App ${app} will be sync to master state"
    argocd app sync "$app"

}

function check_weights(){
    local blue_weight=$1
    local green_weight=$2
    local route_json=$(kubectl get httproutes -o json)
    local blue_current=$(jq '.items[0].spec.rules[0].backendRefs[] | select(.name|test(".-blue$")) | .weight' <<< "${route_json}")
    local green_current=$(jq '.items[0].spec.rules[0].backendRefs[] | select(.name|test(".-green$")) | .weight' <<< "${route_json}")

    echo "Expected weights are: blue - ${blue_weight}, green - ${green_weight}"
    echo "Current weight are: blue - ${blue_current}, green - ${green_current}"

    if [ "${blue_weight}" -eq "${blue_current}" ] && [ "${green_weight}" -eq "${green_current}" ]; then
        echo "Weights were updated"
        return 0
    else
        echo "Weights weren't updated"
        return 1
    fi
}

ARGO_APP_NAME="yolo-deploy-bg"
RETRY_NUMBER=5
blue_current=$(grep -A2 weights: charts/deploy-bg/values.yaml | grep -oP "(?<=blue: )[0-9]{1,3}$")
green_current=$(grep -A2 weights: charts/deploy-bg/values.yaml | grep -oP "(?<=green: )[0-9]{1,3}$")
blue_help=$((blue_current-100))
green_help=$((green_current-100))
blue="${blue_help#-}"
green="${green_help#-}"

echo "Weights will be changed to blue - ${blue}, green - ${green}"
change_waights "${blue}" "${green}" "$ARGO_APP_NAME"
sleep 60
retry=0
while [ "$retry" -lt "${RETRY_NUMBER}" ]; do
    echo "Checking if application is synchoronised, Retry number ${retry}"
    updated=$(check_weights "${blue}" "${green}")
    if [ "${updated}" ]; then
        echo "Weight update finish successfully"
        break
    else
        echo "Weight update didn't finish"
        echo "Retring in 15s"
        retry=$((retry+1))
        sleep 15
    fi
done
if [ $retry -ge "${RETRY_NUMBER}" ]; then
    echo "Too many retries. Rolling back to previous version"
    rollback_to_latest_stable "${blue_current}" "${green_current}" "${ARGO_APP_NAME}"
    exit 1
fi


echo "Blue/green deployment finish with success"
echo "Preparing commit for official release"
exit 0