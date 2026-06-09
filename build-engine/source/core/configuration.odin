package core

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "../config"
import "../patches"
import "../utils"

configuration_system :: proc(cfg: config.Aegis_Config, workspace_root: string) -> bool {}