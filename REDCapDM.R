# REDCapDM

# Enlace: 
# https://bruigtp.github.io/REDCapDM/

# Instalar el paquete - versión de GitHub

# install.packages("remotes")
remotes::install_github("bruigtp/REDCapDM")

library(REDCapDM)

# Ruta
# setwd(r"(C:\Users\jcarmezim\Desktop\demo_redcapdm\data)") # solo en caso de RStudio

# Importar datos de REDCap: redcap_data()

## A partir de ficheros exportados de REDCap
dataset <- redcap_data(
  data_path = "data/PruebaDemoREDCapDM_R_2026-11-11_0817.r", # script de R de REDCap
  dic_path = "data/PruebaDemoREDCapDM_DataDictionary_2026-11-11.csv", # diccionario
  event_path = "data/PruebaDemoREDCapDM_InstrumentDesignations_2026-11-11.csv" # solo si es longitudinal
)

# Si el diccionario se ha guardado con ";" como separador:
dataset <- redcap_data(
  data_path = "data/PruebaDemoREDCapDM_R_2026-11-11_0817.r",
  dic_path = "data/PruebaDemoREDCapDM_DataDictionary_2026-11-11_pyc.csv",
  sep = ";"
)

## Desde API: El token funciona como una contraseña (no compartir), podemos guardarlo en el .Renviron (usethis::edit_r_environ()), por ejemplo: REDCAP_TOKEN_MYPROJECT=ABCDEF0123456789
dataset_api <- redcap_data(
  uri = "https://redcap.igtp.cat/api/",
  token = Sys.getenv("REDCAP_TOKEN_MYPROJECT")
)

# Descargar solo algunas variables
dataset_api <- redcap_data(
  uri = "https://redcap.igtp.cat/api/",
  token = Sys.getenv("REDCAP_TOKEN_MYPROJECT"),
  filter_field = c("record_id", "age", "copd")
)

# Incluir los campos de encuestas (timestamps, identificador de encuesta)
dataset_api <- redcap_data(
  uri = "https://redcap.igtp.cat/api/",
  token = Sys.getenv("REDCAP_TOKEN_MYPROJECT"),
  survey_fields = TRUE
)

## Missing Data Codes (argumento `rm_mdc`) - Ferran

# rm_mdc = TRUE (por defecto): se eliminan los códigos
#   - Campos de texto numéricos/fecha y campos categóricos (radio, dropdown, yes/no, true/false): se pasa todo a NA
#   - Eliminamos las columnas de checkbox creadas para los códigos
#   - Warning que indica que se han encontrado mdc.
#
# rm_mdc = FALSE: se conserva la información del código
#   - Campos categóricos: se conserva el código como una categoria más
#   - Eliminamos las columnas de checkbox creadas para los códigos solo si no contienen información
#   - Campos de texto numéricos/fecha: pasa a ser NA porque un número no puede guardar "UNK"
dataset_mdc <- redcap_data(
  data_path = "data/PruebaDemoREDCapDM_R_2026-11-11_0817.r",
  dic_path = "data/PruebaDemoREDCapDM_DataDictionary_2026-11-11.csv",
  event_path = "data/PruebaDemoREDCapDM_InstrumentDesignations_2026-11-11.csv",
  rm_mdc = FALSE
)

## Resultado de la función:

# Una lista con:
#   $data - los datos (una fila por registro, y por evento si es longitudinal)
#   $dictionary - el diccionario de REDCap (nombres, etiquetas, tipos, lógicas...)
#   $event_form - qué formularios se recogen en cada evento (solo proyectos longitudinales)


# missings: rd_missplot() - Ferran
rd_missplot(covican) # NOTA: Poner límite de caracteres en la label

# Nombres de las variables en vez de las etiquetas
rd_missplot(covican, use_field_labels = FALSE)

# Solo las 10 variables con más missings y conteo en vez de %
rd_missplot(covican, max_vars = 10, show_percentages = FALSE, use_field_labels = FALSE)

# Gráfico de barras: un solo evento
baseline <- covican

baseline$data <- covican$data |>
  dplyr::filter(redcap_event_name == "baseline_visit_arm_1") |>
  dplyr::select(-c(redcap_event_name, redcap_event_name.factor))

rd_missplot(baseline, max_vars = 15)

# Mostrar también las variables sin missings (ocultas por defecto)
rd_missplot(baseline, drop_complete = FALSE, use_field_labels = FALSE)

# Al ser un ggplot, se puede personalizar:
p <- rd_missplot(baseline, max_vars = 15)
p + ggplot2::labs(title = "COVICAN: missings en la visita basal")
# ggplot2::ggsave("missings_basal.png", p, width = 8, height = 6)


# Procesar los datos paso a paso 

# Todas las funciones:
#  - aceptan la lista entera (datos + diccionario + event_form) como primer argumento,
#  - devuelven la misma lista, actualizada, más un elemento `results` que describe lo que se ha hecho,
# así que se pueden encadenar con el pipe en el orden necesario

## rd_dates(): fechas

# Convierte a Date/POSIXct los campos validados como fecha/fecha-hora en REDCap
dates_demo <- covican

dates_demo$data$d_birth <- as.character(dates_demo$data$d_birth)

class(dates_demo$data$d_birth) # "character"

dates_demo <- rd_dates(dates_demo)

class(dates_demo$data$d_birth) # "Date"

## rd_recalculate(): revisar los campos calculados

# Traduce a R la fórmula de cada campo calculado de REDCap, lo recalcula y compara el resultado con el valor guardado en REDCap. 
covican_recalc <- rd_recalculate(covican) 

# Resumen
covican_recalc$results

# Cuando no coinciden, añade una variable nueva `<campo>_recalc` al lado de la original
covican_recalc$data[1:5, c("record_id", "d_birth", "d_admission", "age", "age_recalc")]

# Excluir campos cuya fórmula no se puede (o no se quiere) recalcular
covican_recalc <- rd_recalculate(covican, exclude = "screening_fail_crit")

## rd_checkbox(): transformación de checkboxes

# REDCap exporta una columna por cada opción del checkbox (`campo___código`) con 0/1, y su versión .factor con "Unchecked"/"Checked"
names(covican$data)[grep("___", names(covican$data))][1:4]

table(covican$data$type_underlying_disease___0)
table(covican$data$type_underlying_disease___0.factor)

# Por defecto:
#  - cambia las etiquetas de la versión .factor (por defecto "No"/"Yes")
#  - renombra las columnas con el texto de la opción
#  - actualiza el diccionario y los branching logic que usan los checkboxes
cb <- rd_checkbox(covican)

names(cb$data)[grep("type_underlying_disease|underlying_disease_hemato", names(cb$data))][1:4]

table(cb$data$type_underlying_disease_haematological_cancer)
table(cb$data$type_underlying_disease_haematological_cancer.factor)

# Etiquetas propias y manteniendo los nombres de REDCap
cb <- rd_checkbox(covican, checkbox_labels = c("No", "Sí"), checkbox_names = FALSE)

table(cb$data$type_underlying_disease___0.factor)

# En REDCap un checkbox nunca está vacío: si no se marca, se guarda "Unchecked" (0), aunque la pregunta no se haya llegado a mostrar por el branching logic
# `na_logic` decide cuándo convertimos esos valores en NA:
#   "none" -> nunca: todo lo no marcado cuenta como "No"
#   "missing" -> NA solo si el branching logic no se puede evaluar (falta la variable de la que depende)
#   "eval" -> NA también si el branching logic no se cumple: la pregunta no se mostró, así que no es un "No" real
# Ejemplo: `underlying_disease_hemato` solo se pregunta si el cáncer es hematológico. Con "eval", los 103 pacientes sin cáncer hematológico pasan de "No" a NA
cb_missing <- rd_checkbox(covican, na_logic = "missing")
table(cb_missing$data$underlying_disease_hemato_acute_myeloid_leukemia.factor, useNA = "ifany")

cb_eval <- rd_checkbox(covican, na_logic = "eval")
table(cb_eval$data$underlying_disease_hemato_acute_myeloid_leukemia.factor, useNA = "ifany")

## rd_factor(): Sustituye cada campo categórico por su versión .factor y elimina las columnas .factor
fct <- rd_factor(covican)
str(fct$data$copd)

# Exclusión variables
fct <- rd_factor(covican, exclude = c("copd", "available_analytics", "urine_culture"))
str(fct$data$copd)

## rd_dictionary(): traducir a R las lógicas del diccionario

# Convierte branching logic y los cálculos de lenguaje de REDCap a R
dic_demo <- covican |>
  rd_factor() |> # Cambiamos los valores de los factores (de num. a categorico)
  rd_dictionary()

dic_demo$dictionary[dic_demo$dictionary$field_name %in% c("type_dm", "potassium"), c("field_name", "branching_logic_show_field_only_if")]

dic_demo$results

# Los campos cuya lógica no se ha podido traducir aparecen en los resultados (pequeña trampa para demostrarlo)
dic_demo <- covican |>
  rd_factor() 

dic_demo$dictionary$branching_logic_show_field_only_if[dic_demo$dictionary$field_name == "type_dm"] <- "[hola][dm]='1'"

dic_demo_fake <- dic_demo |> 
  rd_dictionary()

dic_demo_fake$results

## rd_delete_vars(): eliminar variables
del <- rd_delete_vars(covican, vars = c("potassium", "leuk_lymph"))

# Tanto de los datos como del diccionario 
c("potassium", "leuk_lymph") %in% names(del$data)
c("potassium", "leuk_lymph") %in% del$dictionary$field_name

# Por patrón
del <- rd_delete_vars(covican, pattern = c("_complete$", "_timestamp$")) # de normal eliminamos el estado de los formularios (`_complete`) y los timestamps de las encuestas (`_timestamp`)

## rd_insert_na(): poner valores a NA según una determinada condición (Útil para campos sin branching logic en REDCap que deberían estar vacíos en algunos casos)

# Ejemplo inventado: la diabetes solo se recoje en pacientes de 65 años o más
table(covican$data$dm, useNA = "ifany")

cb_na <- rd_insert_na(covican,
                      vars = "dm",
                      filter = "age < 65")
table(cb_na$data$dm, useNA = "ifany")

## rd_rlogic(): traducir una expresión concreta de REDCap (usada en distintas funciones del paquete)

logic <- rd_rlogic(covican,
                   logic = "if([exc_1]='1' or [inc_1]='0' or [inc_2]='0' or [inc_3]='0',1,0)",
                   var = "screening_fail_crit")

logic$rlogic # la expresión en R
head(logic$eval) # su valor en cada fila

## rd_split(): separar la base datos por formulario o por evento

# Por evento (proyectos longitudinales)
by_event <- rd_split(covican, by = "event")
by_event$data

# Por formulario
by_form <- rd_split(covican, by = "form")
by_form$data

## Solo un formulario específico
demographics <- rd_split(covican, by = "form", which = "demographics")
head(demographics$data)

# Formularios recogidos en varios eventos que de normal tienen una fila por paciente/evento:
labs_wide <- rd_split(covican, by = "form", which = "laboratory_findings", wide = TRUE) # Formato wide
head(labs_wide$data) # _1 y _2 son el 1.er y 2.º evento (basal y seguimiento)

## Encadenar los pasos

covican_clean <- covican |>
  rd_dates() |> # Las fechas de covican ya son correctas, así que la función avisa de que no ha cambiado nada
  rd_recalculate() |>
  rd_checkbox() |>
  rd_factor() |>
  rd_dictionary()

covican_clean$results # Registro de transformaciones


# Todo de una vez: rd_transform()
covican_transformed <- rd_transform(covican) # Ejecuta los pasos principales en una sola llamada
covican_transformed$results

# Mismos argumentos de cada paso por separado
covican_transformed2 <- rd_transform(covican,
                                     checkbox_labels = c("No", "Sí"),
                                     na_logic = "eval",
                                     exclude_factor = "urine_culture",
                                     final_format = "by_event")
covican_transformed2$data


# Queries

## rd_query(): valores missing

example <- rd_query(covican_transformed,
                    variables = c("copd", "age"),
                    expression = c("is.na(x)", "is.na(x)"), # x es la variable
                    event = "baseline_visit_arm_1")

# $queries: una fila por query, para poder localizarla en REDCap
head(example$queries)

# $results: resumen por variable
example$results

# Sin `event`, se usa la correspondencia evento-formulario para buscar solo en los eventos donde se recoge cada variable
example <- rd_query(covican_transformed,
                    variables = "copd",
                    expression = "is.na(x)")
example$results

## rd_query(): branching logic

# Ejemplo: `type_dm` solo se muestra si el paciente tiene diabetes ([dm] = '1') - Su branching logic se aplica automáticamente (warning)
example <- rd_query(covican_transformed,
                    variables = "type_dm",
                    expression = "is.na(x)",
                    event = "baseline_visit_arm_1")
example$results

## rd_query(): valores fuera de rango e incoherencias

example <- rd_query(covican_transformed,
                    variables = c("age", "copd"),
                    expression = c("x > 90 | x < 18", "x == 'Yes'"),
                    event = "baseline_visit_arm_1")
example$results

# Varias condiciones para la misma variable
example <- rd_query(covican_transformed,
                    variables = "age",
                    expression = "(x > 70 & x < 80) | is.na(x)",
                    event = "baseline_visit_arm_1")
example$results

# La misma expresión para varias variables: se escribe una sola vez (warning)
example <- rd_query(covican_transformed,
                    variables = c("copd", "age", "dm"),
                    expression = "is.na(x)",
                    event = "baseline_visit_arm_1")
example$results

# negate = TRUE
example <- rd_query(covican_transformed,
                    variables = "copd",
                    expression = "is.na(x)",
                    negate = TRUE,
                    event = "baseline_visit_arm_1")
example$results

## rd_query(): personalizar el informe

example <- rd_query(covican_transformed,
                    variables = "copd",
                    expression = "is.na(x)",
                    event = "baseline_visit_arm_1",
                    variables_names = "Enfermedad pulmonar obstructiva crónica", # descripción
                    query_name = "Falta el valor de EPOC", # texto de la query
                    instrument = "Comorbilidades", # nombre del formulario
                    report_title = "EPOC sin valor en la visita basal") # título de la tabla
head(example$queries)
example$results

# report_zeros = TRUE
example <- rd_query(covican_transformed,
                    variables = c("copd", "age"),
                    expression = c("is.na(x)", "x < 18"),
                    event = "baseline_visit_arm_1",
                    report_zeros = TRUE)
example$results

# Un informe por Data Access Group (DAG), para enviar a cada centro sus queries
example <- rd_query(covican_transformed,
                    variables = c("copd", "age"),
                    expression = c("is.na(x)", "x > 60"),
                    event = "baseline_visit_arm_1",
                    by_dag = TRUE)
names(example$queries)
names(example$results)
example$results$`Hospital 2`

# Enlace directo a cada query en REDCap
## El dominio, la versión y el id del proyecto aparecen en la URL del proyecto; los ids de los eventos en Project Setup -> Define My Events
example <- rd_query(dataset_api, # Datos del proyecto con API
                    variables = "age",
                    expression = "x > 70",
                    event = "basal_arm_1",
                    link = list(domain = "redcap.igtp.cat",
                                redcap_version = "16.0.15",
                                proj_id = 970,
                                event_id = c("basal_arm_1" = 2622, "seguimiento_arm_1" = 2623)))
example$queries$Link

## Construir un informe completo de queries con addTo
report <- rd_query(covican_transformed,
                   variables = c("copd", "age", "dm"),
                   expression = "is.na(x)",
                   event = "baseline_visit_arm_1")

report <- rd_query(covican_transformed,
                   variables = "age",
                   expression = "x > 90 | x < 18",
                   event = "baseline_visit_arm_1",
                   addTo = report) # Cada comprobación añade sus queries a las anteriores

report <- rd_query(covican_transformed,
                   variables = "potassium",
                   expression = "is.na(x)",
                   event = "baseline_visit_arm_1",
                   filter = "available_analytics == 'Yes'",
                   addTo = report)

report$results
nrow(report$queries)

## rd_event(): eventos que faltan

# REDCap no exporta un evento sin datos, así que la función lista los registros que no tienen un evento concreto
events <- rd_event(covican_transformed,
                   event = "follow_up_visit_da_arm_1")
events$results
head(events$queries)

# Solo entre los pacientes que deberían tener la visita de seguimiento (los que cumplían los criterios de inclusión/exclusión)
events <- rd_event(covican_transformed,
                   event = "follow_up_visit_da_arm_1",
                   filter = "screening_fail_crit == 0")
events$results

## rd_export(): exportar el informe de queries
rd_export(queries = report$queries,
          sheet_name = "Queries COVICAN",
          path = "queries/queries_covican.xlsx", 
          password = "REDCap_Modo_Dificil"
        )

## check_queries(): seguimiento tras las correcciones

### Trampa para comparar
covican_fixed <- covican_transformed
missing_age <- with(covican_fixed$data, record_id[is.na(age) & redcap_event_name == "baseline_visit_arm_1"])
covican_fixed$data$age[covican_fixed$data$record_id %in% missing_age[1:2]] <- 50
covican_fixed$data$copd[covican_fixed$data$record_id == "100-13" & covican_fixed$data$redcap_event_name == "baseline_visit_arm_1"] <- NA

new_report <- rd_query(covican_fixed,
                       variables = c("copd", "age", "dm"),
                       expression = "is.na(x)",
                       event = "baseline_visit_arm_1")

old_report <- rd_query(covican_transformed,
                       variables = c("copd", "age", "dm"),
                       expression = "is.na(x)",
                       event = "baseline_visit_arm_1")

check <- check_queries(old = old_report$queries, 
                       new = new_report$queries)

# Categorias de queries:
#   - Pending: sigue pendiente de resolución 
#   - Solved: resuelta
#   - New: nueva respecto al anterior report
#   - Miscorrected: mismo registro y variable, pero un problema distinto
check$results
table(check$queries$Modification)


###################### Lo que encontraréis como plantilla en el Making_data de los proyectos #########################

dades <- "./data"

# Load REDCapDM package
library(REDCapDM)
# Remember version
packageVersion("REDCapDM")

# Import data
dataset_raw <- redcap_data(
  data_path = file.path(dades, "PruebaDemoREDCapDM_R_2026-11-11_0817.r"),
  dic_path = file.path(dades, "PruebaDemoREDCapDM_DataDictionary_2026-11-11.csv"),
  event_path = file.path(dades, "PruebaDemoREDCapDM_InstrumentDesignations_2026-11-11.csv"),
)

# Save original labels in an object
labels <- purrr::map_chr(dataset_raw$data, function(x) {
  lab <- attr(x, "label")
  if (!is.null(lab)) {
    lab
  } else {
    ""
  }
})

# Preprocess

## Process and standardize date and datetime fields
dataset <- rd_dates(dataset_raw)

## Recompute calculated fields and compare with REDCap values
dataset <- rd_recalculate(dataset, exclude = NULL)

# show results of this transformation
dataset$results

## Checkbox transformation: "No"/"Sí" labels & renamed variables
dataset <- rd_checkbox(dataset, 
                       checkbox_labels = c("No", "Sí"),
                       # Renames the original variables (___1) to the checkbox options
                       checkbox_names = TRUE,
                       # Controls how missing values are set based on branching logic
                       na_logic = "missing") # set to NA only when the logic evaluation is NA

## Replace numeric multiple-choice columns with their factor version
dataset <- rd_factor(dataset, exclude = NULL)

## Update dictionary (translation of REDCap logic into R syntax) to reflect transformed data and logic
dataset <- rd_dictionary(dataset)

## Remove specified variables
dataset <- rd_delete_vars(dataset, pattern = c("^borrar_", "^delete_", "_complete$", "_timestamp$"))

data <- dataset$data

dic <- dataset$dictionary

# Preprocess data

# (insert here the code specific to your project)

# Save the data dictionary (one first time, then comment)
dictionary <- dataset$dictionary |> 
  dplyr::select(var = field_name, lab = field_label)
  
openxlsx::write.xlsx(dictionary, file = file.path(dades, "dictionary.xlsx"))   

# Read it again after all required labels are inserted manually
dictionary <- readxl::read_excel(file.path(dades, "dictionary.xlsx"))

# Transform to named vector
var_lab <- dictionary |>
  tibble::deframe() |>
  as.list()

# Add the labels as an attribute of the data using the package labelled
data <- data |>
  labelled::set_variable_labels(.labels = var_lab, .strict = FALSE)
  
# Final arrangement: split by form/event (optional)
# The dataset has to be updated with the transformed data (warning: if new variables have been added, then you need to add them to the dictionary too)
# dataset$data <- data
# dataset$dictionary <- dic

## Split by event (only if longitudinal)
# dataset_event <- rd_split(dataset, by = "event")

## Split by form
# dataset_form <- rd_split(dataset, by = "form", wide = FALSE)

# Save data
save(data, file = file.path(dades, "data_v1.Rda"))
# Save data, dataset_event, dataset_form
# save(data, dataset_event, dataset_form, file = file.path(dades_ana, "data_v1.Rda"))
# Save REDCap dictionary
save(dic, file = file.path(dades, "dic_v1.Rda"))
