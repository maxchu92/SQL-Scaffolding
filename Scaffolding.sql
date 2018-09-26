-- Generates POCOs/models for all tables in the current database.
-- Useful for later processing e. g. with Dapper.
-- Originally done by Alex Aza in https://stackoverflow.com/questions/5873170/generate-class-from-database-table/5873231#5873231
-- Then derived by UWEKEIM in https://pastebin.com/NUQVLmCs
-- This is the version i had derived.
-- Changes:
------ Added Using reference
------ Added Current Namespace
------ Added Partial class attribute
------ Added Folder Path
------ Added Data annotation for each property
------ Each table will now be generated into specific CS file.

-- See https://stackoverflow.com/a/5873231/107625 for the original idea
-- See http://midnightprogrammer.net/post/use-sql-query-to-writecreate-a-file for the SP to write to file.
-- See https://stackoverflow.com/a/23480936/4493976 for Split_On_Upper_Case function.
-- See https://pastebin.com/NUQVLmCs
 
DECLARE @TableName sysname
DECLARE @Result VARCHAR(MAX) = ''
DECLARE @FolderPath varchar(MAX) = 'D:\Websites\Models\'
DECLARE @UseNamespaces VARCHAR(MAX) = 'using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;'

DECLARE @namespace VARCHAR(MAX) = 'YourNamespace.Models'

DECLARE table_cursor CURSOR FOR
SELECT TABLE_NAME
FROM [INFORMATION_SCHEMA].[TABLES]
 
OPEN table_cursor
 
FETCH NEXT FROM table_cursor
INTO @tableName
 
WHILE @@FETCH_STATUS = 0
BEGIN
 
 
-- https://stackoverflow.com/a/5873231/107625
 
select @Result = @Result + @UseNamespaces + '
' + CASE WHEN @namespace <> '' THEN '
namespace ' + @namespace + ' {' ELSE '' END + '
' + CASE WHEN @namespace <> '' THEN '	' ELSE '' END + '[Table(@"' + @TableName + '")]
' + CASE WHEN @namespace <> '' THEN '	' ELSE '' END + 'public partial class ' + @TableName + ' {'
 
    select @Result = @Result + '

' + CASE WHEN @namespace <> '' THEN '	' ELSE '' END + '	' + DataAnno + '
' + CASE WHEN @namespace <> '' THEN '	' ELSE '' END + '	public ' + ColumnType + NullableSign + ' ' + ColumnName + ' { get; set; }'
            from
            (
                SELECT
					'[' + 
					CASE WHEN col.is_identity = 1
						THEN 'Key, Display(Name="ID") '
						ELSE 'Display(Name="' + REPLACE(dbo.Split_On_Upper_Case(col.name), LEFT(dbo.Split_On_Upper_Case(col.name), CHARINDEX(' ', dbo.Split_On_Upper_Case(col.name))), '') +'")'
					END				
					+ CASE WHEN col.is_nullable = 1
						THEN ''
						ELSE ', Required'
					END + ']'
					DataAnno,
                    replace(col.name, ' ', '_') ColumnName,
                    column_id ColumnId,
                    case typ.name
                        when 'bigint' then 'long'
                        when 'binary' then 'byte[]'
                        when 'bit' then 'bool'
                        when 'char' then 'string'
                        when 'date' then 'DateTime'
                        when 'datetime' then 'DateTime'
                        when 'datetime2' then 'DateTime'
                        when 'datetimeoffset' then 'DateTimeOffset'
                        when 'decimal' then 'decimal'
                        when 'float' then 'float'
                        when 'image' then 'byte[]'
                        when 'int' then 'int'
                        when 'money' then 'decimal'
                        when 'nchar' then 'string'
                        when 'ntext' then 'string'
                        when 'numeric' then 'decimal'
                        when 'nvarchar' then 'string'
                        when 'real' then 'double'
                        when 'smalldatetime' then 'DateTime'
                        when 'smallint' then 'short'
                        when 'smallmoney' then 'decimal'
                        when 'text' then 'string'
                        when 'time' then 'TimeSpan'
                        when 'timestamp' then 'DateTime'
                        when 'tinyint' then 'byte'
                        when 'uniqueidentifier' then 'Guid'
                        when 'varbinary' then 'byte[]'
                        when 'varchar' then 'string'
                        else 'UNKNOWN_' + typ.name
                    end ColumnType,
                    case
                        when col.is_nullable = 1 and typ.name in ('bigint', 'bit', 'date', 'datetime', 'datetime2', 'datetimeoffset', 'decimal', 'float', 'int', 'money', 'numeric', 'real', 'smalldatetime', 'smallint', 'smallmoney', 'time', 'tinyint', 'uniqueidentifier')
                        then '?'
                        else ''
                    end NullableSign
                from sys.columns col
                    join sys.types typ on
                        col.system_type_id = typ.system_type_id AND col.user_type_id = typ.user_type_id
                where object_id = object_id(@TableName)
            ) t
            order by ColumnId
 
            set @Result = @Result  + '
' + CASE WHEN @namespace <> '' THEN '	' ELSE '' END + '}' + CASE WHEN @namespace <> '' THEN '
}' ELSE '' END

DECLARE @filename AS VARCHAR(100) = @FolderPath + @TableName + '.cs'
	
EXEC USP_SaveFile @Result, @filename
SELECT @Result = ''
    FETCH NEXT FROM table_cursor
    INTO @tableName
END
CLOSE table_cursor
DEALLOCATE table_cursor
