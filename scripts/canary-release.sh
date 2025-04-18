#!/usr/bin/env bash
set -xe

function change_waights(){
    local stable=$1
    local canary=$2
    local app=$3
    argocd app set --helm-set weights.stable="$stable" --helm-set weights.canary="$canary" "$app"
    echo "App ${app} sync"
    argocd app sync "$app"
}

function rollback_to_latest_stable(){
    local app=$1
    argocd app set --helm-set weights.stable=100 --helm-set weights.canary=0
    echo "App ${app} will be sync to master state"
    argocd app sync "$app"

}

function check_weights(){
    local stable_weight=$1
    local canary_weight=$2
    local route_json=$(kubectl get httproutes -o json)
    local stable_current=$(jq '.items[0].spec.rules[0].backendRefs[] | select(.name|test(".-stable$")) | .weight' <<< "${route_json}")
    local canary_current=$(jq '.items[0].spec.rules[0].backendRefs[] | select(.name|test(".-canary$")) | .weight' <<< "${route_json}")

    echo "Expected weights are: stable - ${stable_weight}, canary - ${canary_weight}"
    echo "Current weight are: stable - ${stable_current}, canary - ${canary_current}"

    if [ "${stable_weight}" -eq "${stable_current}" ] && [ "${canary_weight}" -eq "${canary_current}" ]; then
        echo "Weights were updated"
        return 0
    else
        echo "Weights weren't updated"
        return 1
    fi
}

ARGO_APP_NAME="yolo-deploy-canary"
RETRY_NUMBER=5

declare stable_weights
declare canary_weights
stable_weights=(80 60 40 20)
canary_weights=(20 40 60 80)

for i in "${!stable_weights[@]}"; do
    echo "Weights will be changed to stable = ${stable_weights[$i]}, canary = ${canary_weights[$i]}"
    change_waights "${stable_weights[$i]}" "${canary_weights[$i]}" "$ARGO_APP_NAME"
    sleep 5
    retry=0
    while [ "$retry" -lt "${RETRY_NUMBER}" ]; do
        echo "Checking if application is synchoronised, Retry number ${retry}"
        updated=$(check_weights "${stable_weights[$i]}" "${canary_weights[$i]}")
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
        rollback_to_latest_stable "${ARGO_APP_NAME}"
        exit 1
    fi
done

echo "Canary deployment finish with success"
echo "Preparing commit for official release"
exit 0