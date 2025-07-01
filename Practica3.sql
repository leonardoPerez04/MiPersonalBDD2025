--Crear fragmentación:
create database datoscovid_norte
use datoscovid_norte
SELECT * INTO datoscovid_norte FROM covidHistorico.dbo.datoscovid 
WHERE ENTIDAD_RES IN ('02','03','08','05','19','24','28','10','25');
create database datoscovid_centro
use datoscovid_centro
SELECT * INTO datoscovid_centro FROM covidHistorico.dbo.datoscovid 
WHERE ENTIDAD_RES IN ('01','11','22','24','32','14','15','09','13','17','29','21');
create database datoscovid_sur
use datoscovid_sur
SELECT * INTO datoscovid_sur FROM covidHistorico.dbo.datoscovid 
WHERE ENTIDAD_RES IN ('12','20','07','30','27','04','31','23','16','06','18');

-- En MYSQL crear base de datos covidHistorico y crear tabla covidHistorico_sur vaciando los datos 
-- del archivo csv
create database covidHistorico
use covidHistorico
-- Vaciar datos de csv

EXEC sp_addlinkedserver   
   @server = 'MYSQL_SUR',                  -- nombre que le das al Linked Server
   @srvproduct = 'MySQL',                  -- nombre del proveedor (libre)
   @provider = 'MSDASQL',                  -- controlador ODBC
   @datasrc = 'mysql_covidHistorico_sur';             -- nombre del DSN creado (debe coincidir EXACTO)

-- Configura las credenciales de acceso
EXEC sp_addlinkedsrvlogin   
   @rmtsrvname = 'MYSQL_SUR',             -- mismo nombre del linked server
   @useself = 'false',
   @locallogin = NULL,                    -- permite cualquier usuario local
   @rmtuser = 'Alumno',            -- usuario de MySQL
   @rmtpassword = 'Estudiante1';  

SELECT *
FROM OPENQUERY(MYSQL_SUR, 'SELECT * FROM covidhistorico.covidhistorico_sur LIMIT 10');



	-----------------


EXEC sp_addlinkedserver
   @server = 'SQL_NORTE',
   @srvproduct = '',
   @provider = 'SQLNCLI11',          -- o 'MSOLEDBSQL' si usas la versión más reciente
   @datasrc = '192.168.229.8';       -- IP o nombre del servidor remoto

EXEC sp_addlinkedsrvlogin
   @rmtsrvname = 'SQL_NORTE',
   @useself = 'false',
   @locallogin = NULL,
   @rmtuser = 'sa',
   @rmtpassword = 'estudiante1';


SELECT *
FROM OPENQUERY(SQL_NORTE, 'SELECT TOP 10 * FROM datoscovid_norte.dbo.datoscovid_norte');



----------
EXEC sp_addlinkedserver
    @server = 'SQL_CENTRO',
    @srvproduct = '',
    @provider = 'SQLNCLI11',           -- o 'MSOLEDBSQL' si lo prefieres
    @datasrc = 'localhost';            -- también puede ser '.' o el nombre de tu instancia

EXEC sp_addlinkedsrvlogin
    @rmtsrvname = 'SQL_CENTRO',
    @useself = 'true';                 -- usa las mismas credenciales del usuario conectado

SELECT *
FROM OPENQUERY(SQL_CENTRO, 'SELECT TOP 10 * FROM datoscovid_centro.dbo.datoscovid_centro');


---------
-- Consulta 3
SELECT
    CAST(SUM(Total_Diabetes) * 100.0 / SUM(Total) AS DECIMAL(5,2)) AS Porcentaje_Diabetes,
    CAST(SUM(Total_Obesidad) * 100.0 / SUM(Total) AS DECIMAL(5,2)) AS Porcentaje_Obesidad,
    CAST(SUM(Total_Hipertension) * 100.0 / SUM(Total) AS DECIMAL(5,2)) AS Porcentaje_Hipertension
FROM (
    SELECT 
        COUNT(*) AS Total,
        SUM(CASE WHEN DIABETES = 1 THEN 1 ELSE 0 END) AS Total_Diabetes,
        SUM(CASE WHEN OBESIDAD = 1 THEN 1 ELSE 0 END) AS Total_Obesidad,
        SUM(CASE WHEN HIPERTENSION = 1 THEN 1 ELSE 0 END) AS Total_Hipertension
    FROM OPENQUERY(SQL_NORTE, '
        SELECT DIABETES, OBESIDAD, HIPERTENSION 
        FROM datoscovid_norte.dbo.datoscovid_norte 
        WHERE CLASIFICACION_FINAL IN (1,2,3)
    ')
    
    UNION ALL

    SELECT 
        COUNT(*),
        SUM(CASE WHEN DIABETES = 1 THEN 1 ELSE 0 END),
        SUM(CASE WHEN OBESIDAD = 1 THEN 1 ELSE 0 END),
        SUM(CASE WHEN HIPERTENSION = 1 THEN 1 ELSE 0 END)
    FROM OPENQUERY(SQL_CENTRO, '
        SELECT DIABETES, OBESIDAD, HIPERTENSION 
        FROM datoscovid_centro.dbo.datoscovid_centro 
        WHERE CLASIFICACION_FINAL IN (1,2,3)
    ')

    UNION ALL

    SELECT 
        COUNT(*),
        SUM(CASE WHEN DIABETES = 1 THEN 1 ELSE 0 END),
        SUM(CASE WHEN OBESIDAD = 1 THEN 1 ELSE 0 END),
        SUM(CASE WHEN HIPERTENSION = 1 THEN 1 ELSE 0 END)
    FROM OPENQUERY(MYSQL_SUR, '
        SELECT DIABETES, OBESIDAD, HIPERTENSION 
        FROM covidhistorico.covidHistorico_sur 
        WHERE CLASIFICACION_FINAL IN (1,2,3)
    ')
) AS SubTotales;



---------------------
-- Consulta 4
SELECT c.entidad AS Estado, COUNT(*) AS Total_Casos_Recuperados_Neumonia
FROM (
    -- Nodo Norte (SQL Server)
    SELECT 
        CAST(ENTIDAD_RES AS varchar(2)) AS ENTIDAD_RES,
        CAST(CLASIFICACION_FINAL AS int) AS CLASIFICACION_FINAL,
        CAST(NEUMONIA AS int) AS NEUMONIA
    FROM OPENQUERY(SQL_Norte, '
        SELECT 
            ENTIDAD_RES,
            CLASIFICACION_FINAL,
            NEUMONIA
        FROM datoscovid_norte.dbo.datoscovid_norte
        WHERE CLASIFICACION_FINAL = 3
          AND NEUMONIA = 1
    ')
    
    UNION ALL
    
    -- Nodo Centro (SQL Server)
    SELECT 
        CAST(ENTIDAD_RES AS varchar(2)) AS ENTIDAD_RES,
        CAST(CLASIFICACION_FINAL AS int) AS CLASIFICACION_FINAL,
        CAST(NEUMONIA AS int) AS NEUMONIA
    FROM OPENQUERY(SQL_Centro, '
        SELECT 
            ENTIDAD_RES,
            CLASIFICACION_FINAL,
            NEUMONIA
        FROM datoscovid_centro.dbo.datoscovid_centro
        WHERE CLASIFICACION_FINAL = 3
          AND NEUMONIA = 1
    ')
    
    UNION ALL
    
    -- Nodo Sur (MySQL)
    SELECT 
        CAST(ENTIDAD_RES AS varchar(2)) AS ENTIDAD_RES,
        CAST(CLASIFICACION_FINAL AS int) AS CLASIFICACION_FINAL,
        CAST(NEUMONIA AS int) AS NEUMONIA
    FROM OPENQUERY(MYSQL_SUR, '
        SELECT 
            ENTIDAD_RES,
            CLASIFICACION_FINAL,
            NEUMONIA
        FROM covidhistorico.covidHistorico_sur
        WHERE CLASIFICACION_FINAL = 3
          AND NEUMONIA = 1
    ')
) d
JOIN cat_entidades c ON CAST(d.ENTIDAD_RES AS varchar(2)) = CAST(c.clave AS varchar(2))
WHERE d.CLASIFICACION_FINAL = 3
  AND d.NEUMONIA = 1
GROUP BY c.entidad
ORDER BY Total_Casos_Recuperados_Neumonia DESC;






------------------------------------------
-- Consulta 5

SELECT Estado, SUM(Total) AS Total_Casos_Recuperados_Neumonia
FROM (
    SELECT CAST(c.entidad AS VARCHAR(100)) AS Estado, COUNT(*) AS Total
    FROM OPENQUERY(SQL_Norte, '
        SELECT d.ENTIDAD_RES
        FROM datoscovid_norte.dbo.datoscovid_norte d
        WHERE d.CLASIFICACION_FINAL = 3 AND d.NEUMONIA = 1
    ') d
    JOIN cat_entidades c 
        ON CAST(d.ENTIDAD_RES AS VARCHAR(10)) = CAST(c.clave AS VARCHAR(10))
    GROUP BY CAST(c.entidad AS VARCHAR(100))

    UNION ALL

    SELECT CAST(c.entidad AS VARCHAR(100)), COUNT(*)
    FROM OPENQUERY(SQL_Centro, '
        SELECT d.ENTIDAD_RES
        FROM datoscovid_centro.dbo.datoscovid_centro d
        WHERE d.CLASIFICACION_FINAL = 3 AND d.NEUMONIA = 1
    ') d
    JOIN cat_entidades c 
        ON CAST(d.ENTIDAD_RES AS VARCHAR(10)) = CAST(c.clave AS VARCHAR(10))
    GROUP BY CAST(c.entidad AS VARCHAR(100))

    UNION ALL

    SELECT CAST(c.entidad AS VARCHAR(100)), COUNT(*)
    FROM OPENQUERY(MYSQL_SUR, '
        SELECT d.ENTIDAD_RES
        FROM covidhistorico.covidHistorico_sur d
        WHERE d.CLASIFICACION_FINAL = 3 AND d.NEUMONIA = 1
    ') d
    JOIN cat_entidades c 
        ON CAST(d.ENTIDAD_RES AS VARCHAR(10)) = CAST(c.clave AS VARCHAR(10))
    GROUP BY CAST(c.entidad AS VARCHAR(100))
) AS Resultados
GROUP BY Estado
ORDER BY Total_Casos_Recuperados_Neumonia DESC;

------------------------------------------
-- Consulta 7
WITH CasosMensuales AS (
    SELECT 
        YEAR(CAST(d.FECHA_INGRESO AS date)) AS Año,
        MONTH(CAST(d.FECHA_INGRESO AS date)) AS Mes,
        c.entidad AS Estado,
        SUM(CASE WHEN d.CLASIFICACION_FINAL IN (1, 2, 3, 6) THEN 1 ELSE 0 END) AS Total_Casos
    FROM (
        -- Datos del Norte (SQL Server)
        SELECT 
            FECHA_INGRESO,
            CAST(ENTIDAD_RES AS varchar(2)) AS ENTIDAD_RES,
            CAST(CLASIFICACION_FINAL AS int) AS CLASIFICACION_FINAL
        FROM OPENQUERY(SQL_Norte, 'SELECT 
            TRY_CONVERT(date, FECHA_INGRESO) AS FECHA_INGRESO,
            ENTIDAD_RES,
            CLASIFICACION_FINAL 
        FROM datoscovid_norte.dbo.datoscovid_norte
        WHERE TRY_CONVERT(date, FECHA_INGRESO) IS NOT NULL')
        
        UNION ALL
        
        -- Datos del Centro (SQL Server)
        SELECT 
            FECHA_INGRESO,
            CAST(ENTIDAD_RES AS varchar(2)) AS ENTIDAD_RES,
            CAST(CLASIFICACION_FINAL AS int) AS CLASIFICACION_FINAL
        FROM OPENQUERY(SQL_Centro, 'SELECT 
            TRY_CONVERT(date, FECHA_INGRESO) AS FECHA_INGRESO,
            ENTIDAD_RES,
            CLASIFICACION_FINAL 
        FROM datoscovid_centro.dbo.datoscovid_centro
        WHERE TRY_CONVERT(date, FECHA_INGRESO) IS NOT NULL')
        
        UNION ALL
        
        -- Datos del Sur (MySQL)
        SELECT 
            CAST(FECHA_INGRESO AS date) AS FECHA_INGRESO,
            CAST(ENTIDAD_RES AS varchar(2)) AS ENTIDAD_RES,
            CAST(CLASIFICACION_FINAL AS int) AS CLASIFICACION_FINAL
        FROM OPENQUERY(MYSQL_SUR, 'SELECT 
            STR_TO_DATE(FECHA_INGRESO, ''%Y-%m-%d'') AS FECHA_INGRESO,
            ENTIDAD_RES,
            CLASIFICACION_FINAL 
        FROM covidhistorico.covidHistorico_sur
        WHERE STR_TO_DATE(FECHA_INGRESO, ''%Y-%m-%d'') IS NOT NULL')
    ) d
    JOIN cat_entidades c ON CAST(d.ENTIDAD_RES AS varchar(2)) = CAST(c.clave AS varchar(2))
    WHERE d.CLASIFICACION_FINAL IN (1, 2, 3, 6)
      AND YEAR(CAST(d.FECHA_INGRESO AS date)) IN (2020, 2021)
    GROUP BY YEAR(CAST(d.FECHA_INGRESO AS date)), MONTH(CAST(d.FECHA_INGRESO AS date)), c.entidad
),
RankingMensual AS (
    SELECT 
        Año,
        Estado,
        Mes,
        Total_Casos,
        RANK() OVER (PARTITION BY Año, Estado ORDER BY Total_Casos DESC) AS Ranking
    FROM CasosMensuales
)
SELECT 
    Año,
    Estado,
    Mes,
    Total_Casos
FROM RankingMensual
WHERE Ranking = 1
ORDER BY Año, Estado;
