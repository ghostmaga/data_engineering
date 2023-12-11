------------------------------------------------------------------------------------------------

-- Breakdown of the space consumption and duration for each operation performed on the 'table_to_delete' table

------------------------------------------------------------------------------------------------

    CREATE TABLE table_to_delete AS
    SELECT 'veeeeeeery_long_string' || x AS col
    FROM generate_series(1, (10^7)::int) x;

--      Initial Creation:
-- Operation: Creation of 'table_to_delete' and population with 10 million rows.
-- Initial size: 602611712 bytes (575 MB)
-- Creation time: 45175 ms (45.175 seconds)

------------------------------------------------------------------------------------------------

    DELETE FROM table_to_delete
    WHERE REPLACE(col, 'veeeeeeery_long_string', '')::int % 3 = 0;

--      After DELETE Operation:
-- Operation: Deleted approximately one-third of rows based on a specific condition.
-- Size remained the same: 602611712 bytes (575 MB)
-- Delete time: 10877 ms (10.877 seconds)
-- Although the DELETE operation removed approximately one-third of the rows based on a specific condition, it did not immediately reduce the table's physical size. PostgreSQL marks the space of deleted rows as available for reuse but doesn't immediately release it to the operating system.

------------------------------------------------------------------------------------------------

    VACUUM FULL VERBOSE table_to_delete;

--      After VACUUM FULL:
-- Operation: Executed VACUUM FULL VERBOSE on 'table_to_delete'.
-- Post-vacuum size: 401637376 bytes (383 MB)
-- Vacuum time: 30000 ms (30 seconds)
-- The operation actively reclaims space, optimizing storage by physically compacting the table, resulting in reduced fragmentation and improved performance. However, VACUUM might not always reduce the physical file size on the disk immediately, especially in cases where there's significant internal fragmentation or when there are still live tuples in the table.

------------------------------------------------------------------------------------------------

    TRUNCATE table_to_delete;

--      After TRUNCATE Operation:
-- Operation: Performed TRUNCATE on recreated 'table_to_delete'.
-- Post-truncate size: 8192 bytes
-- Truncate time: 1 second
-- TRUNCATE efficiently removes all rows from the table, leaving only the table structure, resulting in a minimal size of 8192 bytes. It releases all space immediately back to the filesystem because TRUNCATE is a DDL command.

------------------------------------------------------------------------------------------------

--      Summary: 
--The DELETE operation didn't immediately reclaim space because PostgreSQL marks the space as available for future use but doesn’t return it to the operating system. VACUUM FULL actively reclaims this space, resulting in a reduced size. TRUNCATE, being a full table truncate, resets the table back to minimal size by removing all rows, essentially leaving just the table structure intact.