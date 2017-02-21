echo Loading data...
sqlldr %1 entries.ctl
sqlldr %1 params.ctl
sqlldr %1 parser.ctl
sqlldr %1 messages.ctl
sqlldr %1 project.ctl
sqlldr %1 update_journal.ctl ERRORS=100000
