-- Generates POCOs/models for all tables in the current database.
-- Useful for later processing e. g. with Dapper.
--
-- See https://stackoverflow.com/a/5873231/107625 for the original idea
-- See http://midnightprogrammer.net/post/use-sql-query-to-writecreate-a-file for the SP to write to file.
 
DECLARE @TableName sysname
DECLARE @Result VARCHAR(MAX) = ''
DECLARE @FolderPath varchar(MAX) = 'D:\Websites\Models\' -- Please create the folder before save. Files will be saved into the Database host.
DECLARE @UseNamespaces VARCHAR(MAX) = 'using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using DapEx = Dapper.Contrib.Extensions;'

DECLARE @namespace VARCHAR(MAX) = 'YourNamespace.Models'

DECLARE table_cursor CURSOR FOR
SELECT TABLE_NAME
FROM [INFORMATION_SCHEMA].[TABLES]
 
OPEN table_cursor
 
FETCH NEXT FROM table_cursor
INTO @tableName
 
WHILE @@FETCH_STATUS = 0
BEGIN
 
SELECT @Result = @Result + @UseNamespaces + CHAR(13)
+ CASE @namespace WHEN '' THEN '' ELSE CHAR(13) + 'namespace ' + @namespace + ' {' + CHAR(13) END + CHAR(13)
+ CASE @namespace WHEN '' THEN '' ELSE CHAR(9) END + '[Table(@"' + @TableName + '"), DapEx.Table(@"' + @TableName + '")]' + CHAR(13)
+ CASE @namespace WHEN '' THEN '' ELSE CHAR(9) END + 'public partial class ' + @TableName + ' {' + CHAR(13) + CHAR(13)
 
SELECT @Result = @Result
+ CASE @namespace WHEN '' THEN '' ELSE CHAR(9) END + CHAR(9) + CASE WHEN t.DataAnno LIKE '' THEN '' ELSE '[' + DataAnno + ']' END + CHAR(13)
+ CASE @namespace WHEN '' THEN '' ELSE CHAR(9) END + CHAR(9) + 'public ' + ColumnType + NullableSign + ' ' + ColumnName + ' { get; set; }' + CHAR(13) + CHAR(13)
	FROM (
		SELECT
			ISNULL(STUFF(
				CASE
					WHEN ISNULL(i.is_primary_key, 0) = 1 THEN ', Key, DapEx.Key'
					WHEN typ.name LIKE 'timestamp'
						THEN ', Timestamp'
					ELSE
						CONCAT(
							CASE col.is_identity WHEN 1
								THEN ', DatabaseGenerated(DatabaseGeneratedOption.Identity)'
								ELSE ''
							END,
							CASE col.is_computed WHEN 1
								THEN ', DatabaseGenerated(DatabaseGeneratedOption.Computed), DapEx.Computed'
								ELSE ''
							END,
							CASE col.is_nullable WHEN 1
								THEN ''
								ELSE ', Required'
							END
						)
				END
			, 1, 2, ''), '') DataAnno,
			REPLACE(col.name, ' ', '_') ColumnName,
			col.column_id ColumnId,
			CASE typ.name
				WHEN 'bigint' THEN 'long'
				WHEN 'binary' THEN 'byte[]'
				WHEN 'bit' THEN 'bool'
				WHEN 'char' THEN 'string'
				WHEN 'date' THEN 'DateTime'
				WHEN 'datetime' THEN 'DateTime'
				WHEN 'datetime2' THEN 'DateTime'
				WHEN 'datetimeoffset' THEN 'DateTimeOffset'
				WHEN 'decimal' THEN 'decimal'
				WHEN 'float' THEN 'float'
				WHEN 'image' THEN 'byte[]'
				WHEN 'int' THEN 'int'
				WHEN 'money' THEN 'decimal'
				WHEN 'nchar' THEN 'string'
				WHEN 'ntext' THEN 'string'
				WHEN 'numeric' THEN 'decimal'
				WHEN 'nvarchar' THEN 'string'
				WHEN 'real' THEN 'double'
				WHEN 'smalldatetime' THEN 'DateTime'
				WHEN 'smallint' THEN 'short'
				WHEN 'smallmoney' THEN 'decimal'
				WHEN 'text' THEN 'string'
				WHEN 'time' THEN 'TimeSpan'
				WHEN 'timestamp' THEN 'byte[]'
				WHEN 'tinyint' THEN 'byte'
				WHEN 'uniqueidentifier' THEN 'Guid'
				WHEN 'varbinary' THEN 'byte[]'
				WHEN 'varchar' THEN 'string'
				ELSE 'UNKNOWN_' + typ.name
			END ColumnType,
			case
				WHEN col.is_nullable = 1 and typ.name in ('bigint', 'bit', 'date', 'datetime', 'datetime2', 'datetimeoffset', 'decimal', 'float', 'int', 'money', 'numeric', 'real', 'smalldatetime', 'smallint', 'smallmoney', 'time', 'tinyint', 'uniqueidentifier')
				THEN '?'
				ELSE ''
			END NullableSign
		FROM sys.columns col
		JOIN sys.types typ ON col.system_type_id = typ.system_type_id AND col.user_type_id = typ.user_type_id
		LEFT OUTER JOIN sys.index_columns ic ON ic.object_id = col.object_id AND ic.column_id = col.column_id
		LEFT OUTER JOIN sys.indexes i ON ic.object_id = i.object_id AND ic.index_id = i.index_id
		WHERE col.object_id = object_id(@TableName)
	) t
	ORDER BY ColumnId
SET @Result = @Result + CASE @namespace WHEN '' THEN '' ELSE CHAR(9) + '}' + CHAR(13) END
+ '}'

DECLARE @filename AS VARCHAR(100) = @FolderPath + @TableName + '.cs'

EXEC USP_SaveFile @Result, @filename
SELECT @Result = ''
	FETCH NEXT FROM table_cursor
	INTO @tableName
END
CLOSE table_cursor
DEALLOCATE table_cursor
