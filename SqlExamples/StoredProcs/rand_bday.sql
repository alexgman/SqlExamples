/*********************************************************************************************
***** Object:  UserDefinedFunction [dbo].[rand_bday]    Script Date: 08/28/2015 15:38:30 *****
*********************************************************************************************/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE FUNCTION [Dbo].[Rand_Bday](
                @Birthday   DATE,
                @Enrollment DATE,
                @Patientid  INT )
RETURNS DATE
AS
     BEGIN
         DECLARE @From DATE;
         DECLARE @To DATE;
         DECLARE @Randint INT;
         SET @Randint = LOG(@Patientid) * 1000 * ( SELECT [Random_Value]
                                                   FROM [Wrapped_Rand_View] );

/******************************************
The user has no birthday or enrollment date
******************************************/
         IF @Birthday IS NULL
         OR @Enrollment IS NULL
             BEGIN
                 RETURN NULL;
             END;

/************************************************************
Patient is 16 years of age or older at the time of enrollment
************************************************************/
             IF DATEADD(year, 16, @Birthday) <= @Enrollment
                 BEGIN
                     SET @From = DATEADD(year, -90, @Enrollment);
                     SET @To = DATEADD(year, -16, @Enrollment);
                 END;

/*************************
Patient is younger than 16
*************************/
             ELSE
                 BEGIN
                     SET @From = DATEADD(year, -16, @Enrollment);
                     SET @To = DATEADD(day, -1, @Enrollment);
                 END;
                 RETURN DATEADD([D], ROUND(DATEDIFF([D], @From, @To) * 1 / @Randint, 0), @From);
             END;