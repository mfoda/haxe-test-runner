import sys.io.File;
import sys.FileSystem as Fs;
import haxe.io.Path;

using StringTools;
using Lambda;

typedef RunArgs = {
	slug:String,
	inputDir:String,
	outputDir:String,
}

typedef Paths = {
	inputSol:String,
	inputTest:String,
	tmpSol:String,
	tmpTest:String,
	tmpReporter:String,
	outResults:String,
	outDir:String
}

class Runner {
	static inline var helpMsg = "Usage:
  runner [slug] [inputDir] [outputDir]
Run the tests for the `slug` exercise in `inputDir` and write `result.json` to `outputDir`.
Options:
  -h, --help      Print this help message";

	public static function main() {
		var runArgs = parseArgs();
		var paths = getPaths(runArgs);
		prepareFiles(paths);

		var exitCode = run(paths);
		Sys.exit(exitCode);
	}

	// Run the tests for the given exercise and produce a results.json
	static function run(paths:Paths):Int {
		var compArgs = ["-m", '${paths.tmpTest}', "--no-output", "-p", '${paths.outDir}',];
		var compProc = new sys.io.Process("haxe", compArgs);
		var compExitCode = compProc.exitCode();
		var compileResult = compProc.stdout.readAll().toString();
		if (compExitCode != 0) {}

		var testArgs = [
			"--main",
			'${paths.tmpTest}',
			"--interp",
			"--class-path",
			'${paths.outDir}',
			"--define",
			"buddy-ignore-passing-specs",
			"buddy-colors",
			'reporter=${paths.tmpReporter}'
		];
		var testExitCode = 0;
		var testResult = new sys.io.Process("haxe", []).stdout.readAll().toString();
		return 0;
	}

	static function prepareFiles(paths:Paths) {
		Fs.createDirectory(paths.outDir);
		File.copy(paths.inputSol, paths.tmpSol);
		File.copy(paths.inputTest, paths.tmpTest);
	}

	static function getPaths(args:RunArgs):Paths {
		function captalize(str:String)
			return str.charAt(0).toUpperCase() + str.substr(1);

		var className = args.slug.split("-").map(captalize).join("");
		var solName = '$className.hx';
		var testName = "Test.hx";
		var tmpDir = createTmpDir();
		return {
			inputSol: Path.join([args.inputDir, "src", solName]),
			inputTest: Path.join([args.inputDir, "test", testName]),
			tmpSol: Path.join([tmpDir, solName]),
			tmpTest: Path.join([tmpDir, testName]),
			tmpReporter: Path.join([tmpDir, "JsonReporter.hx"]),
			outResults: Path.join([args.outputDir, "results.json"]),
			outDir: args.outputDir
		};
	}

	static function createTmpDir():String {
		var path = "/tmp/haxe_test_runner";
		Fs.deleteDirectory(path);
		Fs.createDirectory(path);
		return path;
	}

	static function writeHelp() {
		Sys.println(helpMsg);
		Sys.exit(0);
	}

	static function writeError(errorMsg:String) {
		Sys.println('Error: $errorMsg\n');
		writeHelp();
	}

	static function writeErrorJsonResult(path:String, errorMsg:String) {
		var result = {
			status: "error",
			message: errorMsg,
			tests: []
		};
		File.saveContent(path, haxe.Json.stringify(result));
	}

	// Checks command-line arguments and returns RunArgs if valid or exits on error
	static function parseArgs():RunArgs {
		var args = Sys.args();
		var flags = args.filter(x -> x.startsWith("-")).map(x -> x.toLowerCase());
		if (flags.contains("-h") || flags.contains("--help"))
			writeHelp();
		if (flags.exists(x -> x != "-h" || x != "--help"))
			writeError("invalid command line options");
		if (args.length > 3)
			writeError("too many arguments");
		if (args.length < 3)
			writeError("not enough arguments");

		var slug = args[0];
		var inputDir = args[1];
		var outputDir = args[2];
		if (inputDir.charAt(inputDir.length - 1) != "/")
			writeError("inputDir must end with a trailing slash");
		if (outputDir.charAt(outputDir.length - 1) != "/")
			writeError("outputDir must end with a trailing slash");
		if (!Fs.exists(inputDir))
			writeError('inputDir "$inputDir" does not exist');

		return {
			slug: slug,
			inputDir: inputDir,
			outputDir: outputDir
		};
	}
}
