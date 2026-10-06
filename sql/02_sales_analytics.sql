USE AdventureWorks2022;
GO

/* ============================================================
   ADVENTUREWORKS SALES ANALYTICS
   02 - SALES ANALYSIS
   ============================================================

   Purpose:
   Analyze overall sales performance, revenue trends,
   products, categories and sales territories.

   Database: AdventureWorks2022
   Platform: SQL Server
   ============================================================ */


/* ============================================================
   1. OVERALL SALES KPIs
   ============================================================ */

-- Total number of orders
SELECT
    COUNT(DISTINCT SalesOrderID) AS TotalOrders
FROM Sales.SalesOrderHeader;


-- Total revenue
SELECT
    SUM(TotalDue) AS TotalRevenue
FROM Sales.SalesOrderHeader;


/* ============================================================
   2. REVENUE BY YEAR
   ============================================================ */

SELECT
    YEAR(OrderDate) AS SalesYear,
    SUM(TotalDue) AS Revenue
FROM Sales.SalesOrderHeader
GROUP BY YEAR(OrderDate)
ORDER BY SalesYear;


/* ============================================================
   3. YEAR-OVER-YEAR REVENUE ANALYSIS
   ============================================================ */

WITH YearlySales AS
(
    SELECT
        YEAR(OrderDate) AS SalesYear,
        SUM(TotalDue) AS Revenue
    FROM Sales.SalesOrderHeader
    GROUP BY YEAR(OrderDate)
),
SalesWithPreviousYear AS
(
    SELECT
        SalesYear,
        Revenue,
        LAG(Revenue) OVER (
            ORDER BY SalesYear
        ) AS PreviousYearRevenue
    FROM YearlySales
)
SELECT
    SalesYear,
    Revenue,
    PreviousYearRevenue,
    Revenue - PreviousYearRevenue AS RevenueChange,
    CASE
        WHEN PreviousYearRevenue IS NULL THEN NULL
        ELSE
            (Revenue - PreviousYearRevenue)
            / PreviousYearRevenue * 100
    END AS YoYGrowthPercentage
FROM SalesWithPreviousYear
ORDER BY SalesYear;


/* ============================================================
   4. ORDERS AND AVERAGE ORDER VALUE BY YEAR
   ============================================================ */

SELECT
    YEAR(OrderDate) AS SalesYear,
    COUNT(DISTINCT SalesOrderID) AS Orders,
    SUM(TotalDue) AS Revenue,
    SUM(TotalDue) / COUNT(DISTINCT SalesOrderID) AS AverageOrderValue
FROM Sales.SalesOrderHeader
GROUP BY YEAR(OrderDate)
ORDER BY SalesYear;


/* ============================================================
   5. PRODUCT PERFORMANCE
   ============================================================ */

-- Top products by revenue
SELECT TOP 10
    p.ProductID,
    p.Name AS ProductName,
    SUM(sod.LineTotal) AS Revenue
FROM Sales.SalesOrderDetail sod
INNER JOIN Production.Product p
    ON sod.ProductID = p.ProductID
GROUP BY
    p.ProductID,
    p.Name
ORDER BY Revenue DESC;


-- Top products by units sold
SELECT TOP 10
    p.ProductID,
    p.Name AS ProductName,
    SUM(sod.OrderQty) AS UnitsSold
FROM Sales.SalesOrderDetail sod
INNER JOIN Production.Product p
    ON sod.ProductID = p.ProductID
GROUP BY
    p.ProductID,
    p.Name
ORDER BY UnitsSold DESC;


-- Top products by average unit price
SELECT TOP 10
    p.ProductID,
    p.Name AS ProductName,
    AVG(sod.UnitPrice) AS AverageUnitPrice
FROM Sales.SalesOrderDetail sod
INNER JOIN Production.Product p
    ON sod.ProductID = p.ProductID
GROUP BY
    p.ProductID,
    p.Name
ORDER BY AverageUnitPrice DESC;


/* ============================================================
   6. PRODUCT CATEGORY ANALYSIS
   ============================================================ */

-- Revenue by category
SELECT
    pc.Name AS Category,
    SUM(sod.LineTotal) AS Revenue
FROM Sales.SalesOrderDetail sod
INNER JOIN Production.Product p
    ON sod.ProductID = p.ProductID
INNER JOIN Production.ProductSubcategory psc
    ON p.ProductSubcategoryID = psc.ProductSubcategoryID
INNER JOIN Production.ProductCategory pc
    ON psc.ProductCategoryID = pc.ProductCategoryID
GROUP BY
    pc.Name
ORDER BY Revenue DESC;


-- Revenue percentage by category
SELECT
    pc.Name AS Category,
    SUM(sod.LineTotal) AS Revenue,
    SUM(sod.LineTotal)
        / SUM(SUM(sod.LineTotal)) OVER () * 100 AS RevenuePercentage
FROM Sales.SalesOrderDetail sod
INNER JOIN Production.Product p
    ON sod.ProductID = p.ProductID
INNER JOIN Production.ProductSubcategory psc
    ON p.ProductSubcategoryID = psc.ProductSubcategoryID
INNER JOIN Production.ProductCategory pc
    ON psc.ProductCategoryID = pc.ProductCategoryID
GROUP BY
    pc.Name
ORDER BY Revenue DESC;


/* ============================================================
   7. SUBCATEGORY ANALYSIS
   ============================================================ */

SELECT
    psc.Name AS Subcategory,
    SUM(sod.OrderQty) AS UnitsSold,
    SUM(sod.LineTotal) AS Revenue,
    COUNT(DISTINCT sod.SalesOrderID) AS Orders,
    SUM(sod.LineTotal)
        / COUNT(DISTINCT sod.SalesOrderID) AS RevenuePerOrder,
    SUM(sod.OrderQty)
        / COUNT(DISTINCT sod.SalesOrderID) AS UnitsPerOrder
FROM Sales.SalesOrderDetail sod
INNER JOIN Production.Product p
    ON sod.ProductID = p.ProductID
INNER JOIN Production.ProductSubcategory psc
    ON p.ProductSubcategoryID = psc.ProductSubcategoryID
GROUP BY
    psc.Name
ORDER BY Revenue DESC;


/* ============================================================
   8. SALES BY TERRITORY
   ============================================================ */

SELECT
    st.Name AS Territory,
    st.[Group] AS Region,
    SUM(soh.TotalDue) AS Revenue
FROM Sales.SalesOrderHeader soh
INNER JOIN Sales.SalesTerritory st
    ON soh.TerritoryID = st.TerritoryID
GROUP BY
    st.Name,
    st.[Group]
ORDER BY Revenue DESC;


/* ============================================================
   9. TERRITORY REVENUE SHARE
   ============================================================ */

SELECT
    st.Name AS Territory,
    st.[Group] AS Region,
    SUM(soh.TotalDue) AS Revenue,
    SUM(soh.TotalDue)
        / SUM(SUM(soh.TotalDue)) OVER () * 100 AS RevenuePercentage
FROM Sales.SalesOrderHeader soh
INNER JOIN Sales.SalesTerritory st
    ON soh.TerritoryID = st.TerritoryID
GROUP BY
    st.Name,
    st.[Group]
ORDER BY Revenue DESC;


/* ============================================================
   10. REVENUE BY REGION AND YEAR
   ============================================================ */

SELECT
    st.[Group] AS Region,
    YEAR(soh.OrderDate) AS SalesYear,
    SUM(soh.TotalDue) AS Revenue
FROM Sales.SalesOrderHeader soh
INNER JOIN Sales.SalesTerritory st
    ON soh.TerritoryID = st.TerritoryID
GROUP BY
    st.[Group],
    YEAR(soh.OrderDate)
ORDER BY
    Region,
    SalesYear;


/* ============================================================
   11. REGIONAL YEAR-OVER-YEAR ANALYSIS
   ============================================================ */

WITH RegionalSales AS
(
    SELECT
        st.[Group] AS Region,
        YEAR(soh.OrderDate) AS SalesYear,
        SUM(soh.TotalDue) AS Revenue
    FROM Sales.SalesOrderHeader soh
    INNER JOIN Sales.SalesTerritory st
        ON soh.TerritoryID = st.TerritoryID
    GROUP BY
        st.[Group],
        YEAR(soh.OrderDate)
)
SELECT
    Region,
    SalesYear,
    Revenue,
    LAG(Revenue) OVER (
        PARTITION BY Region
        ORDER BY SalesYear
    ) AS PreviousYearRevenue
FROM RegionalSales
ORDER BY
    Region,
    SalesYear;


/* ============================================================
   12. TERRITORY YOY GROWTH
   ============================================================ */

WITH TerritorySales AS
(
    SELECT
        st.Name AS Territory,
        YEAR(soh.OrderDate) AS SalesYear,
        SUM(soh.TotalDue) AS Revenue
    FROM Sales.SalesOrderHeader soh
    INNER JOIN Sales.SalesTerritory st
        ON soh.TerritoryID = st.TerritoryID
    GROUP BY
        st.Name,
        YEAR(soh.OrderDate)
),
TerritoryGrowth AS
(
    SELECT
        Territory,
        SalesYear,
        Revenue,
        LAG(Revenue) OVER (
            PARTITION BY Territory
            ORDER BY SalesYear
        ) AS PreviousYearRevenue
    FROM TerritorySales
)
SELECT
    Territory,
    SalesYear,
    Revenue,
    PreviousYearRevenue,
    CASE
        WHEN PreviousYearRevenue IS NULL THEN NULL
        ELSE
            (Revenue - PreviousYearRevenue)
            / PreviousYearRevenue * 100
    END AS YoYGrowthPercentage
FROM TerritoryGrowth
ORDER BY
    Territory,
    SalesYear;


/* ============================================================
   13. CATEGORY PERFORMANCE BY TERRITORY
   ============================================================ */

SELECT
    st.Name AS Territory,
    pc.Name AS Category,
    SUM(sod.LineTotal) AS Revenue
FROM Sales.SalesOrderDetail sod
INNER JOIN Sales.SalesOrderHeader soh
    ON sod.SalesOrderID = soh.SalesOrderID
INNER JOIN Sales.SalesTerritory st
    ON soh.TerritoryID = st.TerritoryID
INNER JOIN Production.Product p
    ON sod.ProductID = p.ProductID
INNER JOIN Production.ProductSubcategory psc
    ON p.ProductSubcategoryID = psc.ProductSubcategoryID
INNER JOIN Production.ProductCategory pc
    ON psc.ProductCategoryID = pc.ProductCategoryID
GROUP BY
    st.Name,
    pc.Name
ORDER BY
    st.Name,
    Revenue DESC;


/* ============================================================
   14. SUBCATEGORY PERFORMANCE BY TERRITORY
   ============================================================ */

SELECT
    st.Name AS Territory,
    psc.Name AS Subcategory,
    SUM(sod.LineTotal) AS Revenue
FROM Sales.SalesOrderDetail sod
INNER JOIN Sales.SalesOrderHeader soh
    ON sod.SalesOrderID = soh.SalesOrderID
INNER JOIN Sales.SalesTerritory st
    ON soh.TerritoryID = st.TerritoryID
INNER JOIN Production.Product p
    ON sod.ProductID = p.ProductID
INNER JOIN Production.ProductSubcategory psc
    ON p.ProductSubcategoryID = psc.ProductSubcategoryID
GROUP BY
    st.Name,
    psc.Name
ORDER BY
    st.Name,
    Revenue DESC;


/* ============================================================
   15. BIKE SALES ANALYSIS
   ============================================================ */

SELECT
    st.Name AS Territory,
    SUM(sod.OrderQty) AS BikesSold,
    SUM(sod.LineTotal) AS Revenue,
    AVG(sod.UnitPrice) AS AverageUnitPrice
FROM Sales.SalesOrderDetail sod
INNER JOIN Sales.SalesOrderHeader soh
    ON sod.SalesOrderID = soh.SalesOrderID
INNER JOIN Sales.SalesTerritory st
    ON soh.TerritoryID = st.TerritoryID
INNER JOIN Production.Product p
    ON sod.ProductID = p.ProductID
INNER JOIN Production.ProductSubcategory psc
    ON p.ProductSubcategoryID = psc.ProductSubcategoryID
INNER JOIN Production.ProductCategory pc
    ON psc.ProductCategoryID = pc.ProductCategoryID
WHERE pc.Name = 'Bikes'
GROUP BY
    st.Name
ORDER BY Revenue DESC;