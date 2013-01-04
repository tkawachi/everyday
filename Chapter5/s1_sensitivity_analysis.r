library(grid)
library(ggplot2)

pdf("sensitivity_analysis.pdf")

grid.newpage()
pushViewport(viewport(layout=grid.layout(3,3)))
vplayout <- function(x,y) {viewport(layout.pos.row=x, layout.pos.col=y)}

row <- 1; col <- 1
for(i in c(1:9)) {
  file_name <- paste("./sa_data/price_demand", i, ".csv", sep="")
  data <- read.table(file_name, header=F, sep=",")
  p <- ggplot(data = data) +
  scale_colour_grey(name="Legend", start=0, end=0.6) +
  geom_line(aes(x  = V1, y = V2, color = "price")) +
  scale_y_continuous("price") +
  scale_x_continuous("time") +
  labs(title=paste("cons", 10+i, sep="")) +
  theme(
    plot.title = element_text(size=10),
    legend.position = "none"
  )

  print(p, vp=vplayout(row, col))
  if (col == 3) {row <- row + 1}
    col <- (col %% 3) + 1
}

dev.off()