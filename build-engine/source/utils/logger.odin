package utils

import "core:fmt"
import "core:time"

// Terminal ANSI Color Codes
COLOR_RESET  :: "\x1b[0m"
COLOR_INFO   :: "\x1b[34m" // Blue
COLOR_WARN   :: "\x1b[33m" // Yellow
COLOR_ERROR  :: "\x1b[31m" // Red
COLOR_SUCCESS:: "\x1b[32m" // Green
COLOR_MUTED  :: "\x1b[90m" // Gray

print_timestamp :: proc() {
	t := time.now()
	// Unpack the time components
	hour, min, sec := time.clock_from_time(t)
	
	fmt.printf("%s[%02d:%02d:%02d]%s ", COLOR_MUTED, hour, min, sec, COLOR_RESET)
}

log_info :: proc(message: string) {
	print_timestamp()
	fmt.printf("%s[INFO]%s    %s\n", COLOR_INFO, COLOR_RESET, message)
}

log_warn :: proc(message: string) {
	print_timestamp()
	fmt.printf("%s[WARN]%s    %s\n", COLOR_WARN, COLOR_RESET, message)
}

log_error :: proc(message: string) {
	print_timestamp()
	fmt.printf("%s[ERROR]%s   %s\n", COLOR_ERROR, COLOR_RESET, message)
}

log_success :: proc(message: string) {
	print_timestamp()
	fmt.printf("%s[SUCCESS]%s %s\n", COLOR_SUCCESS, COLOR_RESET, message)
}

// Example of a formatted metric log for telemetry data
log_metric :: proc(label: string, value: string) {
	print_timestamp()
	fmt.printf("%s[METRIC]%s  %s: %s%s%s\n", COLOR_MUTED, COLOR_RESET, label, COLOR_SUCCESS, value, COLOR_RESET)
}