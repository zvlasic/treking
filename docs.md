insert into races(id, name, date, inserted_at, updated_at) values (uuid_generate_v4(), 'Adria Spring trail', '2024-04-20', now(), now());

pg_dump treking_dev > after_1.sql
