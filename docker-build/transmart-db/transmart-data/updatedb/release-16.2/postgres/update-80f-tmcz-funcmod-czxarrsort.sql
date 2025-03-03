--
-- Cleanup DOS line endings
--

set search_path = tm_cz, pg_catalog;

DROP FUNCTION IF EXISTS tm_cz.czx_array_sort(anyarray);

\i ../../../ddl/postgres/tm_cz/functions/czx_array_sort.sql

ALTER FUNCTION tm_cz.czx_array_sort(anyarray) SET search_path TO tm_cz, tm_lz, tm_wz, i2b2demodata, i2b2metadata, deapp, pg_temp;

