create table messages (
    topic varchar2(16),
    code  varchar2(30),
    text  varchar2(2000)
)
 pctfree    10
 pctused    40
 initrans   1
 maxtrans   255
 tablespace &&TUSER;

create unique index pk_messages_topic_code
    on messages(topic,code) tablespace &&TSPACEI;

alter table messages add
    constraint pk_messages_topic_code primary key(topic,code);

create table notifications (
    owner   varchar2(30),
    event   varchar2(30),
    status  varchar2(16),
    subject varchar2(30),
    message varchar2(30),
    sender  varchar2(64),
    name    varchar2(200),
    description varchar2(1000)
)
 pctfree    10
 pctused    40
 initrans   1
 maxtrans   255
 tablespace &&TUSER;

create unique index pk_notifications_owner_event
    on notifications(owner,event) tablespace &&TSPACEI;

alter table notifications add
    constraint pk_notifications_owner_event primary key(owner,event);

create table recipients (
    owner   varchar2(30),
    event   varchar2(30),
    email   varchar2(64),
    status  varchar2(16),
    name    varchar2(200)
)
 pctfree    10
 pctused    40
 initrans   1
 maxtrans   255
 tablespace &&TUSER;

create unique index pk_recipients
    on recipients(owner,event,email) tablespace &&TSPACEI;

alter table recipients add
    constraint pk_recipients primary key(owner,event,email);

alter table recipients add
    constraint fk_recipients_owner_event foreign key(owner,event)
    references notifications(owner,event) on delete cascade;

