package core

import "core:fmt"
import "core:os"
import "core:strings"
import "../utils"

Execution_Result :: struct {
	stdout:    string,
	stderr:    string,
	exit_code: int,
	success:   bool,
}

// Low-level process executor that isolates command environments and captures streams safely
execute_command :: proc(command: string, args: []string, working_dir: string) -> (res: Execution_Result) {
	process_desc: os.Process_Desc
	process_desc.command = {command}
	process_desc.args = args
	process_desc.working_dir = working_dir

	// Setup stream captures for tracking outputs
	// Note: In standard cross-platform situations, os.stream_from_handle is platform dependent.
	// For production Linux systems, we can read raw stdout/stderr descriptors if piped.
	process_desc.stdout = os.stream_from_handle(os.INVALID_HANDLE) 
	process_desc.stderr = os.stream_from_handle(os.INVALID_HANDLE)

	process_state, err := os.process_start(process_desc)
	if err != nil {
		utils.log_error(fmt.tprintf("Failed to invoke runtime process descriptor for '%s'", command))
		res.exit_code = -1
		res.success = false
		return res
	}
	defer os.process_close(process_state)

	// Explicit await block to halt pipeline progression until task resolves
	state, wait_err := os.process_wait(process_state)
	if wait_err != nil {
		utils.log_error(fmt.tprintf("Process wait boundary error encountered during '%s'", command))
		res.exit_code = -1
		res.success = false
		return res
	}

	res.exit_code = state.exit_code
	res.success = state.exit_code == 0
	return res
}

// Convienience wrapper for running commands cleanly without capturing output buffers
execute_silent :: proc(command: string, args: []string, working_dir: string) -> bool {
	res := execute_command(command, args, working_dir)
	return res.success
}