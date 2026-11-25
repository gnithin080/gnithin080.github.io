-- SQL Server. Load contacts.csv into dbo.Contacts using the CSV headers.
-- Import IDs and all other columns as text; RecordID must be unique.
WITH active AS (
 SELECT *, NULLIF(LOWER(TRIM(RegistrationID)), '') AS RegKey,
 NULLIF(LOWER(TRIM(Email)), '') AS EmailKey,
 NULLIF(LOWER(TRIM(ContactSegment)), '') AS ContactKey,
 NULLIF(LOWER(TRIM(CompanySegment)), '') AS CompanyKey
 FROM dbo.Contacts WHERE Status = 'Active'
), counted AS (
 SELECT *, COUNT(*) OVER(PARTITION BY RegKey) AS RegCount,
 COUNT(*) OVER(PARTITION BY EmailKey) AS EmailCount FROM active
)
SELECT RecordID, v.IssueType
FROM counted CROSS APPLY (VALUES
 ('Missing registration ID', CASE WHEN IsAdvisor='Yes' AND RegKey IS NULL THEN 1 ELSE 0 END),
 ('Duplicate registration ID', CASE WHEN RegKey IS NOT NULL AND RegCount>1 THEN 1 ELSE 0 END),
 ('Duplicate email', CASE WHEN EmailKey IS NOT NULL AND EmailCount>1 THEN 1 ELSE 0 END),
 ('Segment mismatch', CASE WHEN ContactKey IS NOT NULL AND CompanyKey IS NOT NULL AND ContactKey<>CompanyKey THEN 1 ELSE 0 END),
 ('Incomplete contact', CASE WHEN NULLIF(TRIM(FullName),'') IS NULL OR EmailKey IS NULL THEN 1 ELSE 0 END)
) v(IssueType,Failed) WHERE v.Failed=1;
