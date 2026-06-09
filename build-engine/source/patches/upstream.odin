package patches

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "../config"
import "../utils"

// Initializes upstream tracking configurations if not already configured in git context
ensure_upstream_remote :: proc(workspace_root: string, upstream_url: string) -> bool {
	// Check if upstream is already configured
	remote_args := []string{"remote", "get-url", "upstream"}
	_, _, ok := execute_git_command(remote_args, workspace_root)
	if ok do return true // Upstream already configured

	utils.log_info(fmt.tprintf("Configuring upstream tracking remote to: %s", upstream_url))
	
	add_args := []string{"remote", "add", "upstream", upstream_url}
	_, _, add_ok := execute_git_command(add_args, workspace_root)
	if !add_ok {
		utils.log_error("Failed to append tracking branches to Git configuration nodes.")
		return false
	}
	return true
}

// Fetches upstream adjustments and attempts a clean rebase sequence to minimize patch drifting
sync_upstream :: proc(cfg: config.Aegis_Config, workspace_root: string) -> bool {
	upstream_repo := "https://github.com/Alex313031/ThoriumOS.git"
	
	if !ensure_upstream_remote(workspace_root, upstream_repo) {
		return false
	}

	utils.log_info("Fetching fresh commit nodes from upstream ThoriumOS...")
	
	fetch_args := []string{"fetch", "upstream"}
	_, fetch_code, fetch_ok := execute_git_command(fetch_args, workspace_root)
	if !fetch_ok || fetch_code != 0 {
		utils.log_error("Network or remote synchronization fault while pulling upstream trees.")
		return false
	}

	utils.log_info("Executing tree synchronization via rebase orchestration...")

	// Attempting a rebase on top of upstream main branch
	rebase_args := []string{"rebase", "upstream/main"}
	_, rebase_code, rebase_ok := execute_git_command(rebase_args, workspace_root)

	if !rebase_ok || rebase_code != 0 {
		utils.log_error("🔴 Merge conflict or rebase intercept detected!")
		utils.log_warn("The repository has entered a detached state. Manual intervention required.")
		utils.log_warn("Run 'git rebase --abort' inside the workspace directory to roll back.")
		
		// Abort the rebase automatically to leave the tree clean
		abort_args := []string{"rebase", "--abort"}
		execute_git_command(abort_args, workspace_root)
		return false
	}

	utils.log_success("Workspace completely synchronized with upstream ThoriumOS codebases.")
	return true
}