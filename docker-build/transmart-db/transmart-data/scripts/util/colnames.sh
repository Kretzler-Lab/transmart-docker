#!/bin/bash -e

# colnames.sh <schema> <table>
# print the column names for a table comma separated

$PGSQL_BIN/psql -t <<EOD
SELECT
    array_to_string(array_accum(D.x), ', ')
FROM (
        SELECT
            CASE
                WHEN pg_catalog.format_type(
                    a.atttypid,
                    a.atttypmod) = 'boolean'
				THEN a.attname || '::int'
                ELSE a.attname
            END
FROM
    pg_catalog.pg_attribute a
WHERE
    a.attrelid = (
        SELECT
            c.OID
		FROM
			pg_catalog.pg_class c
			LEFT JOIN pg_catalog.pg_namespace n ON n.OID = c.relnamespace
		WHERE
			c.relname = '$2'
			AND n.nspname = '$1')
    AND a.attnum > 0
    AND NOT a.attisdropped
ORDER BY
    a.attnum) D(x);
EOD
