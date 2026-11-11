#Clear existing data and graphics
rm(list=ls())
graphics.off()
#Load Hmisc library
library(Hmisc)
#Read Data
data=read.csv('PruebaDemoREDCapDM_DATA_2026-11-11_0817.csv')
#Setting Labels

label(data$record_id) = "ID del paciente"
label(data$redcap_event_name) = "Event Name"
label(data$redcap_survey_identifier) = "Survey Identifier"
label(data$d_birth) = "Fecha de nacimiento"
label(data$d_admission) = "Fecha de inclusi"
label(data$age) = "Edad (años)"
label(data$sex) = "Sexo"
label(data$weight) = "Peso (kg)"
label(data$demographics_complete) = "Complete?"
label(data$dm) = "Diabetes"
label(data$type_dm) = "Tipo de diabetes"
label(data$copd) = "EPOC"
label(data$comorb___1) = "Otras comorbilidades (choice=Hipertensión)"
label(data$comorb___2) = "Otras comorbilidades (choice=Dislipemia)"
label(data$comorb___3) = "Otras comorbilidades (choice=Obesidad)"
label(data$comorb___4) = "Otras comorbilidades (choice=Otra)"
label(data$comorb___ni) = "Otras comorbilidades (choice=No information)"
label(data$comorb___unk) = "Otras comorbilidades (choice=Unknown)"
label(data$comorb___asku) = "Otras comorbilidades (choice=Asked but unknown)"
label(data$comorb___nask) = "Otras comorbilidades (choice=Not asked)"
label(data$comorb_other) = "Especificar otra comorbilidad"
label(data$comorbidities_complete) = "Complete?"
label(data$fu_date) = "Fecha de la visita de seguimiento"
label(data$fu_status) = "Estado del paciente"
label(data$creatinine) = "Creatinina (mg/dL)"
label(data$follow_up_complete) = "Complete?"
label(data$satisfaction_timestamp) = "Survey Timestamp"
label(data$satisf_score) = "Satisfacción"
label(data$satisf_comment) = "Comentarios"
label(data$satisfaction_complete) = "Complete?"
#Setting Units


#Setting Factors(will create new variable for factors)
mapping_redcap_event_name = c(
	"basal_arm_1" = "Basal",
	"seguimiento_arm_1" = "Seguimiento"
)
data$redcap_event_name.factor = factor(data$redcap_event_name, levels = names(mapping_redcap_event_name), labels = mapping_redcap_event_name)

mapping_sex = c(
	"1" = "Hombre",
	"2" = "Mujer"
)
data$sex.factor = factor(data$sex, levels = names(mapping_sex), labels = mapping_sex)

mapping_demographics_complete = c(
	"0" = "Incomplete",
	"1" = "Unverified",
	"2" = "Complete"
)
data$demographics_complete.factor = factor(data$demographics_complete, levels = names(mapping_demographics_complete), labels = mapping_demographics_complete)

mapping_dm = c(
	"1" = "Yes",
	"0" = "No"
)
data$dm.factor = factor(data$dm, levels = names(mapping_dm), labels = mapping_dm)

mapping_type_dm = c(
	"1" = "Tipo 1",
	"2" = "Tipo 2"
)
data$type_dm.factor = factor(data$type_dm, levels = names(mapping_type_dm), labels = mapping_type_dm)

mapping_copd = c(
	"1" = "Yes",
	"0" = "No"
)
data$copd.factor = factor(data$copd, levels = names(mapping_copd), labels = mapping_copd)

mapping_comorb___1 = c(
	"0" = "Unchecked",
	"1" = "Checked"
)
data$comorb___1.factor = factor(data$comorb___1, levels = names(mapping_comorb___1), labels = mapping_comorb___1)

mapping_comorb___2 = c(
	"0" = "Unchecked",
	"1" = "Checked"
)
data$comorb___2.factor = factor(data$comorb___2, levels = names(mapping_comorb___2), labels = mapping_comorb___2)

mapping_comorb___3 = c(
	"0" = "Unchecked",
	"1" = "Checked"
)
data$comorb___3.factor = factor(data$comorb___3, levels = names(mapping_comorb___3), labels = mapping_comorb___3)

mapping_comorb___4 = c(
	"0" = "Unchecked",
	"1" = "Checked"
)
data$comorb___4.factor = factor(data$comorb___4, levels = names(mapping_comorb___4), labels = mapping_comorb___4)

mapping_comorb___ni = c(
	"0" = "Unchecked",
	"1" = "Checked"
)
data$comorb___ni.factor = factor(data$comorb___ni, levels = names(mapping_comorb___ni), labels = mapping_comorb___ni)

mapping_comorb___unk = c(
	"0" = "Unchecked",
	"1" = "Checked"
)
data$comorb___unk.factor = factor(data$comorb___unk, levels = names(mapping_comorb___unk), labels = mapping_comorb___unk)

mapping_comorb___asku = c(
	"0" = "Unchecked",
	"1" = "Checked"
)
data$comorb___asku.factor = factor(data$comorb___asku, levels = names(mapping_comorb___asku), labels = mapping_comorb___asku)

mapping_comorb___nask = c(
	"0" = "Unchecked",
	"1" = "Checked"
)
data$comorb___nask.factor = factor(data$comorb___nask, levels = names(mapping_comorb___nask), labels = mapping_comorb___nask)

mapping_comorbidities_complete = c(
	"0" = "Incomplete",
	"1" = "Unverified",
	"2" = "Complete"
)
data$comorbidities_complete.factor = factor(data$comorbidities_complete, levels = names(mapping_comorbidities_complete), labels = mapping_comorbidities_complete)

mapping_fu_status = c(
	"1" = "Vivo",
	"2" = "Fallecido"
)
data$fu_status.factor = factor(data$fu_status, levels = names(mapping_fu_status), labels = mapping_fu_status)

mapping_follow_up_complete = c(
	"0" = "Incomplete",
	"1" = "Unverified",
	"2" = "Complete"
)
data$follow_up_complete.factor = factor(data$follow_up_complete, levels = names(mapping_follow_up_complete), labels = mapping_follow_up_complete)

mapping_satisf_score = c(
	"1" = "1",
	"2" = "2",
	"3" = "3",
	"4" = "4",
	"5" = "5"
)
data$satisf_score.factor = factor(data$satisf_score, levels = names(mapping_satisf_score), labels = mapping_satisf_score)

mapping_satisfaction_complete = c(
	"0" = "Incomplete",
	"1" = "Unverified",
	"2" = "Complete"
)
data$satisfaction_complete.factor = factor(data$satisfaction_complete, levels = names(mapping_satisfaction_complete), labels = mapping_satisfaction_complete)

