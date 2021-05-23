
UPDATE pg_database SET datistemplate = FALSE WHERE datname = 'template1';
DROP DATABASE Template1;
CREATE DATABASE template1 WITH owner=postgres ENCODING = 'UTF-8' lc_collate = 'en_US.utf8' lc_ctype = 'en_US.utf8' template template0;
UPDATE pg_database SET datistemplate = TRUE WHERE datname= 'template1';

CREATE DATABASE bg WITH OWNER = postgres ENCODING = 'UTF8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;
