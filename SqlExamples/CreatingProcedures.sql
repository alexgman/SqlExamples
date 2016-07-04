USE [sbucks];
GO

/****************************************************************************************************
Create sproc to retrieve the latest coffee automation id for a specific serial number and patient guid
****************************************************************************************************/

IF EXISTS( SELECT *
		   FROM sys.objects
		   WHERE object_id = OBJECT_ID(N'[dbo].[spGetcoffeeAutomationIDForSerialNumberPatient]')
			 AND type IN( N'P', N'PC' ))
DROP PROCEDURE [dbo].[spGetcoffeeAutomationIDForSerialNumberPatient];
GO
CREATE PROCEDURE [dbo].[spGetcoffeeAutomationIDForSerialNumberPatient]
	   @serialnumber NVARCHAR(7) = NULL,
	   @patientguid  UNIQUEIDENTIFIER = NULL,
	   @id           INT OUTPUT
AS
	BEGIN
		DECLARE @coffeeAutomationId INT;
		SELECT TOP 1 @coffeeAutomationId = coffeeAutomation.id
		FROM coffeeAutomation( nolock )
			 JOIN Devices ON devices.Id = coffeeAutomation.DeviceId
		WHERE devices.SerialNumber = @serialnumber
		  AND coffeeAutomation.PatientGuid = @patientguid
		ORDER BY coffeeAutomation.CreatedAt DESC;
		SELECT @id = CASE
						 WHEN @coffeeAutomationId IS NULL
						 THEN 0
						 ELSE @coffeeAutomationId
					 END;
	END;
GO

/**************************************************************************************************************
Create a sproc to accept values through parameters and create coffee automation entry records using those values
**************************************************************************************************************/

IF EXISTS( SELECT *
		   FROM sys.objects
		   WHERE object_id = OBJECT_ID(N'[dbo].[InsertcoffeeAutomationEntries]')
			 AND type IN( N'P', N'PC' ))
DROP PROCEDURE [dbo].[InsertcoffeeAutomationEntries];
GO
CREATE PROCEDURE [dbo].[InsertcoffeeAutomationEntries](
	   @TableVariable dbo.coffeeAUTOMATIONENTRYTABLETYPE READONLY )
AS
	BEGIN
		INSERT INTO coffeeAutomationEntry
			   ( [coffeeAutomationId],
				 [DataRequestTypeId],
				 [Iteration],
				 [AutomationDate],
				 [CreatedAt],
				 [CreatedBy],
				 [IsError],
				 [RequestAttempts],
				 [IsRequested],
				 [RequestDate],
				 [DataRequestId],
				 [Queued]
			   )
			   SELECT coffeeAutomationId,
					  DataRequestTypeId,
					  Iteration,
					  AutomationDate,
					  CreatedAt,
					  CreatedBy,
					  IsError,
					  RequestAttempts,
					  IsRequested,
					  RequestDate,
					  NULL,
					  Queued
			   FROM @TableVariable;
	END;
GO

/***********************************************************************************************
Create sproc to delete all coffee automation entries associated to a specific coffee automation id
***********************************************************************************************/

IF EXISTS( SELECT *
		   FROM sys.objects
		   WHERE object_id = OBJECT_ID(N'[dbo].[spDeletecoffeeAutomationEntries]')
			 AND type IN( N'P', N'PC' ))
DROP PROCEDURE [dbo].[spDeletecoffeeAutomationEntries];
GO
CREATE PROCEDURE [dbo].[spDeletecoffeeAutomationEntries]
	   @coffeeAutomationId INT = 0
AS
	BEGIN
		SET NOCOUNT OFF;
		DELETE eae
		FROM coffeeautomationentry eae
		WHERE eae.coffeeAutomationId = @coffeeAutomationId
		  AND eae.iserror = 0
		  AND eae.isrequested = 0;
		RETURN @@ROWCOUNT;
	END;
GO

/************************************************************************************************************************
Create a sproc to delete all coffee automation entries associated with a patient guid and serial number that are NOT timed
************************************************************************************************************************/

IF EXISTS( SELECT *
		   FROM sys.objects
		   WHERE object_id = OBJECT_ID(N'[dbo].[spDeleteNonTimedcoffeeAutomationEntries]')
			 AND type IN( N'P', N'PC' ))
DROP PROCEDURE [dbo].[spDeleteNonTimedcoffeeAutomationEntries];
GO
CREATE PROCEDURE [dbo].[spDeleteNonTimedcoffeeAutomationEntries]
	   @patientguid  UNIQUEIDENTIFIER = NULL,
	   @serialnumber NVARCHAR(7) = NULL
AS
	BEGIN
		SET ANSI_NULLS ON;
		SET NOCOUNT OFF;
		DELETE eae
		FROM coffeeautomationentry eae
			 JOIN coffeeautomation ea ON ea.id = eae.coffeeautomationid
			 JOIN devices d ON d.id = ea.deviceid
		WHERE eae.datarequesttypeid IN( 2, 

/***************
Minimum HR Value
***************/

			  3, 

/****************
Maximum HR Value 
****************/

			  9  

/**************
Telemed Report 
**************/

			  )
		  AND @patientguid IS NOT NULL
		  AND ea.patientguid = @patientguid
		  AND @SerialNumber IS NOT NULL
		  AND d.SerialNumber = @SerialNumber
		  AND eae.iserror = 0
		  AND eae.isrequested = 0;
		RETURN @@ROWCOUNT;
	END;
GO

/****************************************************
Give execute permissions on sprocs to sbucks username
****************************************************/

GRANT EXECUTE ON dbo.spGetcoffeeAutomationIDForSerialNumberPatient TO sbucks;
GRANT EXECUTE ON dbo.InsertcoffeeAutomationEntries TO sbucks;
GRANT EXECUTE ON dbo.spDeleteNonTimedcoffeeAutomationEntries TO sbucks;
GRANT EXECUTE ON dbo.spDeletecoffeeAutomationEntries TO sbucks;