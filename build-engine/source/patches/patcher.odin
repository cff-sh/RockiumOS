package patches

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "../config"
import "../utils"

// Executes a system command with arguments, capturing stdout/stderr and isolating execution contexts
execute_git_command :: proc(args: []string, working_dir: string) -> (output: string, exit_code: int, success: bool) {
	// Initialize process attributes
	process_desc: os.Process_Desc
	process_desc.command = {"git"}
	process_desc.args = args
	process_desc.working_dir = working_dir
	
	// Create channels to capture error telemetry
	process_desc.stdout = os.stream_from_handle(os.INVALID_HANDLE) // Swap with pipe streams for logging buffers
	process_desc.stderr = os.stream_from_handle(os.INVALID_HANDLE)

	process_state, err := os.process_start(process_desc)
	if err != nil {
		return "", -1, false
	}
	defer os.process_close(process_state)

	// Await execution completion
	state, wait_err := os.process_wait(process_state)
	if wait_err != nil {
		return "", -1, false
	}

	return "", state.exit_code, state.exit_code == 0
}

// Scans, validates, and applies patch matrices sequentially while maintaining repository state transparency
apply_patches :: proc(cfg: config.Aegis_Config, workspace_root: string) -> bool {
	patches_dir := filepath.join({workspace_root, "patches/thorium-layers"})
	defer delete(patches_dir)
	
	if !os.exists(patches_dir) {
		utils.log_warn(fmt.tprintf("Patches directory missing at '%s'. Skipping layer passes.", patches_dir))
		return true
	}

	handle, err := os.open(patches_dir)
	if err != nil {
		utils.log_error("Failed to access automated patch directories.")
		return false
	}
	defer os.close(handle)

	infos, read_err := os.read_dir(handle, -1)
	if read_err != nil {
		utils.log_error("Failed to read patch descriptors from disk arrays.")
		return false
	}

	utils.log_info("Orchestrating code adjustment routines...")

	for info in infos {
		if info.is_dir || !filepath.has_ext(info.name, ".patch") do continue

		full_patch_path := filepath.join({patches_dir, info.name})
		defer delete(full_patch_path)

		utils.log_info(fmt.tprintf("Evaluating layer delta: %s", info.name))

		check_args := []string{"apply", "--check", full_patch_path}
		_, check_code, check_ok := execute_git_command(check_args, workspace_root)
		
		if !check_ok || check_code != 0 {
			utils.log_error(fmt.tprintf("Merge conflict simulated on patch alignment '%s'. Aborting compilation sequence.", info.name))
			return false
		}

		apply_args := []string{"apply", "--verbose", full_patch_path}
		_, apply_code, apply_ok := execute_git_command(apply_args, workspace_root)
		
		if !apply_ok || apply_code != 0 {
			utils.log_error(fmt.tprintf("Critical crash while applying patch configuration layer: %s", info.name))
			return false
		}
	}

	utils.log_success("All Thorium OS target code pools patched successfully.")
	return true
}

// Re-writes hardcoded configuration blocks inside Chromium build settings programmatically
inject_branding_metadata :: proc(cfg: config.Aegis_Config, workspace_root: string) -> bool {
	target_file := filepath.join({workspace_root, "src/chrome/app/generated_resources.grd"})
	defer delete(target_file)
	
	if !os.exists(target_file) {
		utils.log_warn("Target branding tree array not found. Skipping field replacements.")
		return true
	}

	// Read content into memory safe heap space
	data, ok := os.read_entire_file_from_filename(target_file)
	if !ok {
		utils.log_error("Failed to stream localization descriptors into memory buffers.")
		return false
	}
	defer delete(data)

	file_content := string(data)
	
	// Perform in-memory explicit string mutations
	modified_content, allocation_error := strings.replace_all(file_content, "ChromiumOS", cfg.branding.os_name)
	if allocation_error != nil do return false
	defer delete(modified_content)

	// Commit mutations back to structural filesystems
	write_ok := os.write_entire_file(target_file, transmute([]ubyte)modified_content)
	if !write_ok {
		utils.log_error("I/O subsystem fault while saving custom operating system metadata bindings.")
		return false
	}

	utils.log_success("System namespace identities applied to target tree matrices.")
	return true
}