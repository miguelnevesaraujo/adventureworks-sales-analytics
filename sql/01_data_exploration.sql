USE AdventureWorks2022;

-- Total de encomendas
SELECT
    COUNT(*) AS TotalOrders
FROM Sales.SalesOrderHeader;

-- Receita total
SELECT
    SUM(TotalDue) AS TotalRevenue
FROM Sales.SalesOrderHeader;

-- Receita por ano
SELECT
    YEAR(OrderDate) AS SalesYear,
    SUM(TotalDue) AS Revenue
FROM Sales.SalesOrderHeader
GROUP BY YEAR(OrderDate)
ORDER BY SalesYear;

WITH yearly_sales AS (
    SELECT
        YEAR(OrderDate) AS SalesYear,
        SUM(TotalDue) AS Revenue
    FROM Sales.SalesOrderHeader
    GROUP BY YEAR(OrderDate)
)
SELECT
    SalesYear,
    Revenue,
    LAG(Revenue) OVER (ORDER BY SalesYear) AS PreviousYearRevenue
FROM yearly_sales
ORDER BY SalesYear;

WITH yearly_sales AS (
    SELECT
        YEAR(OrderDate) AS SalesYear,
        SUM(TotalDue) AS Revenue
    FROM Sales.SalesOrderHeader
    GROUP BY YEAR(OrderDate)
),
sales_with_previous AS (
    SELECT
        SalesYear,
        Revenue,
        LAG(Revenue) OVER (ORDER BY SalesYear) AS PreviousYearRevenue
    FROM yearly_sales
)
SELECT
    SalesYear,
    Revenue,
    PreviousYearRevenue,
    (Revenue - PreviousYearRevenue) / PreviousYearRevenue * 100 AS YoYGrowth
FROM sales_with_previous
ORDER BY SalesYear;

SELECT
    YEAR(OrderDate) AS SalesYear,
    COUNT(*) AS NumberOfOrders,
    SUM(TotalDue) AS Revenue,
    AVG(TotalDue) AS AverageOrderValue
FROM Sales.SalesOrderHeader
GROUP BY YEAR(OrderDate)
ORDER BY SalesYear;

SELECT
    TABLE_SCHEMA,
    TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_SCHEMA, TABLE_NAME;

SELECT TOP 10
    *
FROM Sales.SalesOrderDetail;

SELECT TOP 10
    sod.SalesOrderID,
    sod.ProductID,
    p.Name AS ProductName,
    sod.OrderQty,
    sod.UnitPrice,
    sod.LineTotal
FROM Sales.SalesOrderDetail AS sod
INNER JOIN Production.Product AS p
    ON sod.ProductID = p.ProductID;

SELECT TOP 10
    p.Name AS ProductName,
    SUM(sod.LineTotal) AS Revenue
FROM Sales.SalesOrderDetail AS sod
INNER JOIN Production.Product AS p
    ON sod.ProductID = p.ProductID
GROUP BY p.Name
ORDER BY Revenue DESC;

SELECT TOP 10
    p.Name AS ProductName,
    SUM(sod.LineTotal) AS Revenue,
    SUM(sod.OrderQty) AS UnitsSold,
    SUM(sod.LineTotal) / SUM(sod.OrderQty) AS AverageUnitPrice
FROM Sales.SalesOrderDetail AS sod
INNER JOIN Production.Product AS p
    ON sod.ProductID = p.ProductID
GROUP BY p.Name
ORDER BY Revenue DESC;

SELECT TOP 10
    p.Name AS ProductName,
    ps.Name AS SubcategoryName,
    pc.Name AS CategoryName,
    sod.LineTotal
FROM Sales.SalesOrderDetail AS sod
INNER JOIN Production.Product AS p
    ON sod.ProductID = p.ProductID
INNER JOIN Production.ProductSubcategory AS ps
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID
INNER JOIN Production.ProductCategory AS pc
    ON ps.ProductCategoryID = pc.ProductCategoryID;

SELECT
    pc.Name AS CategoryName,
    SUM(sod.LineTotal) AS Revenue
FROM Sales.SalesOrderDetail AS sod
INNER JOIN Production.Product AS p
    ON sod.ProductID = p.ProductID
INNER JOIN Production.ProductSubcategory AS ps
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID
INNER JOIN Production.ProductCategory AS pc
    ON ps.ProductCategoryID = pc.ProductCategoryID
GROUP BY pc.Name
ORDER BY Revenue DESC;

SELECT
    pc.Name AS CategoryName,
    SUM(sod.LineTotal) AS Revenue,
    SUM(sod.LineTotal) / SUM(SUM(sod.LineTotal)) OVER () * 100 AS RevenuePercentage
FROM Sales.SalesOrderDetail AS sod
INNER JOIN Production.Product AS p
    ON sod.ProductID = p.ProductID
INNER JOIN Production.ProductSubcategory AS ps
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID
INNER JOIN Production.ProductCategory AS pc
    ON ps.ProductCategoryID = pc.ProductCategoryID
GROUP BY pc.Name
ORDER BY Revenue DESC;

SELECT TOP 10
    soh.SalesOrderID,
    soh.CustomerID,
    c.PersonID,
    soh.TotalDue
FROM Sales.SalesOrderHeader AS soh
INNER JOIN Sales.Customer AS c
    ON soh.CustomerID = c.CustomerID;

SELECT TOP 10
    soh.CustomerID,
    SUM(soh.TotalDue) AS TotalRevenue,
    COUNT(soh.SalesOrderID) AS NumberOfOrders
FROM Sales.SalesOrderHeader AS soh
INNER JOIN Sales.Customer AS c
    ON soh.CustomerID = c.CustomerID
GROUP BY soh.CustomerID
ORDER BY TotalRevenue DESC;

SELECT TOP 10
    soh.CustomerID,
    SUM(soh.TotalDue) AS TotalRevenue,
    COUNT(soh.SalesOrderID) AS NumberOfOrders,
    SUM(soh.TotalDue) / COUNT(soh.SalesOrderID) AS AverageOrderValue
FROM Sales.SalesOrderHeader AS soh
INNER JOIN Sales.Customer AS c
    ON soh.CustomerID = c.CustomerID
GROUP BY soh.CustomerID
ORDER BY TotalRevenue DESC;

SELECT TOP 10
    c.CustomerID,
    c.PersonID,
    p.FirstName,
    p.LastName
FROM Sales.Customer as c
INNER JOIN Person.Person as p
    ON c.PersonID = p.BusinessEntityID
WHERE c.PersonID IS NOT NULL;

SELECT TOP 10
    c.CustomerID,
    p.FirstName + ' ' + p.LastName AS CustomerName,
    SUM(soh.TotalDue) AS TotalRevenue,
    COUNT(soh.SalesOrderID) AS NumberOfOrders,
    SUM(soh.TotalDue) / COUNT(soh.SalesOrderID) AS AverageOrderValue
FROM Sales.SalesOrderHeader AS soh
INNER JOIN Sales.Customer AS c
    ON soh.CustomerID = c.CustomerID
INNER JOIN Person.Person AS p
    ON c.PersonID = p.BusinessEntityID
GROUP BY
    c.CustomerID,
    p.FirstName,
    p.LastName
ORDER BY TotalRevenue DESC;

WITH customer_sales AS (
    SELECT
        c.CustomerID,
        p.FirstName + ' ' + p.LastName AS CustomerName,
        SUM(soh.TotalDue) AS TotalRevenue,
        COUNT(soh.SalesOrderID) AS NumberOfOrders
    FROM Sales.SalesOrderHeader AS soh
    INNER JOIN Sales.Customer AS c
        ON soh.CustomerID = c.CustomerID
    INNER JOIN Person.Person AS p
        ON c.PersonID = p.BusinessEntityID
    GROUP BY
        c.CustomerID,
        p.FirstName,
        p.LastName
)
SELECT TOP 10
    CustomerID,
    CustomerName,
    TotalRevenue,
    NumberOfOrders,
    TotalRevenue / SUM(TotalRevenue) OVER () * 100 AS RevenuePercentage
FROM customer_sales
ORDER BY TotalRevenue DESC;

WITH customer_sales AS (
    SELECT
        c.CustomerID,
        p.FirstName + ' ' + p.LastName AS CustomerName,
        SUM(soh.TotalDue) AS TotalRevenue
    FROM Sales.SalesOrderHeader AS soh
    INNER JOIN Sales.Customer AS c
        ON soh.CustomerID = c.CustomerID
    INNER JOIN Person.Person AS p
        ON c.PersonID = p.BusinessEntityID
    GROUP BY
        c.CustomerID,
        p.FirstName,
        p.LastName
),
top_10_customers AS (
    SELECT TOP 10
        CustomerID,
        CustomerName,
        TotalRevenue,
        TotalRevenue / SUM(TotalRevenue) OVER () * 100 AS RevenuePercentage
    FROM customer_sales
    ORDER BY TotalRevenue DESC
)
SELECT
    SUM(RevenuePercentage) AS Top10RevenuePercentage
FROM top_10_customers;

SELECT *
FROM Sales.SalesTerritory;

SELECT TOP 10
    soh.SalesOrderID,
    soh.OrderDate,
    soh.TotalDue,
    st.Name AS TerritoryName,
    st.CountryRegionCode,
    st.[Group] AS Region
FROM Sales.SalesOrderHeader AS soh
INNER JOIN Sales.SalesTerritory AS st
    ON soh.TerritoryID = st.TerritoryID;

SELECT
    st.Name AS TerritoryName,
    st.CountryRegionCode,
    st.[Group] AS Region,
    SUM(soh.TotalDue) AS TotalRevenue
FROM Sales.SalesOrderHeader AS soh 
INNER JOIN Sales.SalesTerritory AS st
    ON soh.TerritoryID = st.TerritoryID
GROUP BY
    st.Name,
    st.CountryRegionCode,
    st.[Group]
ORDER BY TotalRevenue DESC;

SELECT
    st.Name AS TerritoryName,
    st.CountryRegionCode,
    st.[Group] AS Region,
    SUM(soh.TotalDue) AS TotalRevenue,
    SUM(soh.TotalDue)
        / SUM(SUM(soh.TotalDue)) OVER () * 100 AS RevenuePercentage
FROM Sales.SalesOrderHeader AS soh
INNER JOIN Sales.SalesTerritory AS st
    ON soh.TerritoryID = st.TerritoryID
GROUP BY
    st.Name,
    st.CountryRegionCode,
    st.[Group]
ORDER BY TotalRevenue DESC;

SELECT
    st.[Group] AS Region,
    SUM(soh.TotalDue) AS TotalRevenue
FROM Sales.SalesOrderHeader AS soh
INNER JOIN Sales.SalesTerritory AS st
    ON soh.TerritoryID = st.TerritoryID
GROUP BY
    st.[Group]
ORDER BY TotalRevenue DESC;

SELECT
    st.[Group] AS Region,
    SUM(soh.TotalDue) AS TotalRevenue,
    SUM(soh.TotalDue)
        / SUM(SUM(soh.TotalDue)) OVER () * 100 AS RevenuePercentage
FROM Sales.SalesOrderHeader AS soh
INNER JOIN Sales.SalesTerritory AS st
    ON soh.TerritoryID = st.TerritoryID
GROUP BY
    st.[Group]
ORDER BY TotalRevenue DESC;

SELECT
    YEAR(soh.OrderDate) AS SalesYear,
    st.[Group] AS Region,
    SUM(soh.TotalDue) AS TotalRevenue
FROM Sales.SalesOrderHeader AS soh
INNER JOIN Sales.SalesTerritory AS st
    ON soh.TerritoryID = st.TerritoryID
GROUP BY
    YEAR(soh.OrderDate),
    st.[Group]
ORDER BY
    SalesYear,
    TotalRevenue DESC;

WITH regional_sales AS (
    SELECT
        YEAR(soh.OrderDate) AS SalesYear,
        st.[Group] AS Region,
        SUM(soh.TotalDue) AS TotalRevenue
    FROM Sales.SalesOrderHeader AS soh
    INNER JOIN Sales.SalesTerritory AS st
        ON soh.TerritoryID = st.TerritoryID
    GROUP BY
        YEAR(soh.OrderDate),
        st.[Group]
)
SELECT
    SalesYear,
    Region,
    TotalRevenue,
    LAG(TotalRevenue) OVER (
        PARTITION BY Region
        ORDER BY SalesYear
    ) AS PreviousYearRevenue
FROM regional_sales
ORDER BY
    Region,
    SalesYear;

WITH regional_sales AS (
    SELECT
        YEAR(soh.OrderDate) AS SalesYear,
        st.[Group] AS Region,
        SUM(soh.TotalDue) AS TotalRevenue
    FROM Sales.SalesOrderHeader AS soh
    INNER JOIN Sales.SalesTerritory AS st
        ON soh.TerritoryID = st.TerritoryID
    GROUP BY
        YEAR(soh.OrderDate),
        st.[Group]
),
regional_sales_with_previous AS (
    SELECT
        SalesYear,
        Region,
        TotalRevenue,
        LAG(TotalRevenue) OVER (
            PARTITION BY Region
            ORDER BY SalesYear
        ) AS PreviousYearRevenue
    FROM regional_sales
)
SELECT
    SalesYear,
    Region,
    TotalRevenue,
    PreviousYearRevenue,
    (TotalRevenue - PreviousYearRevenue)
        / PreviousYearRevenue * 100 AS YoYGrowth
FROM regional_sales_with_previous
ORDER BY
    Region,
    SalesYear;

WITH regional_sales AS (
    SELECT
        YEAR(soh.OrderDate) AS SalesYear,
        st.Name AS Territory,
        SUM(soh.TotalDue) AS TotalRevenue
    FROM Sales.SalesOrderHeader AS soh
    INNER JOIN Sales.SalesTerritory AS st
        ON soh.TerritoryID = st.TerritoryID
    GROUP BY
        YEAR(soh.OrderDate),
        st.Name
),
regional_sales_with_previous AS (
    SELECT
        SalesYear,
        Territory,
        TotalRevenue,
        LAG(TotalRevenue) OVER (
            PARTITION BY Territory
            ORDER BY SalesYear
        ) AS PreviousYearRevenue
    FROM regional_sales
)
SELECT
    SalesYear,
    Territory,
    TotalRevenue,
    PreviousYearRevenue,
    (TotalRevenue - PreviousYearRevenue)
        / PreviousYearRevenue * 100 AS YoYGrowth
FROM regional_sales_with_previous
ORDER BY
    Territory,
    SalesYear;

WITH territory_sales AS (
    SELECT
        YEAR(soh.OrderDate) AS SalesYear,
        st.Name AS Territory,
        SUM(soh.TotalDue) AS TotalRevenue
    FROM Sales.SalesOrderHeader AS soh
    INNER JOIN Sales.SalesTerritory AS st
        ON soh.TerritoryID = st.TerritoryID
    GROUP BY
        YEAR(soh.OrderDate),
        st.Name
),
territory_sales_with_previous AS (
    SELECT
        SalesYear,
        Territory,
        TotalRevenue,
        LAG(TotalRevenue) OVER (
            PARTITION BY Territory
            ORDER BY SalesYear
        ) AS PreviousYearRevenue
    FROM territory_sales
)
SELECT
    Territory,
    TotalRevenue AS Revenue2014,
    PreviousYearRevenue AS Revenue2013,
    (TotalRevenue - PreviousYearRevenue)
        / PreviousYearRevenue * 100 AS YoYGrowth2014
FROM territory_sales_with_previous
WHERE SalesYear = 2014
ORDER BY TotalRevenue DESC;

SELECT
    st.Name AS Territory,
    COUNT(DISTINCT soh.CustomerID) AS NumberOfCustomers,
    SUM(soh.TotalDue) AS TotalRevenue,
    SUM(soh.TotalDue) / COUNT(DISTINCT soh.CustomerID) AS RevenuePerCustomer
FROM Sales.SalesOrderHeader AS soh
INNER JOIN Sales.SalesTerritory AS st
    ON soh.TerritoryID = st.TerritoryID
GROUP BY
    st.Name
ORDER BY
    TotalRevenue DESC;

SELECT
    CustomerID,
    PersonID,
    StoreID
FROM Sales.Customer
ORDER BY CustomerID;

SELECT
    st.Name AS Territory,
    CASE
        WHEN c.PersonID IS NOT NULL THEN 'Person'
        WHEN c.StoreID IS NOT NULL THEN 'Store'
        ELSE 'Unknown'
    END AS CustomerType,
    COUNT(DISTINCT c.CustomerID) AS NumberOfCustomers,
    SUM(soh.TotalDue) AS TotalRevenue
FROM Sales.SalesOrderHeader AS soh
INNER JOIN Sales.Customer AS c
    ON soh.CustomerID = c.CustomerID
INNER JOIN Sales.SalesTerritory AS st
    ON soh.TerritoryID = st.TerritoryID
GROUP BY
    st.Name,
    CASE
        WHEN c.PersonID IS NOT NULL THEN 'Person'
        WHEN c.StoreID IS NOT NULL THEN 'Store'
        ELSE 'Unknown'
    END
ORDER BY
    st.Name,
    TotalRevenue DESC;

SELECT
    st.Name AS Territory,
    COUNT(DISTINCT soh.CustomerID) AS NumberOfCustomers,
    COUNT(soh.SalesOrderID) AS NumberOfOrders,
    SUM(soh.TotalDue) AS TotalRevenue,
    CAST(COUNT(soh.SalesOrderID) AS DECIMAL(10,2))
        / COUNT(DISTINCT soh.CustomerID) AS OrdersPerCustomer,
    SUM(soh.TotalDue)
        / COUNT(soh.SalesOrderID) AS AverageOrderValue
FROM Sales.SalesOrderHeader AS soh
INNER JOIN Sales.Customer AS c
    ON soh.CustomerID = c.CustomerID
INNER JOIN Sales.SalesTerritory AS st
    ON soh.TerritoryID = st.TerritoryID
GROUP BY
    st.Name
ORDER BY
    TotalRevenue DESC;

SELECT
    st.Name AS Territory,
    pc.Name AS CategoryName,
    SUM(sod.LineTotal) AS TotalRevenue
FROM Sales.SalesOrderHeader AS soh
INNER JOIN Sales.SalesTerritory AS st
    ON soh.TerritoryID = st.TerritoryID
INNER JOIN Sales.SalesOrderDetail AS sod
    ON soh.SalesOrderID = sod.SalesOrderID
INNER JOIN Production.Product AS p
    ON sod.ProductID = p.ProductID
INNER JOIN Production.ProductSubcategory AS ps
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID
INNER JOIN Production.ProductCategory AS pc
    ON ps.ProductCategoryID = pc.ProductCategoryID
GROUP BY
    st.Name,
    pc.Name
ORDER BY
    st.Name,
    TotalRevenue DESC;

SELECT
    st.Name AS Territory,
    ps.Name AS SubcategoryName,
    SUM(sod.LineTotal) AS TotalRevenue
FROM Sales.SalesOrderHeader AS soh
INNER JOIN Sales.SalesTerritory AS st
    ON soh.TerritoryID = st.TerritoryID
INNER JOIN Sales.SalesOrderDetail AS sod
    ON soh.SalesOrderID = sod.SalesOrderID
INNER JOIN Production.Product AS p
    ON sod.ProductID = p.ProductID
INNER JOIN Production.ProductSubcategory AS ps
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID
GROUP BY
    st.Name,
    ps.Name
ORDER BY
    st.Name,
    TotalRevenue DESC;

SELECT
    st.Name AS Territory,
    ps.Name AS SubcategoryName,
    SUM(sod.LineTotal) AS TotalRevenue
FROM Sales.SalesOrderHeader AS soh
INNER JOIN Sales.SalesTerritory AS st
    ON soh.TerritoryID = st.TerritoryID
INNER JOIN Sales.SalesOrderDetail AS sod
    ON soh.SalesOrderID = sod.SalesOrderID
INNER JOIN Production.Product AS p
    ON sod.ProductID = p.ProductID
INNER JOIN Production.ProductSubcategory AS ps
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID
WHERE st.Name IN (
    'Central',
    'Southeast',
    'Northeast',
    'Southwest',
    'Northwest'
)
GROUP BY
    st.Name,
    ps.Name
ORDER BY
    st.Name,
    TotalRevenue DESC;

SELECT
    st.Name AS Territory,
    pc.Name AS CategoryName,
    COUNT(DISTINCT soh.SalesOrderID) AS NumberOfOrders,
    SUM(sod.LineTotal) AS TotalRevenue,
    SUM(sod.LineTotal)
        / COUNT(DISTINCT soh.SalesOrderID) AS AverageOrderValue
FROM Sales.SalesOrderHeader AS soh
INNER JOIN Sales.SalesTerritory AS st
    ON soh.TerritoryID = st.TerritoryID
INNER JOIN Sales.SalesOrderDetail AS sod
    ON soh.SalesOrderID = sod.SalesOrderID
INNER JOIN Production.Product AS p
    ON sod.ProductID = p.ProductID
INNER JOIN Production.ProductSubcategory AS ps
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID
INNER JOIN Production.ProductCategory AS pc
    ON ps.ProductCategoryID = pc.ProductCategoryID
WHERE st.Name IN (
    'Central',
    'Southeast',
    'Northeast',
    'Southwest',
    'Northwest'
)
GROUP BY
    st.Name,
    pc.Name
ORDER BY
    st.Name,
    AverageOrderValue DESC;

SELECT
    st.Name AS Territory,
    p.Name AS ProductName,
    SUM(sod.LineTotal) AS TotalRevenue,
    SUM(sod.OrderQty) AS UnitsSold
FROM Sales.SalesOrderHeader AS soh
INNER JOIN Sales.SalesTerritory AS st
    ON soh.TerritoryID = st.TerritoryID
INNER JOIN Sales.SalesOrderDetail AS sod
    ON soh.SalesOrderID = sod.SalesOrderID
INNER JOIN Production.Product AS p
    ON sod.ProductID = p.ProductID
INNER JOIN Production.ProductSubcategory AS ps
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID
INNER JOIN Production.ProductCategory AS pc
    ON ps.ProductCategoryID = pc.ProductCategoryID
WHERE
    st.Name IN (
        'Central',
        'Southeast',
        'Northeast',
        'Southwest',
        'Northwest'
    )
    AND pc.Name = 'Bikes'
GROUP BY
    st.Name,
    p.Name
ORDER BY
    st.Name,
    TotalRevenue DESC;

SELECT
    st.Name AS Territory,
    p.Name AS ProductName,
    SUM(sod.LineTotal) AS TotalRevenue,
    SUM(sod.OrderQty) AS UnitsSold,
    SUM(sod.LineTotal) / SUM(sod.OrderQty) AS AverageUnitPrice
FROM Sales.SalesOrderHeader AS soh
INNER JOIN Sales.SalesTerritory AS st
    ON soh.TerritoryID = st.TerritoryID
INNER JOIN Sales.SalesOrderDetail AS sod
    ON soh.SalesOrderID = sod.SalesOrderID
INNER JOIN Production.Product AS p
    ON sod.ProductID = p.ProductID
INNER JOIN Production.ProductSubcategory AS ps
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID
INNER JOIN Production.ProductCategory AS pc
    ON ps.ProductCategoryID = pc.ProductCategoryID
WHERE
    st.Name IN (
        'Central',
        'Southeast',
        'Northeast',
        'Southwest',
        'Northwest'
    )
    AND pc.Name = 'Bikes'
GROUP BY
    st.Name,
    p.Name
ORDER BY
    st.Name,
    TotalRevenue DESC;

SELECT
    st.Name AS Territory,
    COUNT(DISTINCT soh.SalesOrderID) AS NumberOfOrders,
    SUM(sod.OrderQty) AS UnitsSold,
    CAST(SUM(sod.OrderQty) AS DECIMAL(12,2))
        / COUNT(DISTINCT soh.SalesOrderID) AS BikesPerOrder,
    SUM(sod.LineTotal) AS TotalRevenue,
    SUM(sod.LineTotal)
        / COUNT(DISTINCT soh.SalesOrderID) AS AverageOrderValue
FROM Sales.SalesOrderHeader AS soh
INNER JOIN Sales.SalesTerritory AS st
    ON soh.TerritoryID = st.TerritoryID
INNER JOIN Sales.SalesOrderDetail AS sod
    ON soh.SalesOrderID = sod.SalesOrderID
INNER JOIN Production.Product AS p
    ON sod.ProductID = p.ProductID
INNER JOIN Production.ProductSubcategory AS ps
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID
INNER JOIN Production.ProductCategory AS pc
    ON ps.ProductCategoryID = pc.ProductCategoryID
WHERE
    st.Name IN (
        'Central',
        'Southeast',
        'Northeast',
        'Southwest',
        'Northwest'
    )
    AND pc.Name = 'Bikes'
GROUP BY
    st.Name
ORDER BY
    AverageOrderValue DESC;

SELECT
    st.Name AS Territory,
    c.CustomerID,
    p.FirstName + ' ' + p.LastName AS CustomerName,
    COUNT(DISTINCT soh.SalesOrderID) AS NumberOfOrders,
    SUM(sod.OrderQty) AS BikesSold,
    SUM(sod.LineTotal) AS BikesRevenue,
    SUM(sod.LineTotal)
        / COUNT(DISTINCT soh.SalesOrderID) AS AverageOrderValue
FROM Sales.SalesOrderHeader AS soh
INNER JOIN Sales.SalesTerritory AS st
    ON soh.TerritoryID = st.TerritoryID
INNER JOIN Sales.Customer AS c
    ON soh.CustomerID = c.CustomerID
INNER JOIN Person.Person AS p
    ON c.PersonID = p.BusinessEntityID
INNER JOIN Sales.SalesOrderDetail AS sod
    ON soh.SalesOrderID = sod.SalesOrderID
INNER JOIN Production.Product AS pr
    ON sod.ProductID = pr.ProductID
INNER JOIN Production.ProductSubcategory AS ps
    ON pr.ProductSubcategoryID = ps.ProductSubcategoryID
INNER JOIN Production.ProductCategory AS pc
    ON ps.ProductCategoryID = pc.ProductCategoryID
WHERE
    st.Name IN (
        'Central',
        'Southeast',
        'Northeast',
        'Southwest',
        'Northwest'
    )
    AND pc.Name = 'Bikes'
GROUP BY
    st.Name,
    c.CustomerID,
    p.FirstName,
    p.LastName
ORDER BY
    st.Name,
    BikesRevenue DESC;

SELECT TOP 20
    c.CustomerID,
    p.FirstName + ' ' + p.LastName AS CustomerName,
    COUNT(DISTINCT soh.SalesOrderID) AS NumberOfOrders,
    SUM(sod.OrderQty) AS BikesSold,
    CAST(SUM(sod.OrderQty) AS DECIMAL(12,2))
        / COUNT(DISTINCT soh.SalesOrderID) AS BikesPerOrder,
    SUM(sod.LineTotal) AS BikesRevenue
FROM Sales.SalesOrderHeader AS soh
INNER JOIN Sales.SalesTerritory AS st
    ON soh.TerritoryID = st.TerritoryID
INNER JOIN Sales.Customer AS c
    ON soh.CustomerID = c.CustomerID
INNER JOIN Person.Person AS p
    ON c.PersonID = p.BusinessEntityID
INNER JOIN Sales.SalesOrderDetail AS sod
    ON soh.SalesOrderID = sod.SalesOrderID
INNER JOIN Production.Product AS pr
    ON sod.ProductID = pr.ProductID
INNER JOIN Production.ProductSubcategory AS ps
    ON pr.ProductSubcategoryID = ps.ProductSubcategoryID
INNER JOIN Production.ProductCategory AS pc
    ON ps.ProductCategoryID = pc.ProductCategoryID
WHERE
    st.Name = 'Central'
    AND pc.Name = 'Bikes'
GROUP BY
    c.CustomerID,
    p.FirstName,
    p.LastName
ORDER BY
    BikesPerOrder DESC;

SELECT
    st.Name AS Territory,
    COUNT(DISTINCT soh.CustomerID) AS NumberOfCustomers,
    COUNT(DISTINCT soh.SalesOrderID) AS NumberOfOrders,
    SUM(sod.OrderQty) AS BikesSold,
    CAST(SUM(sod.OrderQty) AS DECIMAL(12,2))
        / COUNT(DISTINCT soh.SalesOrderID) AS BikesPerOrder,
    SUM(sod.LineTotal) AS BikesRevenue,
    SUM(sod.LineTotal)
        / COUNT(DISTINCT soh.SalesOrderID) AS AverageOrderValue
FROM Sales.SalesOrderHeader AS soh
INNER JOIN Sales.SalesTerritory AS st
    ON soh.TerritoryID = st.TerritoryID
INNER JOIN Sales.SalesOrderDetail AS sod
    ON soh.SalesOrderID = sod.SalesOrderID
INNER JOIN Production.Product AS pr
    ON sod.ProductID = pr.ProductID
INNER JOIN Production.ProductSubcategory AS ps
    ON pr.ProductSubcategoryID = ps.ProductSubcategoryID
INNER JOIN Production.ProductCategory AS pc
    ON ps.ProductCategoryID = pc.ProductCategoryID
WHERE
    st.Name IN ('Central', 'Northeast', 'Southeast')
    AND pc.Name = 'Bikes'
GROUP BY
    st.Name
ORDER BY
    BikesPerOrder DESC;

WITH customer_bikes AS (
    SELECT
        st.Name AS Territory,
        c.CustomerID,
        p.FirstName + ' ' + p.LastName AS CustomerName,
        SUM(sod.LineTotal) AS BikesRevenue
    FROM Sales.SalesOrderHeader AS soh
    INNER JOIN Sales.SalesTerritory AS st
        ON soh.TerritoryID = st.TerritoryID
    INNER JOIN Sales.Customer AS c
        ON soh.CustomerID = c.CustomerID
    INNER JOIN Person.Person AS p
        ON c.PersonID = p.BusinessEntityID
    INNER JOIN Sales.SalesOrderDetail AS sod
        ON soh.SalesOrderID = sod.SalesOrderID
    INNER JOIN Production.Product AS pr
        ON sod.ProductID = pr.ProductID
    INNER JOIN Production.ProductSubcategory AS ps
        ON pr.ProductSubcategoryID = ps.ProductSubcategoryID
    INNER JOIN Production.ProductCategory AS pc
        ON ps.ProductCategoryID = pc.ProductCategoryID
    WHERE
        st.Name IN ('Central', 'Northeast', 'Southeast')
        AND pc.Name = 'Bikes'
    GROUP BY
        st.Name,
        c.CustomerID,
        p.FirstName,
        p.LastName
),
ranked_customers AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY Territory
            ORDER BY BikesRevenue DESC
        ) AS CustomerRank
    FROM customer_bikes
)
SELECT
    Territory,
    CustomerRank,
    CustomerName,
    BikesRevenue
FROM ranked_customers
WHERE CustomerRank <= 5
ORDER BY
    Territory,
    CustomerRank;

WITH bikes_per_order AS (
    SELECT
        st.Name AS Territory,
        soh.SalesOrderID,
        SUM(sod.OrderQty) AS BikesSold
    FROM Sales.SalesOrderHeader AS soh
    INNER JOIN Sales.SalesTerritory AS st
        ON soh.TerritoryID = st.TerritoryID
    INNER JOIN Sales.SalesOrderDetail AS sod
        ON soh.SalesOrderID = sod.SalesOrderID
    INNER JOIN Production.Product AS pr
        ON sod.ProductID = pr.ProductID
    INNER JOIN Production.ProductSubcategory AS ps
        ON pr.ProductSubcategoryID = ps.ProductSubcategoryID
    INNER JOIN Production.ProductCategory AS pc
        ON ps.ProductCategoryID = pc.ProductCategoryID
    WHERE
        st.Name IN ('Central', 'Northeast', 'Southeast')
        AND pc.Name = 'Bikes'
    GROUP BY
        st.Name,
        soh.SalesOrderID
)
SELECT
    Territory,
    COUNT(*) AS NumberOfOrders,
    MIN(BikesSold) AS MinBikesPerOrder,
    MAX(BikesSold) AS MaxBikesPerOrder,
    AVG(CAST(BikesSold AS DECIMAL(12,2))) AS AverageBikesPerOrder
FROM bikes_per_order
GROUP BY Territory
ORDER BY AverageBikesPerOrder DESC;

WITH bikes_per_order AS (
    SELECT
        st.Name AS Territory,
        soh.SalesOrderID,
        SUM(sod.OrderQty) AS BikesSold
    FROM Sales.SalesOrderHeader AS soh
    INNER JOIN Sales.SalesTerritory AS st
        ON soh.TerritoryID = st.TerritoryID
    INNER JOIN Sales.SalesOrderDetail AS sod
        ON soh.SalesOrderID = sod.SalesOrderID
    INNER JOIN Production.Product AS pr
        ON sod.ProductID = pr.ProductID
    INNER JOIN Production.ProductSubcategory AS ps
        ON pr.ProductSubcategoryID = ps.ProductSubcategoryID
    INNER JOIN Production.ProductCategory AS pc
        ON ps.ProductCategoryID = pc.ProductCategoryID
    WHERE
        st.Name IN ('Central', 'Northeast', 'Southeast')
        AND pc.Name = 'Bikes'
    GROUP BY
        st.Name,
        soh.SalesOrderID
)
SELECT DISTINCT
    Territory,
    AVG(CAST(BikesSold AS DECIMAL(12,2)))
        OVER (PARTITION BY Territory) AS AverageBikesPerOrder,
    PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY BikesSold)
        OVER (PARTITION BY Territory) AS MedianBikesPerOrder
FROM bikes_per_order
ORDER BY MedianBikesPerOrder DESC;

WITH bikes_per_order AS (
    SELECT
        st.Name AS Territory,
        soh.SalesOrderID,
        SUM(sod.OrderQty) AS BikesSold,
        SUM(sod.LineTotal) AS BikesRevenue
    FROM Sales.SalesOrderHeader AS soh
    INNER JOIN Sales.SalesTerritory AS st
        ON soh.TerritoryID = st.TerritoryID
    INNER JOIN Sales.SalesOrderDetail AS sod
        ON soh.SalesOrderID = sod.SalesOrderID
    INNER JOIN Production.Product AS pr
        ON sod.ProductID = pr.ProductID
    INNER JOIN Production.ProductSubcategory AS ps
        ON pr.ProductSubcategoryID = ps.ProductSubcategoryID
    INNER JOIN Production.ProductCategory AS pc
        ON ps.ProductCategoryID = pc.ProductCategoryID
    WHERE
        st.Name IN ('Central', 'Northeast', 'Southeast')
        AND pc.Name = 'Bikes'
    GROUP BY
        st.Name,
        soh.SalesOrderID
)
SELECT TOP 10
    Territory,
    SalesOrderID,
    BikesSold,
    BikesRevenue
FROM bikes_per_order
ORDER BY BikesSold DESC;

SELECT
    soh.SalesOrderID,
    st.Name AS Territory,
    pr.Name AS ProductName,
    sod.OrderQty,
    sod.UnitPrice,
    sod.LineTotal
FROM Sales.SalesOrderHeader AS soh
INNER JOIN Sales.SalesTerritory AS st
    ON soh.TerritoryID = st.TerritoryID
INNER JOIN Sales.SalesOrderDetail AS sod
    ON soh.SalesOrderID = sod.SalesOrderID
INNER JOIN Production.Product AS pr
    ON sod.ProductID = pr.ProductID
INNER JOIN Production.ProductSubcategory AS ps
    ON pr.ProductSubcategoryID = ps.ProductSubcategoryID
INNER JOIN Production.ProductCategory AS pc
    ON ps.ProductCategoryID = pc.ProductCategoryID
WHERE
    soh.SalesOrderID = 47395
    AND pc.Name = 'Bikes'
ORDER BY
    sod.LineTotal DESC;

SELECT
    st.Name AS Territory,
    ps.Name AS Subcategory,
    SUM(sod.OrderQty) AS UnitsSold,
    SUM(sod.LineTotal) AS Revenue,
    COUNT(DISTINCT soh.SalesOrderID) AS NumberOfOrders,
    SUM(sod.OrderQty) * 1.0
        / COUNT(DISTINCT soh.SalesOrderID) AS UnitsPerOrder
FROM Sales.SalesOrderHeader AS soh
INNER JOIN Sales.SalesTerritory AS st
    ON soh.TerritoryID = st.TerritoryID
INNER JOIN Sales.SalesOrderDetail AS sod
    ON soh.SalesOrderID = sod.SalesOrderID
INNER JOIN Production.Product AS pr
    ON sod.ProductID = pr.ProductID
INNER JOIN Production.ProductSubcategory AS ps
    ON pr.ProductSubcategoryID = ps.ProductSubcategoryID
INNER JOIN Production.ProductCategory AS pc
    ON ps.ProductCategoryID = pc.ProductCategoryID
WHERE
    st.Name IN ('Central', 'Northeast', 'Southeast')
    AND pc.Name = 'Bikes'
GROUP BY
    st.Name,
    ps.Name
ORDER BY
    st.Name,
    Revenue DESC;

SELECT
    st.Name AS Territory,
    ps.Name AS Subcategory,
    SUM(sod.OrderQty) AS UnitsSold,
    SUM(sod.LineTotal) AS Revenue,
    COUNT(DISTINCT soh.SalesOrderID) AS NumberOfOrders,
    SUM(sod.OrderQty) * 1.0
        / COUNT(DISTINCT soh.SalesOrderID) AS UnitsPerOrder
FROM Sales.SalesOrderHeader AS soh
INNER JOIN Sales.SalesTerritory AS st
    ON soh.TerritoryID = st.TerritoryID
INNER JOIN Sales.SalesOrderDetail AS sod
    ON soh.SalesOrderID = sod.SalesOrderID
INNER JOIN Production.Product AS pr
    ON sod.ProductID = pr.ProductID
INNER JOIN Production.ProductSubcategory AS ps
    ON pr.ProductSubcategoryID = ps.ProductSubcategoryID
INNER JOIN Production.ProductCategory AS pc
    ON ps.ProductCategoryID = pc.ProductCategoryID
WHERE
    st.Name IN ('Central', 'Northeast', 'Southeast')
    AND pc.Name = 'Bikes'
GROUP BY
    st.Name,
    ps.Name
ORDER BY
    st.Name,
    Revenue DESC;

WITH territory_subcategory_sales AS (
    SELECT
        st.Name AS Territory,
        ps.Name AS Subcategory,
        SUM(sod.OrderQty) AS UnitsSold,
        SUM(sod.LineTotal) AS Revenue
    FROM Sales.SalesOrderHeader AS soh
    INNER JOIN Sales.SalesTerritory AS st
        ON soh.TerritoryID = st.TerritoryID
    INNER JOIN Sales.SalesOrderDetail AS sod
        ON soh.SalesOrderID = sod.SalesOrderID
    INNER JOIN Production.Product AS pr
        ON sod.ProductID = pr.ProductID
    INNER JOIN Production.ProductSubcategory AS ps
        ON pr.ProductSubcategoryID = ps.ProductSubcategoryID
    INNER JOIN Production.ProductCategory AS pc
        ON ps.ProductCategoryID = pc.ProductCategoryID
    WHERE
        st.Name IN ('Central', 'Northeast', 'Southeast')
        AND pc.Name = 'Bikes'
    GROUP BY
        st.Name,
        ps.Name
)
SELECT
    Territory,
    Subcategory,
    UnitsSold,
    Revenue,
    Revenue
        / SUM(Revenue) OVER (
            PARTITION BY Territory
        ) * 100 AS RevenuePercentage
FROM territory_subcategory_sales
ORDER BY
    Territory,
    Revenue DESC;