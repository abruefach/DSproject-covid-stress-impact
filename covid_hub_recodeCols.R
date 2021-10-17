# Recode our selected columns from the Covid Hub data
# Elena Leib

#### Load libraries and set options ####
library(tidyverse)
library(tidylog)

options(stringsAsFactors = FALSE)


#### Load data ####
# Using read.csv instead of read_csv because the tidyverse function was not
# working on E's computer

covid <- read.csv("united-states.csv")


# Note: 
# I was originally reading in the data frame from Alex, but lots of columns were showing up as NA for me, so I decided to redo the column selection.
# covid_Alex <- read.csv("cov19tracker_cleaned.csv")


#### Select only our columns of interest ####
covid_sub <- covid %>% 
  select(state, endtime, gender, age, contains("household"), contains("child_age"),
         contains("child_education"), i10_health, i11_health, r1_1, WCRV_4,
         employment_status, cantril_ladder, contains("PHQ4"), CORE_B2_4, contains("w4")) 

# Not using work ones anymore, so removed contains("w4")


#### Go through and check all the columns for any funky data ####
# Ended up doing this by hand so I could inspect and be sure what I was doing!

# unique(covid_sub$state)
# unique(covid_sub$gender)
# unique(covid_sub$household_size)
# unique(covid_sub$household_children)
# unique(covid_sub$child_age_1)
# unique(covid_sub$child_education_1)
# unique(covid_sub$r1_1)
# unique(covid_sub$WCRV_4)
# unique(covid_sub$employment_status)
# unique(covid_sub$cantril_ladder)
# unique(covid_sub$PHQ4_1)
# unique(covid_sub$CORE_B2_4)
# unique(covid_sub$w4_1)



#### Helper functions ####
recode_child_ed <- function(x) {
  case_when(str_detect(x, "1") ~ 5,
            str_detect(x, "2") ~ 4,
            str_detect(x, "3") ~ 3,
            str_detect(x, "4") ~ 2,
            str_detect(x, "5") ~ 1,
            TRUE ~ NA_real_)
}



#### Recode columns ####
covid_recode <- covid_sub %>% 
         # For household variables, note that 8 or more and 5 or more are coded
         # as 8 and 5 respectively. So need to be careful with interpreting
         # these values.
  mutate(household_size = recode(household_size, 
                                 '0' = 0,
                                 '1' = 1,
                                 '2' = 2,
                                 '3' = 3,
                                 '4' = 4,
                                 '5' = 5,
                                 '6' = 6,
                                 '7' = 7,
                                 "8 or more" = 8,
                                 .default = NA_real_),
         household_children = recode(household_children, 
                                     '0' = 0,
                                     '1' = 1,
                                     '2' = 2,
                                     '3' = 3,
                                     '4' = 4,
                                     '5 or more' = 5,
                                     .default = NA_real_), 
         
         # Change all child_age and w4 columns to numeric 0/1
         across(contains(c("child_age", "w4")), recode, "No" = 0, 
                "Yes" = 1, .default = NA_real_),
         
         # Higher scores indicate more concern about education
         across(contains("child_education"), recode_child_ed),
         
         # Higher score means more willing/easy to isolate
         i10_health = recode(i10_health, 
                             "Very easy"= 5,
                             "Somewhat easy" = 4,
                             "Neither easy nor difficult" = 3,
                             "Somewhat difficult" = 2,
                             "Very difficult" = 1,
                             .default = NA_real_),
         
         i11_health = recode(i11_health, 
                             "Very willing"= 5,
                             "Somewhat willing" = 4,
                             "Neither willing nor unwilling" = 3,
                             "Somewhat unwilling" = 2,
                             "Very unwilling" = 1,
                             .default = NA_real_),
         
         # r1_1 - Coronavirus (COVID-19) is very dangerous for me
         # Higher scores indicate more fear about covid
         # (Using str_detect because there are some weird characters in there,
         # and it is just easier to detect if there is a number than match it
         # exactly)
         r1_1 =  case_when(str_detect(r1_1, "1") ~ 1,
                           str_detect(r1_1, "2") ~ 2,
                           str_detect(r1_1, "3") ~ 3,
                           str_detect(r1_1, "4") ~ 4,
                           str_detect(r1_1, "5") ~ 5,
                           str_detect(r1_1, "6") ~ 6,
                           str_detect(r1_1, "7") ~ 7,
                           TRUE ~ NA_real_),
         
         # WCRV_4 - Which, if any, of the following statements BEST describes
         # your feelings towards contracting the Coronavirus (COVID-19)?
         # Higher scores indicates more fear
         WCRV_4 = case_when(str_detect(WCRV_4, "not at all scared") ~ 1,
                            str_detect(WCRV_4, "not very scared") ~ 2,
                            str_detect(WCRV_4, "fairly scared") ~ 3,
                            str_detect(WCRV_4, "very scared") ~ 4,
                            WCRV_4 == "Don't know" ~ NA_real_,
                            str_detect(WCRV_4, "Not applicable") ~ NA_real_,
                            TRUE ~ NA_real_),
         
         # Change all the PHQ4 (well-being) questions to a numeric scale
         # Higher scores indicate more severe anxiety/depression symptoms
         across(contains("PHQ4"),
                recode,'Not at all' = 1,
                'Several days' = 2,
                'More than half the days' = 3,
                'Nearly every day' = 4,
                .default = NA_real_),
         
         # Compared with two weeks ago, would you say you are more or less happy now?
         # Higher scores indicate feeling more happy than 2 weeks ago
         CORE_B2_4 = recode(CORE_B2_4, 
                            "Much more happy now" = 5,
                            "Somewhat more happy now" = 4, 
                            "About the same" = 3,
                            "Somewhat less happy now" = 2,
                            "Much less happy now" = 1,
                            .default = NA_real_),
         
         # Our first pass at making employment status into a binary variable
         # 1 - full time or part time
         # 0 - unemployed or not working
         # NA - all other categories
         employment_status.cat = case_when(employment_status %in% 
                                             c("Full time employment", 
                                               "Part time employment") ~ 1,
                                           employment_status %in% 
                                             c("Unemployed", 
                                               "Not working") ~ 0,
                                           TRUE ~ NA_real_)) %>%
  rowwise() %>% 
  mutate(PHQ4_sum = sum(PHQ4_1, PHQ4_2, PHQ4_3, PHQ4_4),
         child_education_sum = sum(child_education_1, child_education_2, child_education_3, child_education_4)) %>% 
  ungroup()


write.csv(covid_recode, file = "covid19tracker_recoded.csv", row.names = FALSE)

