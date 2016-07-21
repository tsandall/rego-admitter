package io.k8s.admission

import request as req
import data.pods


############################################################
#
# Rejections
#
############################################################

admit :- not reject

reject :- deny_privileged_exec

deny_privileged_exec :-
    is_connect,
    is_exec_or_attach,
    data.pods[uid].metadata.name = req.object.Name,
    data.pods[uid].metadata.namespace = req.namespace,
    is_privileged[uid]

############################################################
#
# Overrides
#
############################################################

override[patch] :- always_pull_images[patch]

always_pull_images[{"op": "add", "path": path, "value": "Always"}] :-
    is_pod,
    is_create_or_update,
    req.object.spec.containers[i],
    format_int(i, 10, idx),
    concat("/", ["", "spec", "containers", idx, "imagePullPolicy"], path)


############################################################
#
# Helpers
#
############################################################

is_pod :- req.kind.Kind = "Pod"
is_rc :- req.kind.Kind = "ReplicationController"

is_exec :- req.object.ResourcePath = "pods/exec"
is_attach :- req.object.ResourcePath = "pods/attach"
is_exec_or_attach :- is_exec
is_exec_or_attach :- is_attach

is_privileged[pod_id] :-
    data.pods[pod_id].spec.containers[_].securityContext.privileged

is_privileged[pod_id] :-
    data.pods[pod_id].spec.initContainers[_].securityContext.privileged

is_create :- req.operation = "CREATE"
is_connect :- req.operation = "CONNECT"
is_update :- req.operation = "UPDATE"
is_create_or_update :- is_create
is_create_or_update :- is_update
