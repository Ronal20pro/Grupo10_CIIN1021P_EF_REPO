# GRUPO10_CIIN1021P_EF_REPO

Proyecto integrador desarrollado para el curso de **Base de Datos Avanzadas y Big Data**, utilizando conjuntos de datos abiertos relacionados con las atenciones de salud y la mortalidad neonatal y perinatal de la región San Martín.

El proyecto comprende procesos de automatización en SQL Server, seguridad de bases de datos, respaldos y restauración, integración SQL–NoSQL, Data Warehouse, ETL, Business Intelligence y procesamiento Big Data.

## 📁 Estructura del repositorio

El repositorio está organizado en seis carpetas que contienen los archivos correspondientes a los componentes desarrollados.

```text
GRUPO10_CIIN1021P_EF_REPO/
│
├── 📁 Automatizacion_SQL/
├── 📁 BigData/
├── 📁 DataWarehouse_ETL/
├── 📁 MongoDB/
├── 📁 PowerBI/
├── 📁 Seguridad/
│
├── 📄 .gitattributes
└── 📄 README.md
```

### 📂 Descripción de las carpetas

- **Automatizacion_SQL:** creación de la base de datos `DataSalud_SanMartin`, tablas de preparación y definitivas, procedimientos almacenados, triggers de auditoría e integridad, función escalar y procesos de validación e ingesta de datos.
- **BigData:** notebook de Apache Spark para el procesamiento de información y archivo SQL para la comparación de resultados con SQL Server.
- **DataWarehouse_ETL:** scripts de creación del Data Warehouse `DW_DataSalud_SanMartin` y proceso ETL desarrollado en Python.
- **MongoDB:** archivo JSON con documentos de atenciones de salud utilizados para la integración con MongoDB.
- **PowerBI:** dashboard interactivo para el análisis y visualización de indicadores relacionados con las atenciones de salud.
- **Seguridad:** implementación de roles y permisos, respaldos completos y diferenciales, restauración de la base de datos e índice para la optimización de consultas.

## 📊 Conjuntos de datos utilizados

Para el desarrollo del proyecto se seleccionaron dos conjuntos de datos publicados por el **Gobierno Regional de San Martín (GRSM)** en la Plataforma Nacional de Datos Abiertos del Perú.

### Dataset 1: Reporte de atendidos y atenciones

Contiene información sobre los establecimientos de salud, ubicación geográfica, tipos de seguro, cantidad de personas atendidas y atenciones registradas en la región San Martín.

- **Entidad responsable:** Gobierno Regional de San Martín – GRSM.
- **Formato:** CSV.
- **Cantidad de campos:** 19.
- **Registros analizados:** 1 048 575.
- **Fecha de publicación:** 31/07/2024.
- **Fuente oficial:** [Reporte de atendidos y atenciones en los establecimientos de salud de San Martín](https://www.datosabiertos.gob.pe/dataset/reporte-de-atendidos-y-atenciones-en-los-establecimientos-de-salud-de-la-regi%C3%B3n-san-mart%C3%ADn-%E2%80%93).

### Dataset 2: Mortalidad neonatal y perinatal

Contiene información sobre los casos de mortalidad neonatal y perinatal registrados en la región San Martín.

- **Entidad responsable:** Gobierno Regional de San Martín – GRSM.
- **Formato:** CSV.
- **Cantidad de campos:** 48.
- **Registros analizados:** 3 293.
- **Fecha de publicación:** 27/06/2026.
- **Fuente oficial:** [Mortalidad neonatal y perinatal de la región San Martín](https://www.datosabiertos.gob.pe/dataset/mortalidad-neonatal-y-perinatal-de-la-regi%C3%B3n-san-mart%C3%ADn-%E2%80%93-gore-san-mart%C3%ADn-grsm).

**Nota:** Los archivos CSV originales no se incluyen en el repositorio. Pueden obtenerse desde los enlaces oficiales indicados anteriormente.

## ⚙️ Implementación en SQL Server

Se desarrolló la base de datos `DataSalud_SanMartin`, utilizando las tablas `stg_Atenciones` y `stg_Mortalidad` para la carga inicial de datos, así como las tablas definitivas `Atenciones` y `Mortalidad`.

Para automatizar el procesamiento de la información se implementaron:

- `sp_ValidarDatos`: procedimiento almacenado para la validación de registros.
- `sp_IngestarDatos`: procedimiento almacenado para la transformación y carga de información.
- `trg_Auditoria_Atenciones`: trigger para registrar operaciones de auditoría.
- `trg_Integridad_Atenciones`: trigger para controlar la integridad de los datos.
- `fn_NormalizarTexto`: función escalar para normalizar valores de texto.

La carga inicial se realiza mediante `BULK INSERT`, utilizando los archivos CSV descargados previamente.

## 🔐 Seguridad y recuperación

Se implementaron tres roles con permisos diferenciados: `rol_Administrador`, `rol_Operador` y `rol_Analista`.

También se desarrollaron procedimientos de respaldo completo y diferencial, restauración en la base de datos `DataSalud_SanMartin_Restore` y el índice no agrupado `IX_Atenciones_CodigoUnico` para optimizar las consultas.

## 📈 Data Warehouse, ETL y visualización

Se desarrolló el Data Warehouse `DW_DataSalud_SanMartin` para organizar los datos mediante un modelo dimensional.

Asimismo, se utilizaron Python para el proceso ETL, MongoDB para el trabajo con documentos JSON, Apache Spark para el procesamiento Big Data y Power BI para presentar indicadores mediante un dashboard interactivo.

## 🛠️ Tecnologías utilizadas

- Microsoft SQL Server.
- SQL Server Management Studio (SSMS).
- Python.
- MongoDB y MongoDB Compass.
- Apache Spark.
- Microsoft Power BI.
- Git y GitHub.

## 👥 Información del proyecto

**Grupo:** 10

**Curso:** Base de Datos Avanzadas y Big Data

**Evaluación:** Evaluación Final (EF)

**Año:** 2026
