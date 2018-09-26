# SQL-Scaffolding
SQL Script for C# Model scaffolding

Generates POCOs/models for all tables in the current database.
Useful for later processing e. g. with Dapper.

Original idea done by Alex Aza. Then, derived by UWEKEIM.

This is the version i had derived.
Changes:
- Added Using reference
- Added Current Namespace
- Added Partial class attribute
- Added Folder Path
- Added Data annotation for each property
- Each table will now be generated into specific CS file.

See https://stackoverflow.com/a/5873231/107625 for the original idea.

See http://midnightprogrammer.net/post/use-sql-query-to-writecreate-a-file for the SP to write to file.

See https://stackoverflow.com/a/23480936/4493976 for Split_On_Upper_Case function.

See https://pastebin.com/NUQVLmCs derived by UWEKEIM.
