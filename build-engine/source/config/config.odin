package config

import "core:fmt"
import "core:os"
import "core:encoding/json"
import "../utils"

Branding_Config :: struct {
	os_name: string,
	creator: string,
}

Aegis_Config :: struct {
	target_board:       string,
	optimization_level: string,
	enable_avx512:      bool,
	distcc_hosts:       []string,
	branding:           Branding_Config,
}

// Loads and parses the configuration JSON file into an Aegis_Config struct.
// Returns the configuration data and a boolean indicating success.
load_config :: proc(filename: string) -> (cfg: Aegis_Config, success: bool) {
	if !os.exists(filename) {
		utils.log_error(fmt.tprintf("Configuration file '%s' not found.", filename))
		return cfg, false
	}

	data, read_ok := os.read_entire_file_from_filename(filename)
	if !read_ok {
		utils.log_error(fmt.tprintf("Failed to read file contents of '%s'.", filename))
		return cfg, false
	}
	defer delete(data)

	err := json.unmarshal(data, &cfg)
	if err != nil {
		utils.log_error(fmt.tprintf("JSON syntax error in '%s': %v", filename, err))
		return cfg, false
	}

	return cfg, true
}

// Cleans up the dynamically allocated string slices inside the configuration struct
destroy_config :: proc(cfg: ^Aegis_Config) {
	delete(cfg.target_board)
	delete(cfg.optimization_level)
	delete(cfg.branding.os_name)
	delete(cfg.branding.creator)
	
	for host in cfg.distcc_hosts {
		delete(host)
	}
	delete(cfg.distcc_hosts)
}