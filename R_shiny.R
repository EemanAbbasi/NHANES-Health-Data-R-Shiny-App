library(shiny)
library(ggplot2)
library(dplyr)
library(NHANES)
library(RColorBrewer)
library(shinythemes)
library(shinycssloaders)
library(rlang)

ui <- fluidPage(
  theme = shinytheme("cosmo"),
  
  titlePanel("NHANES Health Data Visualization"),
  
  sidebarLayout(
    sidebarPanel(
      width = 3,
      selectInput("xvar", "Choose X variable:",
                  choices = names(NHANES),
                  selected = "Age"),
      
      selectInput("yvar", "Choose Y variable:",
                  choices = names(NHANES),
                  selected = "BMI"),
      
      radioButtons("plotType", "Choose plot type:",
                   choices = list("Scatter Plot" = "scatter",
                                  "Box Plot" = "box")),
      
      sliderInput("pointSize", "Point Size:",
                  min = 1, max = 10, value = 3),
      
      textInput("color", "Point Color:", value = "blue"),
      
      selectInput("genderFilter", "Filter by Gender:",
                  choices = unique(NHANES$Gender),
                  selected = unique(NHANES$Gender),
                  multiple = TRUE),
      
      helpText("Use the inputs to customize your plot and filter the data.")
    ),
    
    mainPanel(
      withSpinner(plotOutput("plot")),
      uiOutput("summary")
    )
  )
)

server <- function(input, output) {
  
  filteredData <- reactive({
    data <- NHANES %>%
      filter(Gender %in% input$genderFilter)
    
    xvar <- sym(input$xvar)
    yvar <- sym(input$yvar)
    
    if (is.numeric(data[[input$xvar]])) {
      data <- data %>%
        filter(!!xvar >= min(!!xvar, na.rm = TRUE), 
               !!xvar <= max(!!xvar, na.rm = TRUE))
    }
    
    if (is.numeric(data[[input$yvar]])) {
      data <- data %>%
        filter(!!yvar >= min(!!yvar, na.rm = TRUE), 
               !!yvar <= max(!!yvar, na.rm = TRUE))
    }
    
    data
  })
  
  output$plot <- renderPlot({
    data <- filteredData()
    
    p <- ggplot(data, aes_string(x = input$xvar, y = input$yvar)) +
      labs(title = paste(input$plotType, "of", input$xvar, "vs", input$yvar),
           x = input$xvar,
           y = input$yvar) +
      theme_minimal(base_size = 14) +
      theme(
        panel.grid.major = element_blank(),  # Remove major grid lines
        panel.grid.minor = element_blank(),  # Remove minor grid lines
        panel.border = element_rect(colour = "black", fill = NA, size = 0.5),  # Add a border around the panel
        axis.line = element_line(colour = "black"),  # Add lines on the axes
        plot.title = element_text(hjust = 0.5, size = 16, face = "bold"),  # Center and bold the title
        axis.title = element_text(size = 14, face = "bold"),  # Bold axis titles
        axis.text = element_text(size = 12),  # Adjust size of axis labels
        legend.position = "right",  # Place legend on the right
        legend.title = element_text(size = 12, face = "bold"),  # Bold legend title
        legend.text = element_text(size = 10)  # Adjust size of legend text
      )
    
    if (input$plotType == "scatter") {
      p <- p + geom_point(size = input$pointSize, color = input$color) +
        scale_color_brewer(palette = "Set1")  # Use a color palette
    } else if (input$plotType == "box") {
      p <- p + geom_boxplot(fill = input$color) +
        scale_fill_brewer(palette = "Set1")  # Use a color palette
    }
    
    p
  })
  
  output$summary <- renderUI({
    data <- filteredData()
    
    if (nrow(data) > 0) {
      summary_df <- data %>%
        summarise(
          Mean_X = if(is.numeric(data[[input$xvar]])) mean(!!sym(input$xvar), na.rm = TRUE) else NA,
          SD_X = if(is.numeric(data[[input$xvar]])) sd(!!sym(input$xvar), na.rm = TRUE) else NA,
          Min_X = if(is.numeric(data[[input$xvar]])) min(!!sym(input$xvar), na.rm = TRUE) else NA,
          Max_X = if(is.numeric(data[[input$xvar]])) max(!!sym(input$xvar), na.rm = TRUE) else NA,
          Mean_Y = if(is.numeric(data[[input$yvar]])) mean(!!sym(input$yvar), na.rm = TRUE) else NA,
          SD_Y = if(is.numeric(data[[input$yvar]])) sd(!!sym(input$yvar), na.rm = TRUE) else NA,
          Min_Y = if(is.numeric(data[[input$yvar]])) min(!!sym(input$yvar), na.rm = TRUE) else NA,
          Max_Y = if(is.numeric(data[[input$yvar]])) max(!!sym(input$yvar), na.rm = TRUE) else NA
        )
      
      summary_df_melted <- as.data.frame(t(summary_df))
      names(summary_df_melted) <- "Value"
      summary_df_melted$Statistic <- rownames(summary_df_melted)
      
      fluidRow(
        column(12, 
               h4("Summary Statistics"),
               tableOutput("summaryTable")
        )
      )
    }
  })
  
  output$summaryTable <- renderTable({
    data <- filteredData()
    
    if (nrow(data) > 0) {
      summary_df <- data %>%
        summarise(
          Mean_X = if(is.numeric(data[[input$xvar]])) mean(!!sym(input$xvar), na.rm = TRUE) else NA,
          SD_X = if(is.numeric(data[[input$xvar]])) sd(!!sym(input$xvar), na.rm = TRUE) else NA,
          Min_X = if(is.numeric(data[[input$xvar]])) min(!!sym(input$xvar), na.rm = TRUE) else NA,
          Max_X = if(is.numeric(data[[input$xvar]])) max(!!sym(input$xvar), na.rm = TRUE) else NA,
          Mean_Y = if(is.numeric(data[[input$yvar]])) mean(!!sym(input$yvar), na.rm = TRUE) else NA,
          SD_Y = if(is.numeric(data[[input$yvar]])) sd(!!sym(input$yvar), na.rm = TRUE) else NA,
          Min_Y = if(is.numeric(data[[input$yvar]])) min(!!sym(input$yvar), na.rm = TRUE) else NA,
          Max_Y = if(is.numeric(data[[input$yvar]])) max(!!sym(input$yvar), na.rm = TRUE) else NA
        )
      
      summary_df_melted <- as.data.frame(t(summary_df))
      names(summary_df_melted) <- "Value"
      summary_df_melted$Statistic <- rownames(summary_df_melted)
      
      summary_df_melted
    }
  })
}

# Run the application 
shinyApp(ui = ui, server = server)
