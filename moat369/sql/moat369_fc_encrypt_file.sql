-- This code will check if parameter 1 has a valid file. If it does, it will encrypt the file and update the input parameter with the new name.
DEF in_param = "&1."
UNDEF 1

@@&&fc_def_output_file. step_file 'step_file.sql'
HOS echo "DEF in_param_content = '&&""&&in_param..'" > &&step_file.
@&&step_file.

DEF out_enc_file = '&&in_param_content..enc'

HOS openssl smime -encrypt -binary -aes-256-cbc -in &&in_param_content. -out &&out_enc_file. -outform DER &&moat369_enc_pub_file.
HOS if [ -f &&out_enc_file. ]; then rm -f &&in_param_content.; fi
HOS if [ -f &&out_enc_file. ]; then echo "DEF &&in_param. = '&&""out_enc_file.'" > &&step_file.; fi
@&&step_file.

HOS rm -f &&step_file.
UNDEF step_file

UNDEF in_param in_param_content out_enc_file