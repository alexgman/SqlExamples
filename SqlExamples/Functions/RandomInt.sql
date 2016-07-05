-- SUMMARY
--   Deterministically generates a pseudorandom integer. 
--
-- PARAMETERS
--   @offset : An integer to randomize.
--   @seed : A seed; for best results, should be at least 10000.
--   @max : The upper limit of the range of integers to return.
--
-- RETURNS 
--   A pseudorandom integer in between 1 and @max, inclusive.
CREATE FUNCTION [dbo].[RandomInt] ( @offset int, @seed int, @max int )
RETURNS INT
AS
BEGIN
	RETURN CAST( RAND( @offset * @seed )* @max as int ) + 1
END
