create table repl_settings(
    name        varchar2(30),
    value       varchar2(100),
    description varchar2(1000)
)
tablespace     &&TUSERS;


create table repl_sequences(
    class_id    varchar2(16),
    attr_id     varchar2(16),
    value       number
)
tablespace     &&TUSERS;

