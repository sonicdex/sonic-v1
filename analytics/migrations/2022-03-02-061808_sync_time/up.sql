-- Your SQL goes here

create table if not exists sync_time
(
    id    int primary key not null,
    time  text            not null,
    tx_id int             not null
);

alter table bundle add timestamp text;