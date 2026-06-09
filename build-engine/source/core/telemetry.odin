package core

import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"
import "../utils"

System_Stats :: struct {
	cpu_usage:    f64,    // Percentage (0.0 to 100.0)
	ram_total_gb: f64,
	ram_used_gb:  f64,
	ram_percent:  f64,
}

// Parses /proc/meminfo to get current RAM statistics
get_ram_stats :: proc() -> (total_gb: f64, used_gb: f64, percent: f64) {
	data, ok := os.read_entire_file_from_filename("/proc/meminfo")
	if !ok do return 0, 0, 0
	defer delete(data)

	lines := strings.split(string(data), "\n")
	defer delete(lines)

	mem_total, mem_available: int

	for line in lines {
		if strings.has_prefix(line, "MemTotal:") {
			fields := strings.fields(line)
			defer delete(fields)
			if len(fields) >= 2 do mem_total = strconv.atoi(fields[1])
		} else if strings.has_prefix(line, "MemAvailable:") {
			fields := strings.fields(line)
			defer delete(fields)
			if len(fields) >= 2 do mem_available = strconv.atoi(fields[1])
		}
	}

	if mem_total == 0 do return 0, 0, 0

	// Convert KB to GB
	total_gb = f64(mem_total) / (1024.0 * 1024.0)
	used_gb = f64(mem_total - mem_available) / (1024.0 * 1024.0)
	percent = (used_gb / total_gb) * 100.0

	return total_gb, used_gb, percent
}

// Helper to get raw CPU ticks from /proc/stat
get_cpu_ticks :: proc() -> (idle: u64, total: u64) {
	data, ok := os.read_entire_file_from_filename("/proc/stat")
	if !ok do return 0, 0
	defer delete(data)

	lines := strings.split(string(data), "\n")
	defer delete(lines)

	if len(lines) == 0 do return 0, 0

	// We only care about the first line ("cpu ...")
	fields := strings.fields(lines[0])
	defer delete(fields)

	if len(fields) < 5 do return 0, 0

	user       := u64(strconv.atoi(fields[1]))
	nice       := u64(strconv.atoi(fields[2]))
	system_val := u64(strconv.atoi(fields[3]))
	idle_val   := u64(strconv.atoi(fields[4]))
	iowait     := u64(strconv.atoi(fields[5]))
	irq        := u64(strconv.atoi(fields[6]))
	softirq    := u64(strconv.atoi(fields[7]))

	total_idle := idle_val + iowait
	total_non_idle := user + nice + system_val + irq + softirq
	total_system := total_idle + total_non_idle

	return total_idle, total_system
}

// Calculates CPU load over a brief sampling window (approx. 200ms)
get_cpu_usage :: proc() -> f64 {
	idle1, total1 := get_cpu_ticks()
	os.sleep(200000000) // Sleep for 200ms (in nanoseconds)
	idle2, total2 := get_cpu_ticks()

	total_diff := f64(total2 - total1)
	idle_diff  := f64(idle2 - idle1)

	if total_diff == 0.0 do return 0.0
	return ((total_diff - idle_diff) / total_diff) * 100.0
}

// Gathers all current system telemetry metrics
sample_telemetry :: proc() -> System_Stats {
	stats: System_Stats
	stats.cpu_usage = get_cpu_usage()
	stats.ram_total_gb, stats.ram_used_gb, stats.ram_percent = get_ram_stats()
	return stats
}

// Prints a single-line snapshot of the compiler pipeline environment
launch_telemetry_dashboard :: proc() {
	utils.log_info("AegisBuild Resource Tracker Active (Press Ctrl+C to exit)")
	
	for {
		stats := sample_telemetry()
		metrics_str := fmt.tprintf("CPU: %5.1f%% | RAM: %5.1f / %5.1f GB (%4.1f%%)", 
			stats.cpu_usage, stats.ram_used_gb, stats.ram_total_gb, stats.ram_percent)
		
		utils.log_metric("System Load", metrics_str)
		os.sleep(2000000000) // Sample every 2 seconds
	}
}