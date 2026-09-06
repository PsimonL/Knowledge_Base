#!/bin/bash

# Set the worker node names
worker_node_names=("k8s-worker-201" "k8s-worker-202")

# Run the kubectl command to label the worker nodes
for node_name in "${worker_node_names[@]}"; do
    sudo -u vagrant kubectl label nodes "$node_name" roles=worker
done
