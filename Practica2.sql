-- copia de la tabla Sales Order Header
select * into orderHeader
from AdventureWorks2019.Sales.SalesOrderHeader

-- copia de la tabla Sales Order Detail
select * into orderDetail
from AdventureWorks2019.Sales.SalesOrderDetail

-- copia de la tabla Customer
select * into customer
from AdventureWorks2019.Sales.Customer

-- copia de la tabla Customer
select * into Salesterritoty
from AdventureWorks2019.Sales.SalesTerritory

-- copia de la tabla Product
select * into Product
from AdventureWorks2019.Production.Product

-- copia de la tabla ProductCategory
select * into ProductCategory
from AdventureWorks2019.Production.ProductCategory

-- copia de la tabla ProductSubcategory
select * into ProductSubcategory
from AdventureWorks2019.Production.ProductSubcategory

-- copia de la tabla Person

SELECT BusinessEntityID, PersonType, NameStyle, Title,
FirstName, MiddleName, LastName, Suffix, EmailPromotion, rowguid, ModifiedDate
INTO Person 
FROM AdventureWorks2019.Person.Person;
--------------------------------------------------------------------------------------------------

-- a) Listar el producto más vendido de cada una de las categorías registradas en la base de datos
-- 1.1
WITH VentasProducto AS (
    SELECT 
        pc.Name AS Categoria,
        p.ProductID,
        p.Name AS Producto,
        SUM(od.OrderQty) AS CantidadVendida
    FROM orderDetail od
    JOIN Product p ON od.ProductID = p.ProductID
    JOIN ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
    JOIN ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
    GROUP BY pc.Name, p.ProductID, p.Name
),
ProductoMaximo AS (
    SELECT 
        Categoria,
        MAX(CantidadVendida) AS MaxCantidad
    FROM VentasProducto
    GROUP BY Categoria
)
SELECT vp.Categoria, vp.Producto, vp.CantidadVendida
FROM VentasProducto vp
JOIN ProductoMaximo pm
  ON vp.Categoria = pm.Categoria AND vp.CantidadVendida = pm.MaxCantidad
ORDER BY vp.Categoria;

-- 1.2
WITH ProductosVendidos AS (
    SELECT 
        od.ProductID,
        SUM(od.OrderQty) AS CantidadVendida
    FROM orderDetail od
    GROUP BY od.ProductID
),
ProductoConCategoria AS (
    SELECT 
        pv.ProductID,
        pv.CantidadVendida,
        p.Name AS Producto,
        pc.Name AS Categoria
    FROM ProductosVendidos pv
    JOIN Product p ON pv.ProductID = p.ProductID
    JOIN ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
    JOIN ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
),
Ranking AS (
    SELECT *,
           RANK() OVER (PARTITION BY Categoria ORDER BY CantidadVendida DESC) AS rk
    FROM ProductoConCategoria
)
SELECT Categoria, Producto, CantidadVendida
FROM Ranking
WHERE rk = 1
ORDER BY Categoria;

-- Consulta en la DB AdvetureWorks sin indices
WITH ProductosVendidos AS (
    SELECT 
        od.ProductID,
        SUM(od.OrderQty) AS CantidadVendida
    FROM AdventureWorks2019.Sales.SalesOrderDetail od
    GROUP BY od.ProductID
),
ProductoConCategoria AS (
    SELECT 
        pv.ProductID,
        pv.CantidadVendida,
        p.Name AS Producto,
        pc.Name AS Categoria
    FROM ProductosVendidos pv
    JOIN Product p ON pv.ProductID = p.ProductID
    JOIN ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
    JOIN ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
),
Ranking AS (
    SELECT *,
           RANK() OVER (PARTITION BY Categoria ORDER BY CantidadVendida DESC) AS rk
    FROM ProductoConCategoria
)
SELECT Categoria, Producto, CantidadVendida
FROM Ranking
WHERE rk = 1
ORDER BY Categoria;

-- b) Listar el nombre de los clientes con más órdenes por cada uno de los territorios registrados en la base de datos
-- 2.1
WITH OrdenesPorCliente AS (
    SELECT 
        st.Name AS Territorio,
        c.CustomerID,
        COUNT(oh.SalesOrderID) AS TotalOrdenes
    FROM orderHeader oh
    JOIN customer c ON oh.CustomerID = c.CustomerID
    JOIN Salesterritoty st ON oh.TerritoryID = st.TerritoryID
    GROUP BY st.Name, c.CustomerID
),
MaximoPorTerritorio AS (
    SELECT 
        Territorio,
        MAX(TotalOrdenes) AS MaxOrdenes
    FROM OrdenesPorCliente
    GROUP BY Territorio
)
SELECT 
    opc.Territorio,
    c.CustomerID,
    p.FirstName + ' ' + ISNULL(p.MiddleName + ' ', '') + p.LastName AS NombreCompleto,
    opc.TotalOrdenes
FROM OrdenesPorCliente opc
JOIN MaximoPorTerritorio mpt
  ON opc.Territorio = mpt.Territorio AND opc.TotalOrdenes = mpt.MaxOrdenes
JOIN customer c ON opc.CustomerID = c.CustomerID
JOIN Person p ON c.PersonID = p.BusinessEntityID
ORDER BY opc.Territorio;

-- 2.2
WITH OrdenesPorCliente AS (
    SELECT
        c.CustomerID,
        st.Name AS Territorio,
        COUNT(oh.SalesOrderID) AS TotalOrdenes
    FROM orderHeader oh
    JOIN customer c ON oh.CustomerID = c.CustomerID
    JOIN Salesterritoty st ON oh.TerritoryID = st.TerritoryID
    GROUP BY c.CustomerID, st.Name
),
RankingClientes AS (
    SELECT 
        opc.CustomerID,
        opc.Territorio,
        opc.TotalOrdenes,
        RANK() OVER (PARTITION BY opc.Territorio ORDER BY opc.TotalOrdenes DESC) AS rk
    FROM OrdenesPorCliente opc
),
TopClientes AS (
    SELECT 
        rc.CustomerID,
        rc.Territorio,
        rc.TotalOrdenes
    FROM RankingClientes rc
    WHERE rk = 1
)
SELECT 
    t.Territorio,
    CONCAT(p.FirstName, ' ', ISNULL(p.MiddleName + ' ', ''), p.LastName) AS NombreCliente,
    t.TotalOrdenes
FROM TopClientes t
JOIN customer c ON t.CustomerID = c.CustomerID
JOIN Person p ON c.PersonID = p.BusinessEntityID
ORDER BY t.Territorio;

-- 2.3
SELECT
    t.Name AS Territorio,
    CONCAT(p.FirstName, ' ', ISNULL(p.MiddleName + ' ', ''), p.LastName) AS NombreCliente,
    x.TotalOrdenes
FROM Salesterritoty t
CROSS APPLY (
    SELECT TOP 1 WITH TIES
        c.CustomerID,
        COUNT(oh.SalesOrderID) AS TotalOrdenes
    FROM orderHeader oh
    JOIN customer c ON oh.CustomerID = c.CustomerID
    WHERE oh.TerritoryID = t.TerritoryID
    GROUP BY c.CustomerID
    ORDER BY COUNT(oh.SalesOrderID) DESC
) x
JOIN customer c ON x.CustomerID = c.CustomerID
JOIN Person p ON c.PersonID = p.BusinessEntityID
ORDER BY t.Name;

---- Consulta a base datos AdventureWorks2019 sin indices
SELECT
    t.Name AS Territorio,
    CONCAT(p.FirstName, ' ', ISNULL(p.MiddleName + ' ', ''), p.LastName) AS NombreCliente,
    x.TotalOrdenes
FROM AdventureWorks2019.Sales.SalesTerritory t
CROSS APPLY (
    SELECT TOP 1 WITH TIES
        c.CustomerID,
        COUNT(oh.SalesOrderID) AS TotalOrdenes
    FROM AdventureWorks2019.Sales.SalesOrderHeader oh
    JOIN customer c ON oh.CustomerID = c.CustomerID
    WHERE oh.TerritoryID = t.TerritoryID
    GROUP BY c.CustomerID
    ORDER BY COUNT(oh.SalesOrderID) DESC
) x
JOIN customer c ON x.CustomerID = c.CustomerID
JOIN Person p ON c.PersonID = p.BusinessEntityID
ORDER BY t.Name;

-- c) Listar los datos generales de las órdenes que tengan al menos los mismos productos de la orden SalesOrderID = 43676
-- 3.1
WITH ProductosRequeridos AS (
    SELECT ProductID
    FROM orderDetail
    WHERE SalesOrderID = 43676
),
ConteoRequeridos AS (
    SELECT COUNT(*) AS TotalRequeridos
    FROM ProductosRequeridos
),
OrdenesConProductos AS (
    SELECT od.SalesOrderID, COUNT(DISTINCT od.ProductID) AS Coincidencias
    FROM orderDetail od
    JOIN ProductosRequeridos pr ON od.ProductID = pr.ProductID
    GROUP BY od.SalesOrderID
),
OrdenesValidas AS (
    SELECT ocp.SalesOrderID
    FROM OrdenesConProductos ocp, ConteoRequeridos cr
    WHERE ocp.Coincidencias = cr.TotalRequeridos
)
SELECT oh.*
FROM orderHeader oh
JOIN OrdenesValidas ov ON oh.SalesOrderID = ov.SalesOrderID
ORDER BY oh.SalesOrderID;

-- 3.2
WITH productos_objetivo AS (
    SELECT ProductID
    FROM orderDetail
    WHERE SalesOrderID = 43676
),
conteo_objetivo AS (
    SELECT COUNT(DISTINCT ProductID) AS totalProductos
    FROM productos_objetivo
),
ordenes_con_productos AS (
    SELECT od.SalesOrderID
    FROM orderDetail od
    JOIN productos_objetivo po ON od.ProductID = po.ProductID
    GROUP BY od.SalesOrderID
    HAVING COUNT(DISTINCT od.ProductID) = (SELECT totalProductos FROM conteo_objetivo)
)
SELECT oh.*
FROM orderHeader oh
JOIN ordenes_con_productos o ON oh.SalesOrderID = o.SalesOrderID
WHERE oh.SalesOrderID <> 43676 -- para excluir la original (opcional)
ORDER BY oh.OrderDate;

-- Consulta de AdventureWorks:
WITH ProductosRequeridos AS (
    SELECT ProductID
    FROM AdventureWorks2019.Sales.SalesOrderDetail
    WHERE SalesOrderID = 43676
),
ConteoRequeridos AS (
    SELECT COUNT(*) AS TotalRequeridos
    FROM ProductosRequeridos
),
OrdenesConProductos AS (
    SELECT od.SalesOrderID, COUNT(DISTINCT od.ProductID) AS Coincidencias
    FROM AdventureWorks2019.Sales.SalesOrderDetail od
    JOIN ProductosRequeridos pr ON od.ProductID = pr.ProductID
    GROUP BY od.SalesOrderID
),
OrdenesValidas AS (
    SELECT ocp.SalesOrderID
    FROM OrdenesConProductos ocp, ConteoRequeridos cr
    WHERE ocp.Coincidencias = cr.TotalRequeridos
)
SELECT oh.*
FROM AdventureWorks2019.Sales.SalesOrderHeader oh
JOIN OrdenesValidas ov ON oh.SalesOrderID = ov.SalesOrderID
ORDER BY oh.SalesOrderID;

-- Indices propuestos para las consultas de la base de datos de adventureworks:

-- Correspondientes a la consulta 1:
CREATE NONCLUSTERED INDEX IX_orderDetail_ProductID_OrderQty
ON orderDetail (ProductID)
INCLUDE (OrderQty, SalesOrderID);

CREATE NONCLUSTERED INDEX IX_Product_ProductSubcategoryID_Name
ON Product (ProductSubcategoryID, ProductID)
INCLUDE (Name);

CREATE NONCLUSTERED INDEX IX_ProductSubcategory_ProductCategoryID
ON ProductSubcategory (ProductSubcategoryID)
INCLUDE (ProductCategoryID);


CREATE NONCLUSTERED INDEX IX_ProductCategory_Name
ON ProductCategory (ProductCategoryID)
INCLUDE (Name);

-- Correspondientes a la consulta 2:
CREATE NONCLUSTERED INDEX IX_orderHeader_Territory_Customer
ON orderHeader (TerritoryID, CustomerID)
INCLUDE (SalesOrderID);

CREATE NONCLUSTERED INDEX IX_customer_CustomerID_PersonID
ON customer (CustomerID)
INCLUDE (PersonID);

CREATE NONCLUSTERED INDEX IX_Person_BusinessEntityID_Names
ON Person (BusinessEntityID)
INCLUDE (FirstName, MiddleName, LastName);

-- Correspondientes a la consulta 3:
go
CREATE NONCLUSTERED INDEX IX_orderDetail_SalesOrder_Product
ON orderDetail (SalesOrderID, ProductID);

go
CREATE NONCLUSTERED INDEX IX_orderHeader_SalesOrderID
ON orderHeader (SalesOrderID);

go
-- Index covering para orderDetail
CREATE NONCLUSTERED INDEX IX_orderDetail_Product_SalesOrder
ON orderDetail (ProductID, SalesOrderID);


-- 6 Consulta 3 con indices

CREATE NONCLUSTERED INDEX IX_datoscovid_Clasificacion_Morbilidades
ON datoscovid (CLASIFICACION_FINAL)
INCLUDE (DIABETES, OBESIDAD, HIPERTENSION);

SELECT 
    (SUM(CASE WHEN DIABETES = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS Porcentaje_Diabetes,
    (SUM(CASE WHEN OBESIDAD = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS Porcentaje_Obesidad,
    (SUM(CASE WHEN HIPERTENSION = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS Porcentaje_Hipertension
FROM datoscovid
WHERE CLASIFICACION_FINAL IN (1, 2, 3);  

-- 6 Consulta 4 con indices


CREATE NONCLUSTERED INDEX IX_datoscovid_Municipio_Entidad_Clasificacion_Morbilidades
ON datoscovid (MUNICIPIO_RES, ENTIDAD_RES, CLASIFICACION_FINAL)
INCLUDE (HIPERTENSION, OBESIDAD, DIABETES, TABAQUISMO);

SELECT DISTINCT c.entidad AS Estado, d.MUNICIPIO_RES AS Municipio
FROM datoscovid d
JOIN cat_entidades c ON d.ENTIDAD_RES = c.clave
WHERE NOT EXISTS (
    SELECT 1
    FROM datoscovid d2
    WHERE d2.MUNICIPIO_RES = d.MUNICIPIO_RES
      AND d2.ENTIDAD_RES = d.ENTIDAD_RES
      AND d2.CLASIFICACION_FINAL IN (1, 2, 3)  
      AND (d2.HIPERTENSION = 1 AND d2.OBESIDAD = 1 AND d2.DIABETES = 1 AND d2.TABAQUISMO = 1)  
)
ORDER BY c.entidad, d.MUNICIPIO_RES;

-- 6 consulta 5 con indices


CREATE NONCLUSTERED INDEX IX_datoscovid_Entidad_Recuperados_Neumonia
ON datoscovid (ENTIDAD_RES, CLASIFICACION_FINAL, NEUMONIA);


SELECT c.entidad AS Estado, COUNT(*) AS Total_Casos_Recuperados_Neumonia
FROM datoscovid d
JOIN cat_entidades c ON d.ENTIDAD_RES = c.clave
WHERE d.CLASIFICACION_FINAL = 3  
  AND d.NEUMONIA = 1             
GROUP BY c.entidad
ORDER BY Total_Casos_Recuperados_Neumonia DESC;
