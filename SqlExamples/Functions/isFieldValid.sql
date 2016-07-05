/*********************************************************************************
This function will check whether a specified field exists within a specified table
*********************************************************************************/
CREATE FUNCTION [dbo].[isFieldValid]
   (
                @checkfield varchar(100),
                @server     nvarchar(100),
                @database   nvarchar(100),
                @schema     nvarchar(100),
                @table      nvarchar(100) 
   ) 
RETURNS varchar(5) 
AS
BEGIN


    IF EXISTS
       (SELECT 1
        FROM [information_schema].[columns]
        WHERE
                    [table_name] = @table
                AND [table_schema] = @schema
                AND [column_name] = @checkfield
       )  
    RETURN 'TRUE';
    
    RETURN 'FALSE';
    END;