package source

import "core:fmt"
import "core:os"
import "core:strings"

print_usage :: proc() {
	fmt.println("AegisBuild v0.0.1 — Next-Gen Build Engine for RockiumOS\n")
	fmt.println("Usage: aegis <command> [options]\n")
	fmt.println("Commands:")
	fmt.println("  bootstrap    Initialize and pull the containerized SDK environment")
	fmt.println("  patch        Apply or sync custom git patches against upstream")
	fmt.println("  build        Execute the ChromiumOS compilation pipeline")
	fmt.println("  telemetry    Launch real-time performance and resource monitor")
	fmt.println("  clean        Purge build artifacts and reclaim storage space")
}

main :: proc() {
if len(os.args) < 2 {
		print_usage()
		os.exit(1)
	}

    command := os.args[1]

    cfg, cfg_ok := config.load_config("aegis.config.json")
        if !cfg_ok {
            utils.log_error("Failed to load or parse aegis.config.json. Aborting.")
            os.exit(1)
        }

        utils.log_info("AegisBuild initialized successfully.")
        utils.log_info(fmt.tprintf("Target Board: %s | Optimization: %s", cfg.target_board, cfg.optimization_level))
       
        switch command {
            case "bootstrap":
                utils.log_info("Starting environment bootstrap...")
                if container.setup_docker_env(cfg) {
                    utils.log_success("SDK container environment is ready.")
                } else {
                    utils.log_error("Bootstrap failed.")
                    os.exit(1)
                }

            case "patch":
                utils.log_info("Scanning and applying custom patch layers...")
                // Check for subflags like --apply or --sync
                is_sync := false
                if len(os.args) >= 3 && os.args[2] == "--sync" {
                    is_sync = true
                }

                if is_sync {
                    patches.sync_upstream(cfg)
                } else {
                    patches.apply_patches(cfg)
                }

            case "build":
                utils.log_info("Orchestrating ThoriumOS compilation pipeline.")
                core.run_pipeline(cfg)

            case "telemetry":
                utils.log_info("Attaching to active compiler pipelines...")
                core.launch_telemetry_dashboard()

            case "clean":
                utils.log_warn("Deep cleaning build artifacts...")
                utils.purge_cache(cfg)

            case:
                fmt.printf("Unknown command: '%s'\n\n", command)
                print_usage()
                os.exit(1)
            }
        }