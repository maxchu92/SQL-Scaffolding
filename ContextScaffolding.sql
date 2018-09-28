-- See http://midnightprogrammer.net/post/use-sql-query-to-writecreate-a-file for the SP to write to file.
-- Coded this by myself.

DECLARE @ContextName varchar(MAX) = 'DefaultContext'
DECLARE @FolderPath varchar(MAX) = 'D:\Websites\Contexts\' -- Files will be saved in the server. Please create the folder first.
DECLARE @UseNamespaces VARCHAR(MAX) = 'using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using MyNamespace.Models;'

DECLARE @namespace VARCHAR(MAX) = 'MyNamespace.Contexts'
DECLARE @varTables AS VARCHAR(MAX) = ''
SELECT  @varTables =  COALESCE(@varTables + CHAR(13) + CHAR(9) + CASE @namespace WHEN '' THEN '' ELSE CHAR(9) END + 'public DbSet<' + TABLE_NAME + '> ' + TABLE_NAME + ' { get; set; }', 'public DbSet<' + TABLE_NAME + '> ' + TABLE_NAME + ' { get; set; }')
FROM [INFORMATION_SCHEMA].[TABLES]
ORDER BY TABLE_NAME 

DECLARE @Result AS VARCHAR(MAX) = @UseNamespaces + CHAR(13) + CHAR(13) + CASE @namespace WHEN '' THEN '' ELSE 'namespace ' + @namespace + ' {'  + CHAR(13) + CHAR(9) END
+ 'public partial class ' + @ContextName + ' : DbContext {' + @varTables + CHAR(13) + CHAR(13)
+ CASE @namespace WHEN '' THEN '' ELSE CHAR(9) END + CHAR(9) + 'protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder) {' + CHAR(13)
+ CASE @namespace WHEN '' THEN '' ELSE CHAR(9) END + CHAR(9) + CHAR(9) + 'if (!optionsBuilder.IsConfigured) {' + CHAR(13)
+ CASE @namespace WHEN '' THEN '' ELSE CHAR(9) END + CHAR(9) + CHAR(9) + CHAR(9) + 'optionsBuilder.UseSqlServer(Startup.Configuration.GetConnectionString("DefaultConnection"));' + CHAR(13)
+ CASE @namespace WHEN '' THEN '' ELSE CHAR(9) END + CHAR(9) + CHAR(9) + '}' + CHAR(13)
+ CASE @namespace WHEN '' THEN '' ELSE CHAR(9) + CHAR(9) + '}' + CHAR(13) END
+ CHAR(9) + '}' + CHAR(13)
+'}'

DECLARE @filename AS VARCHAR(100) = @FolderPath + @ContextName + '.cs'

EXEC USP_SaveFile @Result, @filename
--PRINT @Result
