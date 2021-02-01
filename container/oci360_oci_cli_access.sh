#!/bin/sh
# v1.1

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

v_dyngroup_name_comp=$(tr '[:upper:]' '[:lower:]' <<< "${v_dyngroup_name}")

if grep -qF 'EntityAlreadyExists' <<< "${v_err}"
then
  echo 'Dynamic Group already exists. Checking if it has this instance..'
  v_dyn_group_json=$(oci iam dynamic-group list --all | jq '.data[] | select(."name" | ascii_downcase == "'${v_dyngroup_name_comp}'")')
  v_dyn_group_id=$(jq -rc '.id' <<< "${v_dyn_group_json}")
  v_dyn_group_rules=$(jq -rc '."matching-rule"' <<< "${v_dyn_group_json}")
  v_new_dyn_group_rules="$(sed 's/}//' <<< "${v_dyn_group_rules}") , instance.id='${v_instance_ocid}'}"
  if ! grep -qF "${v_instance_ocid}" <<< "${v_dyn_group_rules}"
  then
    echo 'Dynamic Group will be updated. Adding this instance on it.'
    oci iam dynamic-group update \
    --dynamic-group-id ${v_dyn_group_id} \
    --force \
    --version-date '' \
    --matching-rule "${v_new_dyn_group_rules}"
  else
    echo 'Dynamic Group already has this instance on it.'
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

# Don't change this: https://docs.cloud.oracle.com/en-us/iaas/Content/Billing/Tasks/accessingusagereports.htm
v_usage_cost_tenancy='ocid1.tenancy.oc1..aaaaaaaaned4fkpkisbwjlr56u7cj63lf3wffbilvqknstgtvzub7vhqkggq'

v_err=$(oci iam policy create \
--compartment-id "${v_tenancy_id}" \
--name "${v_policy_name}"  \
--statements \
"[
  \"define tenancy usage-report as ${v_usage_cost_tenancy}\",
  \"endorse dynamic-group ${v_dyngroup_name} to read objects in tenancy usage-report\",
  \"allow dynamic-group ${v_dyngroup_name} to read all-resources in tenancy\",
  \"allow dynamic-group ${v_dyngroup_name} to read usage-reports in tenancy\"
]" \
--description 'Policy to handle oci-cli calls from the host of OCI360.' 2>&1 >/dev/null) || true

v_policy_name_comp=$(tr '[:upper:]' '[:lower:]' <<< "${v_policy_name}")

function check_policy_exist ()
{
  # Check and add rule 3 if not in policy
  v_value="$1"
  v_pos="$2" # Position to add new rule. 1 or NULL
  v_value_comp=$(tr '[:upper:]' '[:lower:]' <<< "${v_value}")
  v_result=$(jq 'index("'"${v_value_comp}"'") // empty' <<< "$v_policy_stms_comp")
  if [ -z "${v_result}" ]
  then
    if [ "$v_pos" = "1" ]
    then
      v_new_policy_stms=$(jq '["'"${v_value}"'"] + .' <<< "${v_new_policy_stms}")
    else
      v_new_policy_stms=$(jq '. + ["'"${v_value}"'"]' <<< "${v_new_policy_stms}")
    fi
  fi
}

if grep -q -F 'PolicyAlreadyExists' <<< "${v_err}"
then
  echo 'Policy already exists. Checking if it has the required rules..'

  v_policy_json=$(oci iam policy list --compartment-id "${v_tenancy_id}" --all | jq '.data[] | select(."name" | ascii_downcase == "'${v_policy_name_comp}'")')
  v_policy_id=$(jq -rc '.id' <<< "${v_policy_json}")
  v_policy_stms=$(jq '."statements"' <<< "${v_policy_json}")
  v_policy_stms_comp=$(tr '[:upper:]' '[:lower:]' <<< "${v_policy_stms}")
  v_new_policy_stms="${v_policy_stms}"

  # Check and add rule 1 if not in policy
  v_value="allow dynamic-group ${v_dyngroup_name} to read all-resources in tenancy"
  check_policy_exist "$v_value"

  # Check and add rule 2 if not in policy
  v_value="allow dynamic-group ${v_dyngroup_name} to read usage-reports in tenancy"
  check_policy_exist "$v_value"

  # Check and add rule 3 if not in policy (in the beggining)
  v_value="define tenancy usage-report as ${v_usage_cost_tenancy}"
  check_policy_exist "$v_value" 1

  # Check and add rule 4 if not in policy
  v_value="endorse dynamic-group ${v_dyngroup_name} to read objects in tenancy usage-report"
  check_policy_exist "$v_value"

  if ! diff <(echo "${v_policy_stms}") <(echo "${v_new_policy_stms}") > /dev/null
  then
    echo 'Policy will be updated. Adding new rules on it.'
    oci iam policy update \
    --policy-id ${v_policy_id} \
    --force \
    --version-date '' \
    --statements "${v_new_policy_stms}"
  else
    echo 'Policy already has all the required rules.'
  fi
elif [ -n "${v_err}" ]
then
  echo "${v_err}"
  echo "Unable to create ${v_policy_name}."
  exit 1
fi

echo "Script finished without any error."

exit 0
####