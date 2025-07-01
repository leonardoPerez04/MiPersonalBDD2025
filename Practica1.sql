use covidHistorico
go


/************************
Numero de consulta: #1 Listar el top 5 de las entidades con
más casos confirmados por cada uno de los años.

Requisitos: 
			
			Se utilizara la tabla datoscovid para el manejo de las cifras.
			Se utilizara la tabla cat_entidades para haer coincidencia y saber
			exactamente a que entidad en su atributo nombre estamos rankeando.
			FECHA_INGRESO: Para conocer el anio de ingreso por enfermedad.
			ENTIDAD_RES: Para saber la entidad de residencia del paciente.
			CLASIFICACION FINAL: Para recopilar solo los casos confirmados de covid.

Signficado de valores en catalogo:
			
			CLASIFICACION_FINAL: 1,2,3 refiere a casos positivos confirmados por diferentes 
			medios.
			

Responsable de la consulta: Daniel Galicia Cobaxin

Descripcion de consulta: 

			-Se utilizo with para crear una tabla temporal nombrada como 'Ranking', esto con ayuda
			del comando as.

			-Se nombro a la tabla datoscovid como 'd' y a la tabla cat_entidades como 'c'

			-Se recopilo la informacion de solamente el anio del paciente siendo nombrado 'Anio', 
			la entiendad residencia y la suma total de los casos de dicha entidad
			nombrandolo como 'TotalCasos' y siendo contados por el comando Count.
			
			-Se ocupo el comando Rank para poder asiignar un numero de 'ranking' a cada fila dentro
			de un grupo que en este caso esta dado por group by la fecha de ingreso y la entidad
			residencia.
			
			-Se dividen los datos segun el anio de la fecha ingreso, siendo ordenados
			de manera descendente y nombrando a esta columa como 'Posicion'.
			
			-Finalmente se recogen solamente las primeras 5 filas de cada anio, 
			dando asi el top 5 del 2020,2021 y 2022.


Comentarios:
	RANK():Asigna un número de ranking a cada fila dentro de un grupo de filas.
	PARTITTION BY(): Divide los datos en grupos (o particiones) basados en una o más columnas.

*************************/

WITH Ranking AS (
    SELECT 
        YEAR(d.FECHA_INGRESO) AS Anio,
        d.ENTIDAD_RES,
        c.entidad AS NombreEntidad,
        COUNT(*) AS TotalCasos,
        RANK() OVER (PARTITION BY YEAR(d.FECHA_INGRESO) ORDER BY COUNT(*) DESC) AS Posicion
    FROM datoscovid d
    JOIN cat_entidades c ON d.ENTIDAD_RES = c.clave  
    WHERE d.CLASIFICACION_FINAL IN (1, 2, 3) 
    GROUP BY YEAR(d.FECHA_INGRESO), d.ENTIDAD_RES, c.entidad
)
SELECT Anio, ENTIDAD_RES, NombreEntidad, TotalCasos, Posicion
FROM Ranking
WHERE Posicion <= 5;


/************************************
Numero de consulta: #2 Listar el municipio con más casos confirmados recuperados por estado y por año.

Requisitos:
			Tabla datoscovid
			Tabla cat_entidades
			FECHA_INGRESO: Especificamente el anio en el que ingresaron.
			ENTIDAD_RES: Entidades de residencia del paciente
			entidad: Para visualizar el nombre de la entidad de residenia
			MUNICIPIO_RES: Municipio de residencia del paciente
			TIPO_PACIENTE: Pare recopilar a los pacientes recuperados
			FECHA_DEF: Para excluir a los fallecidos

Descripcion en catalogo:

			TIPO_PACIENTE: 1 para pacientes recuperados
			FECHA_DEF: Formato '9999-99-99' para pacientes que no fallecieron
			

Responsable de la consulta: Daniel Galicia Cobaxin

Descripcion de la consulta:
			
			-Se crea una tabla temporal llamada 'Ranking'.
			-Se recopila solo el anio de la FECHA_INGRESO y se nombra como 'Anio'.
			-Se nombra a la tabla datoscovid como 'd' y a la tabla cat_entidades como 'c'.
			-Se recopila la entidad de residencia, entidad y el municipio de residencia.
			-Se cuentan el total de casos con Count segun la clasificacion 1,2,3 en CLASIFICACION_FINAL, que el paciente sea de tipo 1 y la fecha
			de defuncion coincida con el formato para los pacientes que no fallecieron.
			-Se asigna un rank por los grupos dividos segun la fecha de ingreso y entidad, ademas de contarlos y ordenarlos de manera descendente 
			asignandole el nombre de posicion.
			-Con ayuda de un join se hace coincidir la clave en datoscovid y cat_entidades para poder obtener el nonmbre exacto de la entidad de residencia
			-Se agrupan los datos por el anio de la fecha de ingreso, entidad de residencia, entidad y municipio de residencia
			-Finalmente solo se rescata el top 1 de cada estado, en cada anio

Comentarios:
	RANK():Asigna un número de ranking a cada fila dentro de un grupo de filas.
	PARTITTION BY(): Divide los datos en grupos (o particiones) basados en una o más columnas.

************************************/

WITH Ranking AS (
    SELECT 
        YEAR(d.FECHA_INGRESO) AS Anio,
        d.ENTIDAD_RES,
        c.entidad AS NombreEntidad,
        d.MUNICIPIO_RES,
        COUNT(*) AS TotalCasos,
        RANK() OVER (PARTITION BY YEAR(d.FECHA_INGRESO), d.ENTIDAD_RES ORDER BY COUNT(*) DESC) AS Posicion
    FROM datoscovid d
    JOIN cat_entidades c ON d.ENTIDAD_RES = c.clave  
    WHERE d.CLASIFICACION_FINAL IN (1, 2, 3)  
      AND d.TIPO_PACIENTE = 1  
      AND d.FECHA_DEF = '9999-99-99'  
    GROUP BY YEAR(d.FECHA_INGRESO), d.ENTIDAD_RES, c.entidad, d.MUNICIPIO_RES
)
SELECT Anio, ENTIDAD_RES, NombreEntidad, MUNICIPIO_RES, TotalCasos
FROM Ranking
WHERE Posicion = 1;  




/******************************************

Numero de consulta: #3 Listar el porcentaje de casos confirmados en cada una de 
					las siguientes morbilidades a nivel nacional: diabetes, obesidad e hipertensión.

Requisitos: 
			
			Tabla datoscovid
			CLASIFICIACION_FINAL: Para extraer solo casos confirmados
			columas de morbilidades: Diabetes, obesidad e hipertension

Descripcion en catalogo: 
						
						CLASIFICACION_FINAL: Para filtrar solo los casos confirmados (IN (1, 2, 3)).
						DIABETES: Indica si el paciente tiene diabetes (1 = Sí).
						OBESIDAD: Indica si el paciente tiene obesidad (1 = Sí).
						HIPERTENSION: Indica si el paciente tiene hipertensión (1 = Sí).


Responsable de la consulta: Daniel Galicia Cobaxin

Descripcion de la consulta:
		
						-Se utilizo la funcion SUM para sumar los casos en donde si hay diabetes, obesidad o hipertension (1)
						-Cuando el caso es cierto, es decir, que hay alguna de las 3 anteriores morbilidades se suma 1 
						de lo contrario se suma 0
						-Al resultado de cada suma, se le multiplica por 100 y se divide entre el resultado de count, es decir de los
						confirmados
						-Finalmente se obtienen solo de los casos confirmados de CLASIFICACION_FINAL 


						

******************************************/

SELECT 
    (SUM(CASE WHEN DIABETES = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS Porcentaje_Diabetes,
    (SUM(CASE WHEN OBESIDAD = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS Porcentaje_Obesidad,
    (SUM(CASE WHEN HIPERTENSION = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS Porcentaje_Hipertension
FROM datoscovid
WHERE CLASIFICACION_FINAL IN (1, 2, 3);  




/***************************************
Numero de consulta: #4 Listar los municipios que no tengan casos confirmados en todas las morbilidades:
					hipertensión, obesidad, diabetes, tabaquismo.

Requisitos:
			
			Tabla datoscovid y cat_entidades
			entidad: De la tabla cat_entidades para obtener los nombres de los estados
			MUNICIPIO_RES: El municipio de residencia de cada pasiente para las operaciones
			CLASIFICACION_FINAL: Para excluir a los que si estan conirmados
			HIPERTENSION,OBESIDAD, DIABTES Y TABAQUISMO: Para verificar que cumplan con la condicion de 1 (confirmacion)

Descripcion en catalogo:
			
			CLASIFICACION_FINAL: Para filtrar solo los casos confirmados (IN (1, 2, 3)). Estos son de confirmacion
			HIPERTENSION, OBESIDAD, DIABETES, TABAQUISMO: Indican si el paciente tiene estas morbilidades (1 = Sí).

Descripcion de la consulta: 
			
			-Se obtienen de manera unica los datos entidad de la tabla cat_entidades
			-Se obtiene el MUNICIPIO RESIENTE de la tabla datoscovid
			-Se unen las tablas para obtener el nombre exacto del estado
			-Pasamos al where NOT EXISTS donde buscaremos excluir a los municipios donde haya al menos
			1 caso confirmado con todas las morbilidades
			-Se agrupan por estado finalmente

Responsablde la consulta: Daniel Galicia Cobaxin

***************************************/
use covidHistorico
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




/*********************************************
Numero de la consulta: #5. Listar los estados con más casos recuperados con neumonía.

Requesitos:
			
			Tabla datoscovid y cat_entidades
			entidad: Para obtener los nombres de los estados
			ENTIDAD_RES: Para las operaciones de conteo 
			NEUMONIA: Condicion para el conteo 

Descripcion en catalogo: 
			CLASIFICACION_FINAL: Para filtrar solo los casos confirmados recuperados (=3).
			NEUMONIA: Para filtrar solo los casos con neumonía (=1).



Responsable de la consulta: Daniel Galicia Cobaxin


Descripcion de la consulta:
			
			-Se obtiene entidad de la tabla cat_entidades, nombrando esta columna como Estado
			-Se hace el conteo con Count de los casos donde solo sean recuperados, es decir, el caso 3
			-Se hace el conteo agregando la condicion obligatoria de que el elemento Neumonia sea igual a 1
			-A la columna del conteo se le nombro Total_Casos_Recuperados_Neumonia
			-Finalmente se agrupan por entidad y se ordenan de manera descendente para tener hasta arriba los estados con mas casos
			segun la columna del conteo.



*********************************************/

SELECT c.entidad AS Estado, COUNT(*) AS Total_Casos_Recuperados_Neumonia
FROM datoscovid d
JOIN cat_entidades c ON d.ENTIDAD_RES = c.clave
WHERE d.CLASIFICACION_FINAL = 3  
  AND d.NEUMONIA = 1             
GROUP BY c.entidad
ORDER BY Total_Casos_Recuperados_Neumonia DESC;


/**********************************************************

Numero de consulta: #6 Listar el total de casos confirmados/sospechosos por estado en cada uno de los años
registrados en la base de datos.

Requisitos: 
			
			Tabla cat_entidades y datoscovid
			FECHA_INGRESO: Para extraer el anio de la fecha de ingreso del paciente
			entidad: Para extraer el nombre de la entidad residente dentro de la tabla cat_entidades
			CLASIFICACION_FINAL: Para solo extraer los casos confirmados y sospechosos

Descripcion en catalogo:
			
			CLASIFICACION_FINAL: Para contar solo casos confirmados y sospechosos (1, 2, 3, 6).
		
Responsable de la consulta: Daniel Galicia Cobaxin

Descripcion de la consulta:
			
			-Se obtiene el anio de la fecha de ingreso, la cual se nombra como Anio, la entidad dentro de la tabla cat_entidad 
			la cual se nombra 'Estado'.
			-Se hace el conteo por estado en donde CLASIFICACION_FINAL haga coindicencia con 1,2,3 y 6, esto en 2020,2021 y 2022.
			-Se hace un join entre las tablas y las claves de entidades para obtener el nombre de la entidad de residencia.
			-Se agrupa y ordena por anio, entidad y Total de casos de manera descendente.


**********************************************************/

SELECT 
    YEAR(d.FECHA_INGRESO) AS Anio,
    c.entidad AS Estado,
    COUNT(*) AS Total_Casos
FROM datoscovid d
JOIN cat_entidades c ON d.ENTIDAD_RES = c.clave
WHERE d.CLASIFICACION_FINAL IN (1, 2, 3,6) 
GROUP BY YEAR(d.FECHA_INGRESO), c.entidad
ORDER BY Anio, Total_Casos DESC;




/*************************************************************

Numero de consulta: #7 Para el año 2020 y 2021 cuál fue el mes con más casos registrados, confirmados, sospechosos, por estado
					registrado en la base de datos.

Requisitos:
			Tabla cat_entidades
			Tabla datoscovid
			FECHA_INGRESO: Tanto Anio como Mes para las operaciones
			CLASIFICACION_FINAL: Para el filtrado de confirmados y sospechosos
			entidad: Para encontrar el nombre del estado en cat_entidades segun las que coincida con datoscovid

Descripcion del catalogo: 
			
			CLASIFICACION_FINAL: Para distinguir entre casos confirmados (1, 2, 3) y sospechosos (6).

Responsable de la consulta: Daniel Galicia Cobaxin

Descripcion de la consulta:
			-Se obtiene el mes y anio, asi como la entidad para la columna que se nombro como 'Estado'
			-Se inicia el conteo, que se nombrara como 'Total_Casos'
			-Se suman los casos cuando son confirmados y sospechosos, nombrandolo 'Total_Casos'
			-Se hace  la union de las tablas para encontrar el nombre exacto de la entidad residente
			-Se filtra para solo los anios 2020 y 2021
			-Se agrupa segun el anio, mes y por la entidad
			-Hasta este punto se tiene el conteo total por mes, estado y anio (2020 y 2021)
			
			-En la siguiente ventana, tenemos a Ranking mensual, el cual se ocupa por medio de Rank asignar una 'posicion' a cada grupo dividido
			con ayuda del comando PARTITTION, sobre el anio y estado los cuales estan ordenados por total de casos de manera descendente, llamado
			ranking
			-Finalmente se extrae el ranking 1 de cada grupo

Comentarios:
	RANK():Asigna un número de ranking a cada fila dentro de un grupo de filas.
	PARTITTION BY(): Divide los datos en grupos (o particiones) basados en una o más columnas.

***************************************************************/

WITH CasosMensuales AS (
    SELECT 
        YEAR(d.FECHA_INGRESO) AS Año,
        MONTH(d.FECHA_INGRESO) AS Mes,
        c.entidad AS Estado,
        SUM(CASE WHEN d.CLASIFICACION_FINAL IN (1, 2, 3, 6) THEN 1 ELSE 0 END) AS Total_Casos
    FROM datoscovid d
    JOIN cat_entidades c ON d.ENTIDAD_RES = c.clave
    WHERE YEAR(d.FECHA_INGRESO) IN (2020, 2021)
    GROUP BY YEAR(d.FECHA_INGRESO), MONTH(d.FECHA_INGRESO), c.entidad
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







/*
	Consulta #8.
		Listar el municipio con menos defunciones en el mes con más casos confirmados con neumonía
		en los años 2020 y 2021.

	Requisitos:
		Para esta consulta, se utiliza la tabla "datoscovid", específicamente las columnas:
		- FECHA_DEF: Fecha de defunción (tipo nvarchar).
		- NEUMONIA: Indica si el caso presentó neumonía (valor 1 = "Sí").
		- CLASIFICACION_FINAL: Clasificación del caso (valores 1, 2, 3 = casos confirmados de COVID-19).
		- MUNICIPIO_RES: Municipio de residencia del paciente.

		Debido a que la columna FECHA_DEF es de tipo nvarchar, se utiliza la función "TRY_CONVERT" para convertirla a tipo DATE.
		Además, se usa "NULLIF" para manejar valores vacíos o inválidos en FECHA_DEF.

	Significado de los valores de los catálogos:
		- Neumonia = 1: Hace referencia al catálogo "Cátalogo SI_NO", donde 1 significa "Sí".
		- Clasificacion_Final (1, 2, 3): Hace referencia al catálogo "Cat CLASIFICACION_FINAL_COVID", donde 1, 2, 3 son casos confirmados de COVID-19.

	Responsable de la consulta:
		Pérez López Leonardo.

	Comentarios:
		Esta consulta tiene como objetivo identificar el municipio con menos defunciones en el mes con más casos confirmados de COVID-19
		con neumonía durante los años 2020 y 2021. Para lograr esto, se siguen los siguientes pasos:

		1. Filtrado de casos:
		   - Se filtran los casos confirmados de COVID-19 (Clasificacion_Final IN (1, 2, 3)).
		   - Se consideran solo los casos que presentaron neumonía (Neumonia = 1).
		   - Se excluyen registros con FECHA_DEF nula o inválida (Fecha_Def IS NOT NULL y Fecha_Def != '9999-99-99').

		2. Conversión de fechas:
		   - Se utiliza "TRY_CONVERT(DATE, NULLIF(Fecha_Def, ''))" para convertir FECHA_DEF a tipo DATE.
		   - "NULLIF(Fecha_Def, '')" maneja valores vacíos, devolviendo NULL si FECHA_DEF está vacía.
		   - "TRY_CONVERT" intenta convertir a DATE, devolviendo NULL si la conversión falla.

		3. Identificación del mes con más neumonías:
		   - Se utiliza una subconsulta para encontrar el mes con más casos de neumonía en cada año (2020 y 2021).
		   - La subconsulta agrupa por año y mes, cuenta los casos de neumonía y utiliza "RANK()" para identificar el mes con más casos.
		   - "RANK() OVER (PARTITION BY YEAR(...) ORDER BY COUNT(*) DESC)" asigna un rango a cada mes, donde 1 es el mes con más casos.

		4. Conteo de defunciones por municipio:
		   - Se agrupan los casos por municipio (MUNICIPIO_RES), año y mes.
		   - Se cuenta el número de defunciones en cada municipio usando "COUNT(*) AS TotalDefunciones".

		5. Filtrado del mes con más neumonías:
		   - Se filtran los resultados para incluir solo los meses identificados en la subconsulta como los de mayor incidencia de neumonía.

		6. Ordenamiento y selección:
		   - Los resultados se ordenan por año, mes y TotalDefunciones en orden ascendente (ORDER BY Anio, Mes, TotalDefunciones ASC).
		   - Se selecciona el municipio con menos defunciones en cada mes y año.

	Funciones utilizadas:
		- TRY_CONVERT: Intenta convertir un valor a un tipo de dato específico (en este caso, DATE). Si la conversión falla, devuelve NULL.
		- NULLIF: Devuelve NULL si el valor de la columna coincide con el segundo argumento (en este caso, una cadena vacía).
		- YEAR: 
	*/

	SELECT 
    MUNICIPIO_RES AS Municipio,
    COUNT(*) AS TotalDefunciones,
    YEAR(TRY_CONVERT(DATE, NULLIF(Fecha_Def, ''))) AS Anio,
    MONTH(TRY_CONVERT(DATE, NULLIF(Fecha_Def, ''))) AS Mes
FROM datoscovid
WHERE 
    Clasificacion_Final IN (1, 2, 3) 
    AND Neumonia = 1 
    AND Fecha_Def IS NOT NULL
    AND Fecha_Def != '9999-99-99'  
    AND TRY_CONVERT(DATE, NULLIF(Fecha_Def, '')) IS NOT NULL
    AND YEAR(TRY_CONVERT(DATE, NULLIF(Fecha_Def, ''))) IN (2020, 2021)
    AND MONTH(TRY_CONVERT(DATE, NULLIF(Fecha_Def, ''))) IN (
        
        SELECT Mes
        FROM (
            SELECT 
                YEAR(TRY_CONVERT(DATE, NULLIF(Fecha_Def, ''))) AS Anio,
                MONTH(TRY_CONVERT(DATE, NULLIF(Fecha_Def, ''))) AS Mes,
                COUNT(*) AS TotalCasos,
                RANK() OVER (PARTITION BY YEAR(TRY_CONVERT(DATE, NULLIF(Fecha_Def, ''))) 
                            ORDER BY COUNT(*) DESC) AS Rango
            FROM datoscovid
            WHERE 
                Neumonia = 1 
                AND Clasificacion_Final IN (1, 2, 3) 
                AND Fecha_Def IS NOT NULL
                AND Fecha_Def != '9999-99-99' 
                AND TRY_CONVERT(DATE, NULLIF(Fecha_Def, '')) IS NOT NULL
                AND YEAR(TRY_CONVERT(DATE, NULLIF(Fecha_Def, ''))) IN (2020, 2021)
            GROUP BY YEAR(TRY_CONVERT(DATE, NULLIF(Fecha_Def, ''))), 
                     MONTH(TRY_CONVERT(DATE, NULLIF(Fecha_Def, '')))
        ) AS MesMaxNeumonia
        WHERE Rango = 1  
    )
GROUP BY MUNICIPIO_RES, YEAR(TRY_CONVERT(DATE, NULLIF(Fecha_Def, ''))), 
         MONTH(TRY_CONVERT(DATE, NULLIF(Fecha_Def, '')))
ORDER BY Anio, Mes, TotalDefunciones ASC;




/*
	Consulta #9. 
		Listar el top 3 de municipios con menos casos recuperados en el año 2021.

	Requisitos:
		Para esta consulta, se utiliza la tabla "datoscovid", específicamente las columnas:
		- ENTIDAD_RES: Entidad federativa (estado) de residencia del paciente.
		- FECHA_DEF: Fecha de defunción (tipo nvarchar).
		- CLASIFICACION_FINAL: Clasificación del caso (valores 1, 2, 3 = casos confirmados de COVID-19).

		Debido a que la columna FECHA_DEF es de tipo nvarchar, se utiliza la función "TRY_CONVERT" para convertirla a tipo DATE.

	Significado de los valores de los catálogos:
		- Clasificacion_Final (1, 2, 3): Hace referencia al catálogo "Cat CLASIFICACION_FINAL_COVID", donde 1, 2, 3 son casos confirmados de COVID-19.

	Responsable de la consulta:
		Pérez López Leonardo

	Comentarios:
		Esta consulta tiene como objetivo identificar los 3 municipios con menos casos recuperados de COVID-19 en el año 2021.
		Para lograr esto, se siguen los siguientes pasos:

		1. Filtrado de casos:
		   - Se filtran los casos confirmados de COVID-19 (Clasificacion_Final IN (1, 2, 3)).
		   - Se consideran solo los casos del año 2021 (YEAR(TRY_CONVERT(DATE, NULLIF(Fecha_Def, ''))) = 2021).
		   - Se excluyen registros con FECHA_DEF nula o inválida (TRY_CONVERT(DATE, NULLIF(Fecha_Def, '')) IS NOT NULL).

		2. Conversión de fechas:
		   - Se utiliza "TRY_CONVERT(DATE, NULLIF(Fecha_Def, ''))" para convertir FECHA_DEF a tipo DATE.
		3. Conteo de casos recuperados por entidad:
		   - Se agrupan los casos por entidad federativa (ENTIDAD_RES).
		   - Se cuenta el número de casos recuperados en cada entidad usando "COUNT(*) AS TotalRecuperados".

		4. Ordenamiento y selección:
		   - Los resultados se ordenan por el número de casos recuperados en orden ascendente (ORDER BY TotalRecuperados ASC).
		   - Se seleccionan los 3 primeros registros usando "TOP 3", que corresponden a las entidades con menos casos recuperados.

	Funciones utilizadas:
		- YEAR: Extrae el año de una fecha.
		- COUNT: Cuenta el número de filas que cumplen con una condición.
*/

SELECT TOP 3 
    MUNICIPIO_RES, 
    COUNT(*) AS TotalRecuperados
FROM datoscovid
WHERE 
    Clasificacion_Final IN (1, 2, 3) 
    AND YEAR(TRY_CONVERT(DATE, NULLIF(Fecha_Def, ''))) = 2021 
GROUP BY MUNICIPIO_RES
ORDER BY TotalRecuperados ASC; 




/*
	Consulta #10. 
		Listar el porcentaje de casos confirmados por genéro en los años 2020 y 2021
	Requisitos: 
		Para esta consulta me apoye de la tabla datoscovid, usando las columnas "SEXO", "CLASIFICACION_FINAL" y "FECHAD_INGRESO"
	Significado de los valores de los catalogos: 
		Clasificacion_Final (1,2,3) hace referencia al catalogo "Cat CLASIFICACION_FINAL_COVID"	 donde 1,2,3 son aquellos casos confirmados
		Sexo (1 y 2): 1. Mujer, 2. Hombre
	Responsable de la consulta: 
		Pérez López Leonardo
	Comentarios:
		Solo consideré registros donde Clasificacion_Final_Covid indique casos confirmados (1, 2, 3), después,
		solo incluí los años 2020 y 2021, asegurando que Fecha_INGRESO sea una fecha válida con TRY_CONVERT(),
		agrupé por la columna Sexo para contar los casos por cada género, calculé el pocentaje con COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () 
		que nos da el porcentaje de cada género respecto al total y finalmente, se ordena por Porcentaje DESC 
		para mostrar primero el género con más casos.
*/


SELECT 
    Sexo, 
    COUNT(*) AS TotalCasos,
    (COUNT(*) * 100.0) / SUM(COUNT(*)) OVER () AS Porcentaje
FROM datoscovid
WHERE 
    Clasificacion_Final IN (1, 2, 3)  
    AND YEAR(TRY_CONVERT(DATE, NULLIF(Fecha_INGRESO, ''))) IN (2020, 2021) 
GROUP BY Sexo, YEAR (FECHA_INGRESO)
ORDER BY Porcentaje DESC;



/*
	Consulta #11. 
		Listar el porcentaje de casos hospitalizados por estado en el año 2020
	Requisitos: 
		Para esta consulta me apoye de la tabla datoscovid, usando las columnas "ENTIDAD_UM", "CLASIFICACION_FINAL" y "FECHAD_INGRESO"
	Significado de los valores de los catalogos: 
		Clasificacion_Final (1,2,3) hace referencia al catalogo "Cat CLASIFICACION_FINAL_COVID"	 donde 1,2,3 son aquellos casos confirmados
		Del catalogo de ENTIDAD_UM obtenemos el numero de la entidad
	Responsable de la consulta: 
		Pérez López Leonardo
	Comentarios: 
		En entidad_UM almacena la entidad federativa donde fue atendido el paciente, posteriormente,
		solo consideré registros donde Clasificacion_Final_Covid indique casos confirmados (1, 2, 3), hice un filtrado por añi (2020)
		usando YEAR(TRY_CONVERT(DATE, NULLIF(Fecha_INGRESO, ''))) = 2020, que convierte Fecha_INGRESO a DATE, 
		evitando errores con valores inválidos o vacíos, después, hice un filtrado por hospitalización con 
		Tipo_Paciente = 2 (según el catalogo "TIPO_PACIENTE", 1 = Ambulatorio, 2 = Hospitalizado), luego, caculé el porcentaje de casos hospitalizados por estado respecto al total
		de hospitalizados con (COUNT(*) * 100.0) / SUM(COUNT(*)) OVER () y finalmente ordené por porcentaje descendente con
		Porcentaje DESC para mostrar los estados con más hospitalizaciones primero.
*/

SELECT 
    Entidad_UM AS Estado,  
    COUNT(*) AS TotalHospitalizados,
    (COUNT(*) * 100.0) / SUM(COUNT(*)) OVER () AS Porcentaje
FROM datoscovid
WHERE 
    Clasificacion_Final IN (1, 2, 3)
    AND YEAR(TRY_CONVERT(DATE, NULLIF(Fecha_INGRESO, ''))) = 2020  
    AND (Tipo_Paciente = 2) 
GROUP BY Entidad_UM
ORDER BY Porcentaje DESC;

/*
	Consulta #12. 
		Listar total de casos negativos por estado en los años 2020 y 2021
	Requisitos: 
		Para esta consulta me apoye de la tabla datoscovid, usando las columnas "ENTIDAD_RES", "CLASIFICACION_FINAL" y "FECHAD_INGRESO"
	Significado de los valores de los catalogos: 
		Clasificacion_Final (1,2,3) hace referencia al catalogo "Cat CLASIFICACION_FINAL_COVID"	 donde 1,2,3 son aquellos casos confirmados
		Del catalogo de ENTIDAD_UM obtenemos el numero de la entidad
	Responsable de la consulta: 
		Pérez López Leonardo
	Comentarios: 
		Entidad_RES AS Estado representa la entidad federativa donde se atendió el paciente, luego hice un filtrado de casos negativos
		con Clasificacion_Final_Covid NOT IN (1, 2, 3) donde se excluyen los casos confirmados (1, 2, 3), 
		ya que los negativos tienen otros valores en la base de datos, luego, hice un filtrado por años (2020 y 2021) usando 
		YEAR(TRY_CONVERT(DATE, NULLIF(Fecha_Ingreso, ''))) IN (2020, 2021), poterior a esto, hice un agrupamiento por ENTIDAD_RES y 
		finalmente ocupe ORDER BY TotalCasosNegativos DESC para ordenar el TotalCasosNegativos por orden descendente.
*/

SELECT 
    Entidad_Res AS Estado,  
    COUNT(*) AS TotalCasosNegativos
FROM datoscovid
WHERE 
    Clasificacion_Final = 7 
    AND YEAR(FECHA_INGRESO) IN (2020, 2021)  
GROUP BY Entidad_Res, YEAR(FECHA_INGRESO)
ORDER BY TotalCasosNegativos DESC;

/*
	Consulta #13. 
		Listar el porcentaje de casos confirmados por género en el rango de edades de 20 a 30 años, de 31 a 40 años, de 41 a 50 años,
		de 51 a 60 años y mayores a 60 años a nivel nacional
	Requisitos: 
		Para esta consulta me apoye de la tabla datoscovid, usando las columnas "ENTIDAD_UM", "CLASIFICACION_FINAL", "FECHAD_DEF" y "EDAD"
	Significado de los valores de los catalogos: 
		Clasificacion_Final (1,2,3) hace referencia al catalogo "Cat CLASIFICACION_FINAL_COVID"	 donde 1,2,3 son aquellos casos confirmados
		En el caso del sexo 1 y 2 pertenecen a: 1. Mujeres, 2. Hombres
	Responsable de la consulta: 
		Pérez López Leonardo
	Comentarios: 
		En esta consulta me apoyé de varias instrucciones, la que más resalta es la de "CASE-WHEN", que nos sirve para comparar una expresión
		con un conjunto de expresiones sencillas para determinar el resultado. Como se puede ver en la consulta, el "CASE-WHEN" nos ayudó para
		poder compara entre todos los rangos de edades solicitados en la problemática, agrupando entres sus rangos de edades y el sexo.
		Posterior a esto, hicimos uso de un "COUNT" para contar el número de filas con las que coinciden, después calculamos los promedios
		y usamos "GROUP BY" para agrupar y ordenamos por "RANGO_EDAD" y "SEXO"
*/

SELECT 
    CASE 
        WHEN Edad BETWEEN 20 AND 30 THEN '20-30 años'
        WHEN Edad BETWEEN 31 AND 40 THEN '31-40 años'
        WHEN Edad BETWEEN 41 AND 50 THEN '41-50 años'
        WHEN Edad BETWEEN 51 AND 60 THEN '51-60 años'
        ELSE 'Más de 60 años'
    END AS Rango_Edad,
    Sexo,
    COUNT(*) AS TotalCasos,
    (COUNT(*) * 100.0) / SUM(COUNT(*)) OVER (PARTITION BY 
        CASE 
            WHEN Edad BETWEEN 20 AND 30 THEN '20-30 años'
            WHEN Edad BETWEEN 31 AND 40 THEN '31-40 años'
            WHEN Edad BETWEEN 41 AND 50 THEN '41-50 años'
            WHEN Edad BETWEEN 51 AND 60 THEN '51-60 años'
            ELSE 'Más de 60 años'
        END) AS Porcentaje
FROM datoscovid
WHERE 
    Clasificacion_Final IN (1, 2, 3) 
    AND Edad >= 20 
GROUP BY 
    CASE 
        WHEN Edad BETWEEN 20 AND 30 THEN '20-30 años'
        WHEN Edad BETWEEN 31 AND 40 THEN '31-40 años'
        WHEN Edad BETWEEN 41 AND 50 THEN '41-50 años'
        WHEN Edad BETWEEN 51 AND 60 THEN '51-60 años'
        ELSE 'Más de 60 años'
    END,
    Sexo
ORDER BY Rango_Edad, Sexo;


/*
	Consulta #14. 
		Listar el rango de edad con más casos confirmados y que fallecieron en los años 2020 y 2021
	Requisitos: 
		Para esta consulta me apoye de la tabla datoscovid, usando las columnas "CLASIFICACION_FINAL", "FECHAD_DEF" y "EDAD"
	Significado de los valores de los catalogos: 
		Clasificacion_Final (1,2,3) hace referencia al catalogo "Cat CLASIFICACION_FINAL_COVID"	 donde 1,2,3 son aquellos casos confirmados
	Responsable de la consulta: 
		Pérez López Leonardo
	Comentarios: 
		Dentro de la sunbconsulta, clasifiqué la edades en los rangos que necesitamos (así como en la consulta anterior), con FECHA_DEF IS NOT NULL
		se filtran solo casos de covid confirmados y fallecidos y me aseguré que la fecha sea de 2020 y 2021 convirtiendo el tipo de dato
		con "TRY_CONVERT". Agrupé los datos por el RANGO_EDAD, ordeno el TOTAL_FALLECIDOS en orden descendente y filtro el top 1.
*/


SELECT TOP 1 Rango_Edad, COUNT(*) AS TotalFallecidos
FROM (
    SELECT 
        CASE 
            WHEN Edad BETWEEN 20 AND 30 THEN '20-30 años'
            WHEN Edad BETWEEN 31 AND 40 THEN '31-40 años'
            WHEN Edad BETWEEN 41 AND 50 THEN '41-50 años'
            WHEN Edad BETWEEN 51 AND 60 THEN '51-60 años'
            ELSE 'Más de 60 años'
        END AS Rango_Edad
    FROM datoscovid
    WHERE 
        Clasificacion_Final IN (1, 2, 3)  
        AND TRY_CONVERT(DATE, NULLIF(Fecha_Def, '')) IS NOT NULL
        AND YEAR(TRY_CONVERT(DATE, NULLIF(Fecha_Def, ''))) IN (2020, 2021)
) AS T1
GROUP BY Rango_Edad
ORDER BY TotalFallecidos DESC;



