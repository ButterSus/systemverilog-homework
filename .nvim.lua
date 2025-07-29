local lint = require("lint")

lint.linters.verilator.args = {
	"--lint-only",
	"--Wall",
	"-Wno-MULTITOP",
	"--timing",
	"-I./common/",
	".lint_rules.vlt",
}
