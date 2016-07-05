USE vt;
GO

SET XACT_ABORT ON;
GO

BEGIN TRANSACTION;
GO

IF OBJECT_ID('vt.dbo.spGetLastPatientGuidForDevice') IS NOT NULL
DROP PROCEDURE [spGetLastPatientGuidForDevice];
GO

IF OBJECT_ID('tempdb..#tmpErrors') IS NOT NULL 
DROP TABLE #tmpErrors
GO

CREATE TABLE #tmpErrors( [Error] nvarchar(200) NOT NULL );
GO
-- =============================================
-- Author:        Alex Gordon
-- Create date:   01/27/2015
-- Description:   Returns the last patient guid associated with the given serial number
-- =============================================
CREATE PROCEDURE [dbo].[spGetLastPatientGuidForDevice]
       @serialnumber NVARCHAR(7) = NULL
AS
    BEGIN
        RETURN SELECT TOP 1 dr.patientguid
               FROM [DataRequest] dr
                    JOIN Devices d ON d.Id = dr.DeviceId
               WHERE d.SerialNumber = @serialnumber
               ORDER BY dr.CreatedAt DESC;
    END;
GO
IF @@Error <> 0 AND @@TranCount > 0 ROLLBACK TRANSACTION;
GO

IF @@TranCount = 0
    BEGIN
        INSERT INTO #tmpErrors ( Error )
               SELECT 'Unable to create spGetLastPatientGuidForDevice';
        BEGIN TRANSACTION;
    END;
GO

IF OBJECT_ID('vt.dbo.spDeleteEventAutomationEntryData') IS NOT NULL
DROP PROCEDURE [spDeleteEventAutomationEntryData];
GO

-- =============================================
-- Author:        Alex Gordon
-- Create date:   01/12/2015
-- Description:   Deletes from EventAutomationEntry 
--                    based on the patientguid and serialnumber
-- =============================================
CREATE PROCEDURE [dbo].[spDeleteEventAutomationEntryData]
       @patientguid  UNIQUEIDENTIFIER = NULL,
       @serialnumber NVARCHAR(7) = NULL
AS
    BEGIN
        SET NOCOUNT ON;
        DELETE eae
        FROM eventautomationentry eae
             JOIN eventautomation ea ON ea.id = eae.eventautomationid
             JOIN devices d ON d.id = ea.deviceid
        WHERE ea.patientguid = ISNULL(@patientguid, '')
          AND d.serialnumber = ISNULL(@SerialNumber, '')
          AND eae.iserror = 0
          AND eae.isrequested = 0;
    END;
GO
IF @@Error <> 0 AND @@TranCount > 0 ROLLBACK TRANSACTION;
GO
IF @@TranCount = 0
    BEGIN
        INSERT INTO #tmpErrors ( Error )
               SELECT 'Unable to create spDeleteEventAutomationEntryData';
        BEGIN TRANSACTION;
    END;
GO
IF NOT EXISTS( SELECT * FROM #tmpErrors )
    BEGIN
        PRINT 'The database update succeeded';
        IF @@TRANCOUNT > 0 COMMIT TRANSACTION;
    END;
ELSE
    BEGIN
        PRINT 'The database update failed';
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END;
GO
DROP TABLE #tmpErrors;
GO