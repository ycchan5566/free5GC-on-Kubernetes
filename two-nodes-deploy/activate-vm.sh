#!/bin/bash

set -e

if [ -z "${TMUX}" ]; then
  tmux new-session -d -s K8s
  SESSION="K8s"
else
  SESSION="$(tmux display-message -p '#S')"
fi
tmux new-window -a -t $SESSION -n 'node1'
tmux new-window -a -d -t $SESSION -n 'node2'
tmux send-keys -t $SESSION:node1 'vagrant up node1' C-m
tmux send-keys -t $SESSION:node2 'vagrant up node2' C-m
