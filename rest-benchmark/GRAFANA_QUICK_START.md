# Grafana Dashboard Quick Start Guide

## 🎯 You're seeing "No data" - Here's why and how to fix it

### Current Situation

You opened the **"REST Benchmark Overview"** dashboard, which shows Prometheus metrics (JVM, CPU, memory). However, it's showing "No data" because:

1. The time range selected (20:50-21:05) was when tests ran
2. Services may have restarted since then, losing old metrics
3. Prometheus only keeps recent data (default: 15 days, but in-memory metrics are lost on restart)

---

## ✅ Solution: View Current Live Metrics

### Option 1: View Live Metrics (Recommended)

1. **Stay on "REST Benchmark Overview" dashboard**
2. **Change the time range** (top-right corner):
   - Click the time picker
   - Select **"Last 5 minutes"** or **"Last 15 minutes"**
   - Click **Apply**
3. **Select variants** to monitor:
   - Use the "Variant" dropdown at the top
   - Select one or all: `variant-a-jersey`, `variant-c-springmvc`, `variant-d-springdata`
4. You should now see live metrics!

### Option 2: View JMeter Test Results (Historical Data)

1. **Go back to Dashboards** (click "Dashboards" in left sidebar)
2. **Click on "JMeter Benchmark - REST Services"**
3. **Set time range** to when tests ran:
   - Click time picker (top-right)
   - Select **"Last 2 hours"** or use custom range
   - Your tests ran around **20:30-21:00 UTC+1**
4. This dashboard shows:
   - Requests Per Second (RPS)
   - Response time percentiles (p50/p95/p99)
   - Success vs Errors
   - Active threads
   - Requests by transaction type

---

## 📊 What Each Dashboard Shows

### 1. REST Benchmark Overview (Prometheus)
**Purpose**: Monitor application health and resource usage

**Metrics**:
- CPU usage (process)
- Heap memory (used vs max)
- HTTP latency (p95, p99)
- Request throughput (RPS)
- Error rates
- JVM threads (live, daemon)
- HikariCP connections (active, idle, pending)

**Best for**: 
- Real-time monitoring during tests
- Resource consumption analysis
- Finding bottlenecks

**Time Range**: Use "Last X minutes" for live data

### 2. JMeter Benchmark - REST Services (InfluxDB)
**Purpose**: Analyze load test results

**Metrics**:
- Actual RPS achieved during tests
- Response times (p50, p95, p99)
- Success/Error counts
- Thread ramp-up visualization
- Transaction breakdown by endpoint

**Best for**:
- Comparing test runs
- Historical analysis
- Identifying failed requests

**Time Range**: Set to when your tests ran (20:30-21:00 UTC+1 today)

---

## 🔧 Quick Commands to Generate Fresh Data

Want to see live metrics right now? Run a quick test:

```powershell
# Quick 30-second test to generate metrics
$JMETER = "C:\Users\Dell\AppData\Roaming\JetBrains\IntelliJIdea2025.1\apache-jmeter-5.6.3\bin\jmeter.bat"

# Run a quick read-heavy test (just 30 seconds)
& $JMETER -n -t jmeter/scenarios/read-heavy.jmx -JvariantHost=localhost -JvariantPort=8081 -l "results/quick-test.jtl" -Jduration=30
```

Then immediately:
1. Open Grafana
2. Go to "REST Benchmark Overview"
3. Set time range to "Last 5 minutes"
4. Select variant `variant-a-jersey`
5. Watch the metrics!

---

## 🎨 Customize Your View

### Add More Variants to Compare

1. In "REST Benchmark Overview" dashboard
2. Click the **"Variant"** dropdown (top-left)
3. Click **"All"** to see all 3 variants on the same graph
4. Each variant will have a different color

### Zoom into Specific Time Periods

1. **Click and drag** on any graph to zoom into a specific time range
2. **Click "Zoom out"** (top-right) to go back
3. Use the **time picker** for exact ranges

### Refresh Automatically

1. Click the **refresh icon** (top-right)
2. Select auto-refresh interval: `5s`, `10s`, `30s`, `1m`
3. Dashboard will update automatically

---

## 🐛 Troubleshooting

### Still seeing "No data"?

**Check 1: Services are running**
```powershell
docker compose ps
```
All should show "Up" status.

**Check 2: Prometheus is scraping**
1. Open http://localhost:9090 (Prometheus UI)
2. Go to **Status → Targets**
3. All targets should be "UP"

**Check 3: Metrics are exposed**
```powershell
# Test each variant
curl.exe http://localhost:8081/actuator/prometheus | Select-String "process_cpu" -First 1
curl.exe http://localhost:8082/actuator/prometheus | Select-String "process_cpu" -First 1
curl.exe http://localhost:8083/actuator/prometheus | Select-String "process_cpu" -First 1
```
Each should return a line with CPU metrics.

**Check 4: InfluxDB has data**
```powershell
docker exec -i rest-benchmark-influxdb-1 influx query 'from(bucket: "jmeter") |> range(start: -2h) |> limit(n: 5)'
```
Should show recent JMeter data.

### No JMeter data in InfluxDB?

This means the tests didn't write to InfluxDB. The data exists in `.jtl` files but not in the database. To regenerate:

```powershell
# Re-run a quick test
$JMETER = "C:\Users\Dell\AppData\Roaming\JetBrains\IntelliJIdea2025.1\apache-jmeter-5.6.3\bin\jmeter.bat"
& $JMETER -n -t jmeter/scenarios/read-heavy.jmx -JvariantHost=localhost -JvariantPort=8081 -l "results/new-test.jtl"
```

---

## 📈 Recommended Workflow

### For Performance Analysis:

1. **Before running tests**:
   - Open "REST Benchmark Overview" dashboard
   - Set time range to "Last 30 minutes"
   - Set auto-refresh to "10s"

2. **Run your JMeter tests** from PowerShell

3. **Watch real-time metrics**:
   - CPU spikes
   - Memory growth
   - Thread count changes
   - Connection pool usage

4. **After tests complete**:
   - Open "JMeter Benchmark - REST Services" dashboard
   - Set time range to cover the test period
   - Analyze RPS, latency, errors

5. **Compare variants**:
   - Run the same test against all 3 ports (8081, 8082, 8083)
   - Use the "Variant" filter to overlay metrics
   - Identify the winner!

---

## 🎯 Next Steps

1. ✅ **Right now**: Change time range to "Last 5 minutes" to see current metrics
2. 🔄 **Run a quick test** to generate fresh data (30 seconds)
3. 📊 **Switch to JMeter dashboard** to see historical test results
4. 📝 **Read BENCHMARK_RESULTS.md** for detailed analysis

---

## 💡 Pro Tips

- **Use annotations**: Click any graph and add annotations to mark important events
- **Create alerts**: Set up alerts for high CPU, memory, or error rates
- **Export data**: Use Grafana's export feature to save graphs as images
- **Share dashboards**: Click "Share" to get a link or embed code

---

**Dashboard URLs**:
- Grafana: http://localhost:3000
- Prometheus: http://localhost:9090
- InfluxDB: http://localhost:8086

**Current time**: 2025-11-10 21:05 (your tests ran at 20:30-21:00)

**Tip**: For best results, set time range to "Last 2 hours" or use custom range `2025-11-10 20:00` to `2025-11-10 21:30`

