#!/bin/sh
# v1.0
# Create oci-cli instance_principal access for OCI360
# Only use this script if the tenancy you are running OCI360 is the same you want to get the info.

set -eo pipefail

echo -n "OCI360 Instance OCID: "
read v_instance_ocid
[ -z "${v_instance_ocid}" ] && echo "Instance OCID can't be null." && exit 1

v_dyngroup_def_name='OCI360_DG'
echo -n "Dynamic Group Name [${v_dyngroup_def_name}]: "
read v_dyngroup_name
[ -z "${v_dyngroup_name}" ] && v_dyngroup_name="${v_dyngroup_def_name}"

v_dyngroup_def_name='OCI360_Policy'
echo -n "Policy Name [${v_policy_def_name}]: "
read v_policy_name
[ -z "${v_policy_name}" ] && v_policy_name="${v_dyngroup_def_name}"

oci iam dynamic-group create \
--name "${v_dyngroup_name}" \
--matching-rule "instance.id = '${v_instance_ocid}'" \
--description 'Group to handle oci-cli calls from the host of OCI360.'

v_tenancy_id=$(oci iam compartment list \
--all \
--compartment-id-in-subtree true \
--access-level ACCESSIBLE \
--include-root \
--raw-output \
--query "data[?contains(\"id\",'tenancy')].id | [0]")

oci iam policy create \
--compartment-id "${v_tenancy_id}" \
--name "${v_policy_name}"  \
--statements \
"[
  \"allow dynamic-group ${v_dyngroup_name} to read all-resources in tenancy\" ,
  \"allow dynamic-group ${v_dyngroup_name} to read usage-reports in tenancy\"
]" \
--description 'Policy to handle oci-cli calls from the host of OCI360.'

exit 0
####