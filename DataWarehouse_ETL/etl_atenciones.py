# LIBRERÍAS
import pandas as pd
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL
from datetime import datetime
from uuid import uuid4

# CONEXIÓN CON SQL SERVER
conexion = (
    r"DRIVER={ODBC Driver 18 for SQL Server};"
    r"SERVER=.\SQLEXPRESS;"
    "DATABASE=DW_DataSalud_SanMartin;"
    "Trusted_Connection=yes;"
    "Encrypt=yes;TrustServerCertificate=yes;"
)

motor = create_engine(
    URL.create("mssql+pyodbc", query={"odbc_connect": conexion}),
    fast_executemany=True
)

ejecucion = str(uuid4())

# FUNCIÓN PARA REGISTRAR CADA ETAPA
def registrar(etapa, inicio, registros, detalle, estado="Correcto"):
    with motor.begin() as cn:
        cn.execute(text("""
            INSERT INTO Log_ETL
            (Id_Ejecucion, Etapa, FechaInicio, FechaFin,
             Registros, Estado, Detalle)
            VALUES (:id, :etapa, :inicio, :fin,
                    :registros, :estado, :detalle)
        """), {
            "id": ejecucion, "etapa": etapa,
            "inicio": inicio, "fin": datetime.now(),
            "registros": registros, "estado": estado,
            "detalle": detalle
        })

# EXTRACCIÓN DE LOS DATOS
inicio = datetime.now()

datos = pd.read_sql_query("""
    SELECT Id_Atencion, ANIO, MES, DIA,
           PROVINCIA, DISTRITO, SEXO, ATENDIDOS, ATENCIONES
    FROM DataSalud_SanMartin.dbo.Atenciones
""", motor)

registrar(
    "Extracción", inicio, len(datos),
    "Lectura de los campos necesarios desde Atenciones."
)

print("Registros extraídos:", len(datos))
print(datos.head(10).to_string(index=False))

# TRANSFORMACIÓN DE LA FECHA
inicio = datetime.now()

datos["Fecha"] = pd.to_datetime(
    datos[["ANIO", "MES", "DIA"]].rename(
        columns={"ANIO": "year", "MES": "month", "DIA": "day"}
    ),
    errors="coerce"
)

invalidas = int(datos["Fecha"].isna().sum())

registrar(
    "Transformación de fecha", inicio, len(datos),
    f"Conversión de año, mes y día. Fechas inválidas: {invalidas}.",
    estado="Correcto" if invalidas == 0 else "Revisar"
)

print("Fechas inválidas:", invalidas)
print(datos[["ANIO", "MES", "DIA", "Fecha"]].head(10).to_string(index=False))

if invalidas > 0:
    raise ValueError("Se deben revisar las fechas inválidas antes de cargar.")

# NORMALIZACIÓN DE PROVINCIA, DISTRITO Y SEXO
for columna in ["PROVINCIA", "DISTRITO", "SEXO"]:
    inicio = datetime.now()

    datos[columna] = (
        datos[columna]
        .astype("string")
        .str.strip()
        .str.upper()
        .replace("", pd.NA)
        .fillna("NO REGISTRADO")
    )

    registrar(
        f"Normalización de {columna}", inicio, len(datos),
        "Mayúsculas, limpieza de espacios y vacíos como NO REGISTRADO."
    )

print("Textos normalizados:")
print(
    datos[["Fecha", "PROVINCIA", "DISTRITO", "SEXO"]]
    .head(10).to_string(index=False)
)

# CARGA DE LA DIMENSIÓN TIEMPO
inicio = datetime.now()

tiempo = datos[["Fecha"]].drop_duplicates().copy()
tiempo["Anio"] = tiempo["Fecha"].dt.year
tiempo["Mes"] = tiempo["Fecha"].dt.month
tiempo["Dia"] = tiempo["Fecha"].dt.day
tiempo["Fecha"] = tiempo["Fecha"].dt.date

with motor.begin() as cn:
    existentes = pd.read_sql_query("SELECT Fecha FROM Dim_Tiempo", cn)
    fechas_existentes = pd.to_datetime(existentes["Fecha"]).dt.date

    nuevas = tiempo[
        ~tiempo["Fecha"].isin(fechas_existentes)
    ]

    if not nuevas.empty:
        nuevas.to_sql(
            "Dim_Tiempo", cn,
            if_exists="append", index=False
        )

registrar(
    "Carga Dim_Tiempo", inicio, len(nuevas),
    "Inserción de fechas únicas que todavía no estaban registradas."
)

print("Fechas nuevas cargadas:", len(nuevas))
print(
    pd.read_sql_query(
        "SELECT TOP (10) * FROM Dim_Tiempo ORDER BY Fecha",
        motor
    ).to_string(index=False)
)

# CARGA DE LA DIMENSIÓN UBICACIÓN
inicio = datetime.now()

ubicacion = (
    datos[["PROVINCIA", "DISTRITO"]]
    .drop_duplicates()
    .rename(columns={"PROVINCIA": "Provincia", "DISTRITO": "Distrito"})
)
ubicacion.insert(0, "Departamento", "SAN MARTÍN")

columnas = ["Departamento", "Provincia", "Distrito"]

with motor.begin() as cn:
    existentes = pd.read_sql_query(
        "SELECT Departamento, Provincia, Distrito FROM Dim_Ubicacion",
        cn
    )

    comparacion = ubicacion.merge(
        existentes, on=columnas, how="left", indicator=True
    )
    nuevas = comparacion.loc[
        comparacion["_merge"] == "left_only", columnas
    ]

    if not nuevas.empty:
        nuevas.to_sql(
            "Dim_Ubicacion", cn,
            if_exists="append", index=False
        )

registrar(
    "Carga Dim_Ubicacion", inicio, len(nuevas),
    "Carga de ubicaciones únicas del dataset de San Martín."
)

print("Ubicaciones nuevas cargadas:", len(nuevas))
print(
    pd.read_sql_query(
        "SELECT TOP (10) * FROM Dim_Ubicacion ORDER BY Provincia, Distrito",
        motor
    ).to_string(index=False)
)

# CARGA DE LA DIMENSIÓN SEXO
inicio = datetime.now()

sexo = (
    datos[["SEXO"]]
    .drop_duplicates()
    .rename(columns={"SEXO": "Sexo"})
)

with motor.begin() as cn:
    existentes = pd.read_sql_query(
        "SELECT Sexo FROM Dim_Sexo", cn
    )

    nuevas = sexo[
        ~sexo["Sexo"].isin(existentes["Sexo"])
    ]

    if not nuevas.empty:
        nuevas.to_sql(
            "Dim_Sexo", cn,
            if_exists="append", index=False
        )

registrar(
    "Carga Dim_Sexo", inicio, len(nuevas),
    "Carga de categorías de sexo únicas del dataset."
)

print("Categorías de sexo nuevas cargadas:", len(nuevas))
print(
    pd.read_sql_query(
        "SELECT * FROM Dim_Sexo ORDER BY Id_Sexo",
        motor
    ).to_string(index=False)
)

# RELACIÓN DE LOS DATOS CON LAS DIMENSIONES
inicio = datetime.now()

dim_tiempo = pd.read_sql_query(
    "SELECT Id_Tiempo, Fecha FROM Dim_Tiempo", motor
)
dim_tiempo["Fecha"] = pd.to_datetime(dim_tiempo["Fecha"])

dim_ubicacion = pd.read_sql_query("""
    SELECT Id_Ubicacion, Provincia AS PROVINCIA,
           Distrito AS DISTRITO
    FROM Dim_Ubicacion
    WHERE Departamento = N'SAN MARTÍN'
""", motor)

dim_sexo = pd.read_sql_query(
    "SELECT Id_Sexo, Sexo AS SEXO FROM Dim_Sexo", motor
)

hechos = (
    datos.merge(dim_tiempo, on="Fecha", how="left", validate="many_to_one")
    .merge(dim_ubicacion, on=["PROVINCIA", "DISTRITO"],
           how="left", validate="many_to_one")
    .merge(dim_sexo, on="SEXO", how="left", validate="many_to_one")
)

claves = ["Id_Tiempo", "Id_Ubicacion", "Id_Sexo"]
sin_dimension = int(hechos[claves].isna().any(axis=1).sum())

registrar(
    "Asignación de claves", inicio, len(hechos),
    f"Relación con las tres dimensiones. Sin coincidencia: {sin_dimension}.",
    estado="Correcto" if sin_dimension == 0 else "Revisar"
)

if sin_dimension > 0:
    raise ValueError("Existen registros sin dimensión; se detiene la carga.")

hechos = hechos[
    ["Id_Atencion"] + claves + ["ATENDIDOS", "ATENCIONES"]
].rename(columns={"ATENDIDOS": "Atendidos", "ATENCIONES": "Atenciones"})

# CARGA DE LA TABLA DE HECHOS
inicio = datetime.now()

try:
    with motor.begin() as cn:
        existentes = pd.read_sql_query(
            "SELECT Id_Atencion FROM Fact_Atenciones", cn
        )
        nuevos = hechos[
            ~hechos["Id_Atencion"].isin(existentes["Id_Atencion"])
        ]

        if not nuevos.empty:
            nuevos.to_sql(
                "Fact_Atenciones", cn,
                if_exists="append", index=False, chunksize=10000
            )

    registrar(
        "Carga Fact_Atenciones", inicio, len(nuevos),
        "Carga de registros nuevos relacionados con las tres dimensiones."
    )
    print("Registros nuevos cargados en Fact_Atenciones:", len(nuevos))

except Exception as error:
    registrar(
        "Carga Fact_Atenciones", inicio, 0,
        str(error)[:500], estado="Error"
    )
    raise