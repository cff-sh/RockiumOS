package utils

import "core:fmt"
import "core:os"
import "core:path/filepath"

// Checks if a given file or directory path exists
exists :: proc(path: string) -> bool {
	return os.exists(path)
}

// Safely ensures a directory path exists, creating all parent directories if necessary
make_dir :: proc(path: string) -> bool {
	if exists(path) do return true

	err := os.make_directory(path)
	if err != nil {
		log_error(fmt.tprintf("Failed to create directory structure at '%s'", path))
		return false
	}
	return true
}

// Recursively deletes a directory tree (useful for 'aegis clean')
// DANGER: Equivalent to rm -rf. Handles path sanity checks carefully.
remove_dir_recursive :: proc(path: string) -> bool {
	if !exists(path) do return true

	// Safety check to ensure we aren't accidentally nuking root or critical paths
	if path == "/" || path == "." || path == "" {
		log_error(fmt.tprintf("Refusing to recursively delete dangerous path: '%s'", path))
		return false
	}

	// Read everything in the directory
	handle, err := os.open(path)
	if err != nil do return false
	defer os.close(handle)

	infos, read_err := os.read_dir(handle, -1)
	if read_err != nil do return false

	for info in infos {
		full_path := filepath.join({path, info.name})
		defer delete(full_path) // Clean up string allocation

		if info.is_dir {
			if !remove_dir_recursive(full_path) do return false
		} else {
			remove_err := os.remove(full_path)
			if remove_err != nil {
				log_error(fmt.tprintf("Failed to remove file: %s", full_path))
				return false
			}
		}
	}

	// Remove the top-level directory once empty
	remove_err := os.remove(path)
	return remove_err == nil
}

// Retrieves total size of a path in bytes (for telemetry disk tracking)
get_dir_size :: proc(path: string) -> (size_in_bytes: i64) {
	if !exists(path) do return 0

	handle, err := os.open(path)
	if err != nil do return 0
	defer os.close(handle)

	infos, read_err := os.read_dir(handle, -1)
	if read_err != nil do return 0

	total: i64 = 0
	for info in infos {
		if info.is_dir {
			full_path := filepath.join({path, info.name})
			total += get_dir_size(full_path)
			delete(full_path)
		} else {
			total += info.size
		}
	}
	return total
}

// Converts raw bytes into a human-readable storage string
format_size :: proc(bytes: i64) -> string {
	kb : f64 = 1024
	mb := kb * 1024
	gb := mb * 1024

	f_bytes := f64(bytes)

	if f_bytes >= gb do return fmt.tprintf("%.2f GB", f_bytes / gb)
	if f_bytes >= mb do return fmt.tprintf("%.2f MB", f_bytes / mb)
	if f_bytes >= kb do return fmt.tprintf("%.2f KB", f_bytes / kb)
	return fmt.tprintf("%d Bytes", bytes)
}