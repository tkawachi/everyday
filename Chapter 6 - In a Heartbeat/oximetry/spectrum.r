data <- read.csv(file='data.csv', header=T)

png("spectrum.png")
spec_result <- spectrum(ts(data$intensity, frequency=30*60))
dev.off()

max_idx = which.max(spec_result$spec)
heartbeat_rate <- round(spec_result$freq[max_idx])
print(paste("Heartbeat rate is",heartbeat_rate))
