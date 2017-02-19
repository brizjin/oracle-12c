def

accept OK_FLAG char format a30 prompt 'Are Settings OK? [YES]: ' default YES

@@exit_when "nvl(upper('&&OK_FLAG'), 'N') <> 'YES'"
