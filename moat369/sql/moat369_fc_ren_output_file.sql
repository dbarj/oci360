-- This code will check if parameter 1 has a valid file. If it does, it will put the file in the stardard name and update the input parameter with the new name.
-- Param 1 = Variable with file path

DEF in_param_ren_file = "&1."
UNDEF 1

@@&&fc_def_output_file. step_ren_file 'step_ren_file.sql'
HOS echo "DEF in_param_file_old = '&&""&&in_param_ren_file..'" > &&step_ren_file.
HOS echo "DEF in_param_file_new = '&&""&&in_param_ren_file..'" >> &&step_ren_file.
@&&step_ren_file.

HOS if [ -f &&in_param_file_old. ]; then echo "@@&&fc_seq_output_file. in_param_file_new" >> &&step_ren_file.; fi
HOS if [ -f &&in_param_file_old. ]; then echo "HOS mv &&""in_param_file_old. &&""in_param_file_new." >> &&step_ren_file.; fi
HOS if [ -f &&in_param_file_old. ]; then echo "DEF &&in_param_ren_file. = '&&""in_param_file_new.'" >> &&step_ren_file.; fi
@&&step_ren_file.

HOS rm -f &&step_ren_file.
UNDEF step_ren_file

UNDEF in_param_ren_file in_param_file_old in_param_file_new