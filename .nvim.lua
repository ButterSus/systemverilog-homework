local lint = require("lint")

lint.linters.verilator.args = {
	"--lint-only",
	"--Wall",
	"-Wno-MULTITOP",
	"--timing",
	"--relative-includes",
	"-I./common/",
	".lint_rules.vlt",
	"./common/isqrt/isqrt.sv",
	"./import/preprocessed/cvw/config-shared.vh",
}
