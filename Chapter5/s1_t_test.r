prices <- read.csv("sample_prices.csv", header=F)
t.test(prices, mu=5)
