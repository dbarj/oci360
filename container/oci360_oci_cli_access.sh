#!/bin/sh
# v1.0

# Create oci-cli instance_principal access for OCI360
# Only use this script if the tenancy you are running OCI360 is the same you want to get the info.
# Run this script from Cloud Shell with Administrator account.

set -eo pipefail

echo -n "OCI360 Instance OCID: "
read v_instance_ocid
[ -z "${v_instance_ocid}" ] && echo "Instance OCID can't be null." && exit 1

v_dyngroup_def_name='OCI360_DG'
echo -n "Dynamic Group Name for OCI360 [${v_dyngroup_def_name}]: "
read v_dyngroup_name
[ -z "${v_dyngroup_name}" ] && v_dyngroup_name="${v_dyngroup_def_name}"

v_policy_def_name='OCI360_Policy'
echo -n "Policy Name for OCI360 [${v_policy_def_name}]: "
read v_policy_name
[ -z "${v_policy_name}" ] && v_policy_name="${v_policy_def_name}"

v_err=$(oci iam dynamic-group create \
--name "${v_dyngroup_name}" \
--matching-rule "instance.id = '${v_instance_ocid}'" \
--description 'Group to handle oci-cli calls from the host of OCI360.' 2>&1 >/dev/null) || true

if grep -q -F 'EntityAlreadyExists' <<< "${v_err}"
then
  v_dyn_group_json=$(oci iam dynamic-group list --all | jq '.data[] | select(."name" == "'${v_dyngroup_name}'")')
  v_dyn_group_id=$(jq -rc '.id' <<< "${v_dyn_group_json}")
  v_dyn_group_rules=$(jq -rc '."matching-rule"' <<< "${v_dyn_group_json}")
  v_new_dyn_group_rules="$(sed 's/}//' <<< "${v_dyn_group_rules}") , instance.id='${v_instance_ocid}'}"
  if ! grep -q -F "${v_instance_ocid}" <<< "${v_new_dyn_group_rules}"
  then
    echo 'Dynamic Group already exists. Adding this instance on it.'
    oci iam dynamic-group update \
    --dynamic-group-id ${v_dyn_group_id} \
    --force \
    --matching-rule "${v_new_dyn_group_rules}"
  else
    echo 'Dynamic Group already exists with this tenancy on it.'
  fi
elif [ -n "${v_err}" ]
then
  echo "${v_err}"
  echo "Unable to create ${v_dyngroup_name}."
  exit 1
fi

v_tenancy_id=$(oci iam compartment list \
--all \
--compartment-id-in-subtree true \
--access-level ACCESSIBLE \
--include-root \
--raw-output \
--query "data[?contains(\"id\",'tenancy')].id | [0]")

v_err=$(oci iam policy create \
--compartment-id "${v_tenancy_id}" \
--name "${v_policy_name}"  \
--statements \
"[
  \"allow dynamic-group ${v_dyngroup_name} to read all-resources in tenancy\" ,
  \"allow dynamic-group ${v_dyngroup_name} to read usage-reports in tenancy\"
]" \
--description 'Policy to handle oci-cli calls from the host of OCI360.' 2>&1 >/dev/null) || true

if grep -q -F 'PolicyAlreadyExists' <<< "${v_err}"
then
  echo 'Policy already exists.'
elif [ -n "${v_err}" ]
then
  echo "${v_err}"
  echo "Unable to create ${v_dyngroup_name}."
  exit 1
fi

echo "Script finished without any error."

exit 0
####