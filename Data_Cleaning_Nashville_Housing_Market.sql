/*
Clean Data Using SQL 
Armaan Singh Pandher 
3/10/2023
*/

SELECT * FROM ProjectPortfolio01..Nashville_Housing_Data

-----------------------------------------------------------------------------------------------------------------------------------------------------
--Standardize Data Format
-----------------------------------------------------------------------------------------------------------------------------------------------------

SELECT SaleDate,CONVERT(varchar,SaleDate,103)
FROM ProjectPortfolio01..Nashville_Housing_Data
ORDER BY CONVERT(varchar,SaleDate,103) DESC
/*
CONVERT function, which takes three arguments: 
	the data type to convert to, 
	the expression to convert, 
	and an optional style parameter that specifies the format of the date. (only works if you convert to varchar)
For example, to convert the current datetime value to a date value in the US format (mm/dd/yyyy)
*/
--Using CAST
SELECT SaleDate,CAST(SaleDate AS date) as 'New_date'
FROM ProjectPortfolio01..Nashville_Housing_Data

--Using TRY_CONVERT
/*
TRY_CONVERT function, which is similar to the CONVERT function, but returns NULL if the conversion fails. 
*/

SELECT SaleDate,TRY_CONVERT(date,SaleDate,103) as 'New_date'
FROM ProjectPortfolio01..Nashville_Housing_Data
--WHERE TRY_CONVERT(date,SaleDate) is NULL


-----------------------------------------------------------------------------------------------------------------------------------------------------
--Update the date values in table
-----------------------------------------------------------------------------------------------------------------------------------------------------

--UPDATE Nashville_Housing_Data
--SET SaleDate=CONVERT(date,SaleDate)

--UPDATE Nashville_Housing_Data
--SET SaleDate=CAST(SaleDate AS date)

--The above commands dont seem to work even though they are running successfully 

ALTER TABLE ProjectPortfolio01..Nashville_Housing_Data
ALTER COLUMN saledate date

SELECT SaleDate
FROM ProjectPortfolio01..Nashville_Housing_Data


-----------------------------------------------------------------------------------------------------------------------------------------------------
--Property Address-Dealing with NULL values
-----------------------------------------------------------------------------------------------------------------------------------------------------

--SELECT COUNT(*) 
SELECT * 
FROM ProjectPortfolio01..Nashville_Housing_Data
--WHERE PropertyAddress is NULL
Order BY ParcelID

SELECT ParcelID, PropertyAddress
FROM ProjectPortfolio01..Nashville_Housing_Data
--WHERE PropertyAddress is NULL
GROUP BY ParcelID,PropertyAddress
Order BY ParcelID

/*
When we group the data based on parcelid and property address we realise that properties with same 
parcelid have the same address.
Since property address to change over time is very rare since the property is physically not going to move
we can safely fill the parcelid propertyaddress where the id is same 
*/

--Lets use COALESCE/ISNULL function to tke the first not NULL value from the two property address columns
SELECT dba1.ParcelID, dba1.PropertyAddress
		,dba2.ParcelID, dba2.PropertyAddress
		,COALESCE(dba1.PropertyAddress,dba2.PropertyAddress) as Update_address
FROM ProjectPortfolio01..Nashville_Housing_Data as dba1
JOIN ProjectPortfolio01..Nashville_Housing_Data as dba2
	ON dba1.ParcelID=dba2.ParcelID
	AND dba1.[UniqueID ]<>dba2.[UniqueID ]
	--So that we are taking different row entries for the same parcelid
WHERE dba1.PropertyAddress is NULL
/*
We can also use ISNULL(col1_which_might_be_null,col2_which_is_not_null)
instead of COALESCE but ISNULL is specific to SQL Server while COALESCE is not.
*/


--Make Updates in the Data

UPDATE dba1
SET dba1.PropertyAddress=
	COALESCE(dba1.PropertyAddress,dba2.PropertyAddress)   
	FROM ProjectPortfolio01..Nashville_Housing_Data as dba1
	JOIN ProjectPortfolio01..Nashville_Housing_Data as dba2
		ON dba1.ParcelID=dba2.ParcelID
		AND dba1.[UniqueID ]<>dba2.[UniqueID ]
	WHERE dba1.PropertyAddress is NULL


--SELECT * from ProjectPortfolio01..Nashville_Housing_Data
--WHERE PropertyAddress is NULL


-----------------------------------------------------------------------------------------------------------------------------------------------------
--Property Address-Extracting cities from address
-----------------------------------------------------------------------------------------------------------------------------------------------------

SELECT PropertyAddress
FROM ProjectPortfolio01..Nashville_Housing_Data
--If you have noticed a comma is used in the address and text after the comma is our city here 

SELECT PropertyAddress,CHARINDEX(',',PropertyAddress) as deliminator_index
		,LEN(PropertyAddress)-CHARINDEX(',',PropertyAddress) as city_text_length
		,SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1) as Address_without_city
		,SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress)-CHARINDEX(',',PropertyAddress)) as city
FROM ProjectPortfolio01..Nashville_Housing_Data

--Im just playing around with different functions you just need the last two columns for the data cleanning purposes

ALTER TABLE ProjectPortfolio01..Nashville_Housing_Data
ADD  PropertySlitAddress nvarchar(255);

--SELECT * from ProjectPortfolio01..Nashville_Housing_Data

EXEC sp_rename 'ProjectPortfolio01..Nashville_Housing_Data.PropertySlitAddress','PropertySplitAddress','COLUMN'
--Had to change my column name since there was a spelling mistake

UPDATE ProjectPortfolio01..Nashville_Housing_Data
SET PropertySplitAddress = SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1)

ALTER TABLE ProjectPortfolio01..Nashville_Housing_Data
ADD  PropertySplitCity varchar(255);

UPDATE ProjectPortfolio01..Nashville_Housing_Data
SET PropertySplitCity= SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress))

-----------------------------------------------------------------------------------------------------------------------------------------------------
--Property Address-Extracting cities from address
-----------------------------------------------------------------------------------------------------------------------------------------------------

--Parse name splits based on '.' and not','
SELECT OwnerAddress,
	PARSENAME(REPLACE(OwnerAddress,',','.'),3)
	,PARSENAME(REPLACE(OwnerAddress,',','.'),2)
	,PARSENAME(REPLACE(OwnerAddress,',','.'),1)
FROM ProjectPortfolio01..Nashville_Housing_Data


ALTER TABLE ProjectPortfolio01..Nashville_Housing_Data
ADD OwnerSplitState varchar(255);

ALTER TABLE ProjectPortfolio01..Nashville_Housing_Data
ADD  OwnerSplitCity varchar(255);

ALTER TABLE ProjectPortfolio01..Nashville_Housing_Data
ADD OwnerSplitaddress nvarchar(255);

UPDATE ProjectPortfolio01..Nashville_Housing_Data
SET OwnerSplitState =PARSENAME(REPLACE(OwnerAddress,',','.'),1)


UPDATE ProjectPortfolio01..Nashville_Housing_Data
SET OwnerSplitCity =PARSENAME(REPLACE(OwnerAddress,',','.'),2)


UPDATE ProjectPortfolio01..Nashville_Housing_Data
SET OwnerSplitaddress =PARSENAME(REPLACE(OwnerAddress,',','.'),3)

--Select * FROM ProjectPortfolio01..Nashville_Housing_Data


-----------------------------------------------------------------------------------------------------------------------------------------------------
--SoldAsVacant Data validation (Only Yes No values allowed)
-----------------------------------------------------------------------------------------------------------------------------------------------------

SELECT DISTINCT SoldAsVacant,COUNT(SoldAsVacant)
FROM ProjectPortfolio01..Nashville_Housing_Data
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant,
CASE
WHEN SoldAsVacant='Y' THEN 'Yes'
WHEN SoldAsVacant='N' THEN 'No'
ELSE SoldAsVacant
END as update_SoldAsVacant
FROM ProjectPortfolio01..Nashville_Housing_Data
WHERE SoldAsVacant='N' 

UPDATE ProjectPortfolio01..Nashville_Housing_Data
SET SoldAsVacant=
	CASE
	WHEN SoldAsVacant='Y' THEN 'Yes'
	WHEN SoldAsVacant='N' THEN 'No'
	ELSE SoldAsVacant
	END 


-----------------------------------------------------------------------------------------------------------------------------------------------------
--Remove duplicates
-----------------------------------------------------------------------------------------------------------------------------------------------------
/* WARNING
Ususally its better to make a seperate tanle for clean data and keep the raw data as it is but since i have an CSV backup of the data im making
changesdirectly to the main imported data
*/

WITH #CTE_Duplicate_check
AS(
SELECT * ,
ROW_NUMBER() OVER (
PARTITION BY 
ParcelID
,PropertyAddress
,SaleDate
,SalePrice
,LegalReference
,OwnerName
ORDER BY UniqueID) as duplicate_count
FROM ProjectPortfolio01..Nashville_Housing_Data
--ORDER BY 25 DESC
--WHERE ParcelID='091 12 0N 001.00'
)
--SELECT *
DELETE
FROM #CTE_Duplicate_check
WHERE duplicate_count>1
--104 such rows 


-----------------------------------------------------------------------------------------------------------------------------------------------------
--Remove duplicates
-----------------------------------------------------------------------------------------------------------------------------------------------------
/* WARNING
Ususally its better to make a seperate tanle for clean data and keep the raw data as it is but since i have an CSV backup of the data im making
changesdirectly to the main imported data
*/

ALTER TABLE ProjectPortfolio01..Nashville_Housing_Data
DROP COLUMN PropertyAddress,OwnerAddress

--Dropping columns since we have already used these columns to make new ones in the above sections

SELECT * FROM ProjectPortfolio01..Nashville_Housing_Data

-----------------------------------------------------------------------------------------------------------------------------------------------------
--Lets Creates Somes Views
-----------------------------------------------------------------------------------------------------------------------------------------------------
SELECT * 
FROM ProjectPortfolio01..Nashville_Housing_Data

CREATE VIEW Property_city_count AS
SELECT PropertySplitCity,COUNT(*) PropertCount
FROM ProjectPortfolio01..Nashville_Housing_Data
GROUP BY PropertySplitCity

CREATE VIEW Propert_LandUse_Count AS
SELECT LandUse,COUNT(*) PropertCount
FROM ProjectPortfolio01..Nashville_Housing_Data
GROUP BY LandUse

CREATE VIEW Monthly_sales AS
SELECT DATEPART(YEAR,SaleDate) as Year,DATEPART(MONTH,SaleDate) as Month,COUNT(*) PropertCount
	,SUM(SalePrice) AS TotalSales
	,ROUND(AVG(SalePrice),0) as AVGSalesPrice
,CASE 
WHEN LAG(ROUND(AVG(SalePrice),0) ,1,0) OVER (PARTITION BY DATEPART(YEAR,SaleDate) ORDER BY DATEPART(MONTH,SaleDate)) = 0 THEN '' 
WHEN LAG(ROUND(AVG(SalePrice),0) ,1,0) OVER (PARTITION BY DATEPART(YEAR,SaleDate) ORDER BY DATEPART(MONTH,SaleDate)) >= ROUND(AVG(SalePrice),0) THEN 'DOWN'
ELSE 'UP'
END as Monthly_AVGSales_Performance
FROM ProjectPortfolio01..Nashville_Housing_Data
GROUP BY DATEPART(YEAR,SaleDate),DATEPART(MONTH,SaleDate)
--ORDER BY 1,2 
