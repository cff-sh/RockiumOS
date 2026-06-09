package container

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "../config"
import "../core"
import "../utils"

CONTAINER_NAME :: "aegis-sdk-container"
IMAGE_NAME     :: "aegisbuild-sdk:latest"

// Checks if the Docker daemon is accessible and running
check_docker_daemon :: proc() -> bool {
	args := []string{"info"}
	return core.execute_silent("docker", args, "")
}

// Builds the custom ChromiumOS/ThoriumOS SDK development container image
build_sdk_image :: proc(workspace_root: string) -> bool {
	dockerfile_dir := filepath.join({workspace_root, "container"})
	defer delete(dockerfile_dir)

	utils.log_info("Compiling AegisBuild SDK container image layer...")
	
	args := []string{"build", "-t", IMAGE_NAME, dockerfile_dir}
	res := core.execute_command("docker", args, workspace_root)
	
	if !res.success {
		utils.log_error("Failed to compile Docker SDK image blueprint.")
		return false
	}
	
	utils.log_success("SDK container blueprint image updated successfully.")
	return true
}

// Spins up the SDK container in the background with local workspaces mounted
setup_docker_env :: proc(cfg: config.Aegis_Config, workspace_root: string) -> bool {
	if !check_docker_daemon() {
		utils.log_error("Docker daemon is unreachable. Is Docker Desktop or the docker systemd service running?")
		return false
	}

	if !build_sdk_image(workspace_root) do return false

	if core.execute_silent("docker", []string{"inspect", CONTAINER_NAME}, workspace_root) {
		utils.log_warn("Stale compiler container instance discovered. Terminating...")
		core.execute_silent("docker", []string{"rm", "-f", CONTAINER_NAME}, workspace_root)
	}

	utils.log_info("Spawning isolated SDK compiler runtime container...")

	src_volume := fmt.tprintf("%s:/home/aegisbuild/workspace", workspace_root)
	defer delete(src_volume)

	run_args := []string{
		"run", "-d",
		"--name", CONTAINER_NAME,
		"-v", src_volume,
		IMAGE_NAME,
		"sleep", "infinity", // Keeps container alive indefinitely for pipelines to attach to
	}
	defer delete(run_args)

	res := core.execute_command("docker", run_args, workspace_root)
	if !res.success {
		utils.log_error("Failed to initialize system container mapping configurations.")
		return false
	}

	return true
}

// Tears down and purges the build container environment to free system loop resources
teardown_docker_env :: proc() {
	if core.execute_silent("docker", []string{"inspect", CONTAINER_NAME}, "") {
		utils.log_info("Destroying container context mappings...")
		core.execute_silent("docker", []string{"rm", "-f", CONTAINER_NAME}, "")
		utils.log_success("Container context successfully isolated and destroyed.")
	}
}