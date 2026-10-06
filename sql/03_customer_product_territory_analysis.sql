USE AdventureWorks2022;
GO

/* ============================================================
   ADVENTUREWORKS SALES ANALYTICS
   03 - CUSTOMER, PRODUCT & TERRITORY ANALYSIS
   ============================================================

   Purpose:
   Detailed analysis of customers, territories and products.

   Advanced SQL techniques:
   - CTEs
   - Window Functions
   - LAG()
   - ROW_NUMBER()
   - PERCENTILE_CONT()
   ============================================================ */


/* ============================================================
   1. TOP CUSTOMERS BY REVENUE
   ============================================================ */

SELECT TOP 10
    c.CustomerID,
    SUM(soh.TotalDue) AS Revenue
FROM Sales.Customer c
INNER JOIN Sales.SalesOrderHeader soh
    ON c.CustomerID = soh.CustomerID
GROUP BY
    c.CustomerID
ORDER BY Revenue DESC;


/* ============================================================
   2. TOP CUSTOMERS BY ORDERS
   ============================================================ */

SELECT TOP 10
    c.CustomerID,
    COUNT(DISTINCT soh.SalesOrderID) AS Orders,
    SUM(soh.TotalDue) AS Revenue,
    SUM(soh.TotalDue)
        / COUNT(DISTINCT soh.SalesOrderID) AS AverageOrderValue
FROM Sales.Customer c
INNER JOIN Sales.SalesOrderHeader soh
    ON c.CustomerID = soh.CustomerID
GROUP BY
    c.CustomerID
ORDER BY Orders DESC;


/* ============================================================
   3. TOP CUSTOMERS WITH NAMES
   ============================================================ */

SELECT TOP 10
    c.CustomerID,
    p.FirstName,
    p.LastName,
    SUM(soh.TotalDue) AS Revenue
FROM Sales.Customer c
INNER JOIN Person.Person p
    ON c.PersonID = p.BusinessEntityID
INNER JOIN Sales.SalesOrderHeader soh
    ON c.CustomerID = soh.CustomerID
GROUP BY
    c.CustomerID,
    p.FirstName,
    p.LastName
ORDER BY Revenue DESC;


/* ============================================================
   4. TOP 10 CUSTOMERS' SHARE OF TOTAL REVENUE
   ============================================================ */

WITH CustomerRevenue AS
(
    SELECT
        c.CustomerID,
        SUM(soh.TotalDue) AS Revenue
    FROM Sales.Customer c
    INNER JOIN Sales.SalesOrderHeader soh
        ON c.CustomerID = soh.CustomerID
    GROUP BY
        c.CustomerID
),
RankedCustomers AS
(
    SELECT
        CustomerID,
        Revenue,
        ROW_NUMBER() OVER (
            ORDER BY Revenue DESC
        ) AS CustomerRank
    FROM CustomerRevenue
)
SELECT
    SUM(
        CASE
            WHEN CustomerRank <= 10 THEN Revenue
            ELSE 0
        END
    ) / SUM(Revenue) * 100 AS Top10RevenuePercentage
FROM RankedCustomers;


/* ============================================================
   5. CUSTOMER TYPE
   ============================================================ */

SELECT
    CASE
        WHEN c.PersonID IS NOT NULL THEN 'Person'
        WHEN c.StoreID IS NOT NULL THEN 'Store'
        ELSE 'Unknown'
    END AS CustomerType,
    COUNT(DISTINCT c.CustomerID) AS Customers,
    SUM(soh.TotalDue) AS Revenue
FROM Sales.Customer c
INNER JOIN Sales.SalesOrderHeader soh
    ON c.CustomerID = soh.CustomerID
GROUP BY
    CASE
        WHEN c.PersonID IS NOT NULL THEN 'Person'
        WHEN c.StoreID IS NOT NULL THEN 'Store'
        ELSE 'Unknown'
    END
ORDER BY Revenue DESC;


/* ============================================================
   6. CUSTOMERS AND REVENUE BY TERRITORY
   ============================================================ */

SELECT
    st.Name AS Territory,
    COUNT(DISTINCT soh.CustomerID) AS Customers,
    SUM(soh.TotalDue) AS Revenue,
    SUM(soh.TotalDue)
        / COUNT(DISTINCT soh.CustomerID) AS RevenuePerCustomer
FROM Sales.SalesOrderHeader soh
INNER JOIN Sales.SalesTerritory st
    ON soh.TerritoryID = st.TerritoryID
GROUP BY
    st.Name
ORDER BY Revenue DESC;


/* ============================================================
   7. ORDERS, CUSTOMERS AND REVENUE BY TERRITORY
   ============================================================ */

SELECT
    st.Name AS Territory,
    COUNT(DISTINCT soh.CustomerID) AS Customers,
    COUNT(DISTINCT soh.SalesOrderID) AS Orders,
    SUM(soh.TotalDue) AS Revenue,
    COUNT(DISTINCT soh.SalesOrderID)
        / CAST(
            COUNT(DISTINCT soh.CustomerID)
            AS DECIMAL(18,2)
        ) AS OrdersPerCustomer,
    SUM(soh.TotalDue)
        / COUNT(DISTINCT soh.SalesOrderID) AS AverageOrderValue
FROM Sales.SalesOrderHeader soh
INNER JOIN Sales.SalesTerritory st
    ON soh.TerritoryID = st.TerritoryID
GROUP BY
    st.Name
ORDER BY Revenue DESC;


/* ============================================================
   8. 2014 VS 2013 TERRITORY YOY
   ============================================================ */

WITH TerritoryYearlySales AS
(
    SELECT
        st.Name AS Territory,
        YEAR(soh.OrderDate) AS SalesYear,
        SUM(soh.TotalDue) AS Revenue
    FROM Sales.SalesOrderHeader soh
    INNER JOIN Sales.SalesTerritory st
        ON soh.TerritoryID = st.TerritoryID
    WHERE YEAR(soh.OrderDate) IN (2013, 2014)
    GROUP BY
        st.Name,
        YEAR(soh.OrderDate)
)
SELECT
    Territory,
    MAX(
        CASE
            WHEN SalesYear = 2013 THEN Revenue
        END
    ) AS Revenue2013,
    MAX(
        CASE
            WHEN SalesYear = 2014 THEN Revenue
        END
    ) AS Revenue2014,
    (
        MAX(
            CASE
                WHEN SalesYear = 2014 THEN Revenue
            END
        )
        -
        MAX(
            CASE
                WHEN SalesYear = 2013 THEN Revenue
            END
        )
    )
    /
    MAX(
        CASE
            WHEN SalesYear = 2013 THEN Revenue
        END
    ) * 100 AS YoYGrowthPercentage
FROM TerritoryYearlySales
GROUP BY
    Territory
ORDER BY YoYGrowthPercentage DESC;


/* ============================================================
   9. TOP 5 CUSTOMERS PER TERRITORY
   ============================================================ */

WITH CustomerTerritoryRevenue AS
(
    SELECT
        st.Name AS Territory,
        c.CustomerID,
        SUM(soh.TotalDue) AS Revenue
    FROM Sales.Customer c
    INNER JOIN Sales.SalesOrderHeader soh
        ON c.CustomerID = soh.CustomerID
    INNER JOIN Sales.SalesTerritory st
        ON soh.TerritoryID = st.TerritoryID
    GROUP BY
        st.Name,
        c.CustomerID
),
RankedCustomers AS
(
    SELECT
        Territory,
        CustomerID,
        Revenue,
        ROW_NUMBER() OVER (
            PARTITION BY Territory
            ORDER BY Revenue DESC
        ) AS CustomerRank
    FROM CustomerTerritoryRevenue
)
SELECT
    Territory,
    CustomerID,
    Revenue,
    CustomerRank
FROM RankedCustomers
WHERE CustomerRank <= 5
ORDER BY
    Territory,
    CustomerRank;


/* ============================================================
   10. BIKE SALES BY TERRITORY
   ============================================================ */

SELECT
    st.Name AS Territory,
    SUM(sod.OrderQty) AS BikesSold,
    SUM(sod.LineTotal) AS Revenue,
    COUNT(DISTINCT sod.SalesOrderID) AS Orders,
    SUM(sod.OrderQty)
        / CAST(
            COUNT(DISTINCT sod.SalesOrderID)
            AS DECIMAL(18,2)
        ) AS BikesPerOrder,
    SUM(sod.LineTotal)
        / COUNT(DISTINCT sod.SalesOrderID) AS AverageOrderValue
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


/* ============================================================
   11. BIKES PER ORDER
   ============================================================ */

SELECT
    sod.SalesOrderID,
    SUM(sod.OrderQty) AS BikesSold
FROM Sales.SalesOrderDetail sod
INNER JOIN Production.Product p
    ON sod.ProductID = p.ProductID
INNER JOIN Production.ProductSubcategory psc
    ON p.ProductSubcategoryID = psc.ProductSubcategoryID
INNER JOIN Production.ProductCategory pc
    ON psc.ProductCategoryID = pc.ProductCategoryID
WHERE pc.Name = 'Bikes'
GROUP BY
    sod.SalesOrderID
ORDER BY BikesSold DESC;


/* ============================================================
   12. MINIMUM, MAXIMUM AND AVERAGE BIKES PER ORDER
   ============================================================ */

WITH BikeOrders AS
(
    SELECT
        sod.SalesOrderID,
        SUM(sod.OrderQty) AS BikesSold
    FROM Sales.SalesOrderDetail sod
    INNER JOIN Production.Product p
        ON sod.ProductID = p.ProductID
    INNER JOIN Production.ProductSubcategory psc
        ON p.ProductSubcategoryID = psc.ProductSubcategoryID
    INNER JOIN Production.ProductCategory pc
        ON psc.ProductCategoryID = pc.ProductCategoryID
    WHERE pc.Name = 'Bikes'
    GROUP BY
        sod.SalesOrderID
)
SELECT
    MIN(BikesSold) AS MinimumBikesPerOrder,
    MAX(BikesSold) AS MaximumBikesPerOrder,
    AVG(
        CAST(BikesSold AS DECIMAL(18,2))
    ) AS AverageBikesPerOrder
FROM BikeOrders;


/* ============================================================
   13. MEDIAN BIKES PER ORDER
   ============================================================ */

WITH BikeOrders AS
(
    SELECT
        sod.SalesOrderID,
        SUM(sod.OrderQty) AS BikesSold
    FROM Sales.SalesOrderDetail sod
    INNER JOIN Production.Product p
        ON sod.ProductID = p.ProductID
    INNER JOIN Production.ProductSubcategory psc
        ON p.ProductSubcategoryID = psc.ProductSubcategoryID
    INNER JOIN Production.ProductCategory pc
        ON psc.ProductCategoryID = pc.ProductCategoryID
    WHERE pc.Name = 'Bikes'
    GROUP BY
        sod.SalesOrderID
)
SELECT DISTINCT
    PERCENTILE_CONT(0.5)
        WITHIN GROUP (
            ORDER BY BikesSold
        ) OVER () AS MedianBikesPerOrder
FROM BikeOrders;


/* ============================================================
   14. TOP 10 BIKE ORDERS
   ============================================================ */

WITH BikeOrders AS
(
    SELECT
        sod.SalesOrderID,
        SUM(sod.OrderQty) AS BikesSold
    FROM Sales.SalesOrderDetail sod
    INNER JOIN Production.Product p
        ON sod.ProductID = p.ProductID
    INNER JOIN Production.ProductSubcategory psc
        ON p.ProductSubcategoryID = psc.ProductSubcategoryID
    INNER JOIN Production.ProductCategory pc
        ON psc.ProductCategoryID = pc.ProductCategoryID
    WHERE pc.Name = 'Bikes'
    GROUP BY
        sod.SalesOrderID
)
SELECT TOP 10
    SalesOrderID,
    BikesSold
FROM BikeOrders
ORDER BY BikesSold DESC;


/* ============================================================
   15. BIKE CUSTOMERS BY TERRITORY
   ============================================================ */

SELECT
    st.Name AS Territory,
    c.CustomerID,
    SUM(sod.LineTotal) AS BikeRevenue,
    SUM(sod.OrderQty) AS BikesPurchased
FROM Sales.SalesOrderDetail sod
INNER JOIN Sales.SalesOrderHeader soh
    ON sod.SalesOrderID = soh.SalesOrderID
INNER JOIN Sales.Customer c
    ON soh.CustomerID = c.CustomerID
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
    st.Name,
    c.CustomerID
ORDER BY
    st.Name,
    BikeRevenue DESC;


/* ============================================================
   16. SUBCATEGORY PERFORMANCE BY SELECTED TERRITORIES
   ============================================================ */

SELECT
    st.Name AS Territory,
    psc.Name AS Subcategory,
    SUM(sod.OrderQty) AS UnitsSold,
    SUM(sod.LineTotal) AS Revenue,
    COUNT(DISTINCT sod.SalesOrderID) AS Orders,
    SUM(sod.OrderQty)
        / CAST(
            COUNT(DISTINCT sod.SalesOrderID)
            AS DECIMAL(18,2)
        ) AS UnitsPerOrder
FROM Sales.SalesOrderDetail sod
INNER JOIN Sales.SalesOrderHeader soh
    ON sod.SalesOrderID = soh.SalesOrderID
INNER JOIN Sales.SalesTerritory st
    ON soh.TerritoryID = st.TerritoryID
INNER JOIN Production.Product p
    ON sod.ProductID = p.ProductID
INNER JOIN Production.ProductSubcategory psc
    ON p.ProductSubcategoryID = psc.ProductSubcategoryID
WHERE st.Name IN (
    'Central',
    'Northeast',
    'Southeast',
    'Southwest',
    'Northwest'
)
GROUP BY
    st.Name,
    psc.Name
ORDER BY
    st.Name,
    Revenue DESC;


/* ============================================================
   17. SUBCATEGORY REVENUE SHARE BY TERRITORY
   ============================================================ */

WITH TerritorySubcategorySales AS
(
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
)
SELECT
    Territory,
    Subcategory,
    Revenue,
    Revenue
        / SUM(Revenue) OVER (
            PARTITION BY Territory
        ) * 100 AS RevenuePercentage
FROM TerritorySubcategorySales
ORDER BY
    Territory,
    Revenue DESC;