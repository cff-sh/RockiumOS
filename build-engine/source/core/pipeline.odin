package core

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "../config"
import "../patches"
import "../utils"

// Verifies the workspace structure has everything needed before compilation begins
verify_workspace_layout :: proc(workspace_root: string) -> bool {
	required_paths := []string{
		"patches/thorium-layers",
		"src",
	}

	for sub_path in required_paths {
		full_path := filepath.join({workspace_root, sub_path})
		defer delete(full_path)

		if !os.exists(full_path) {
			utils.log_error(fmt.tprintf("Missing required workspace asset structural path: '%s'", sub_path))
			return false
		}
	}
	return true
}

// Executes a command inside the container environment using our process executor
run_command_in_sdk :: proc(workspace_root: string, args: []string) -> bool {
	// Wraps execution logic into 'docker exec' or 'chroot' primitives
	process_desc: os.Process_Desc
	process_desc.command = {"docker"}
	
	// Prepend docker exec configurations to target the Aegis Build container
	docker_base := []string{"exec", "-it", "aegis-sdk-container"}
	
	// Combine slices allocation-safe
	full_args := make([]string, len(docker_base) + len(args))
	defer delete(full_args)
	
	copy(full_args[0:], docker_base)
	copy(full_args[len(docker_base):], args)
	
	process_desc.args = full_args
	process_desc.working_dir = workspace_root

	process_state, err := os.process_start(process_desc)
	if err != nil do return false
	defer os.process_close(process_state)

	state, wait_err := os.process_wait(process_state)
	if wait_err != nil do return false

	return state.exit_code == 0
}

run_pipeline :: proc(cfg: config.Aegis_Config, workspace_root: string) -> bool {
	utils.log_info("Starting AegisBuild OS Pipeline Validation Stage...")

	// Step 1: Pre-flight internal workspace checks
	if !verify_workspace_layout(workspace_root) {
		utils.log_error("Workspace state validation failed. Terminating engine runtime.")
		return false
	}

	stats := sample_telemetry()
	if stats.ram_total_gb < 16.0 {
		utils.log_warn("Host hardware possesses less than 16GB available RAM. Build stability may degrade.")
	}
	utils.log_info(fmt.tprintf("Current System Load Metrics -> CPU: %.1f%% | RAM Used: %.1f GB", stats.cpu_usage, stats.ram_used_gb))

	if !patches.apply_patches(cfg, workspace_root) {
		utils.log_error("Codebase adjustment phase failed.")
		return false
	}

	if !patches.inject_branding_metadata(cfg, workspace_root) {
		utils.log_error("Operating system branding metadata assignment failed.")
		return false
	}

	utils.log_info(fmt.tprintf("Compiling cross-toolchain packages for target board: [%s]", cfg.target_board))
	
  // Board should be removed. As we target every platform like DragonFlyBSD.
  // Instead, we should use architecture instead.
  // Example command sequence mapping to ChromiumOS build targets
	// TODO: Change this to be arcitecture, also make the sh file.
  setup_board_args := []string{"./setup_board", fmt.tprintf("--board=%s", cfg.target_board)}
	if !run_command_in_sdk(workspace_root, setup_board_args) {
		utils.log_error("Cross-compiler board toolchain bootstrap phase crashed.")
		return false
	}

	utils.log_info("Compiling kernel modules and window managers...")
	build_packages_args := []string{"./build_packages", fmt.tprintf("--board=%s", cfg.target_board)}
	if !run_command_in_sdk(workspace_root, build_packages_args) {
		utils.log_error("Emerge compilation pipeline reported a critical package crash.")
		return false
	}

	utils.log_info("Packaging compiled objects into bootable sector images...")
  // Here we should change the --board argument too.
	build_image_args := []string{"./build_image", fmt.tprintf("--board=%s", cfg.target_board), "test"}
	if !run_command_in_sdk(workspace_root, build_image_args) {
		utils.log_error("Disk topology packaging routine failed to yield a bootable .bin image.")
		return false
	}

	utils.log_success("Pipeline Complete! Target OS images built successfully.")
	return true
}
