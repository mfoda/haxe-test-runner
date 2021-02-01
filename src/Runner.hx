package;

import RunnerResult;
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
	inputDir:String,
	tmpDir:String,
	outputDir:String,
	inputSolution:String,
	inputTest:String,
	tmpSolution:String,
	tmpTest:String,
	outputResults:String,
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
		prepareOutputDir(paths);
		var exitCode = run(paths);
		Sys.exit(exitCode);
	}

	// Run the tests for the given exercise and produce a results.json
	static function run(paths:Paths):Int {
		// if tests can't compile then exit without running, report compile error
		var compArgs = ["-cp", '${paths.tmpDir}', "-m", "Test.hx", "--no-output", "-L", "buddy"];
		var compProc = new sys.io.Process("haxe", compArgs);
		var compExitCode = compProc.exitCode();
		if (compExitCode != 0) {
			var compError = compProc.stderr.readAll().toString();
			writeTopLevelErrorJson(paths.outputResults, compError.trim());
			return compExitCode;
		}
		// run tests, report test result
		var testArgs = [
			"-cp",
			'${paths.tmpDir}',
			"-x",
			"Test.hx",
			"-L",
			"buddy",
			"-D",
			'reporter=Reporter'
		];
		var testProc = new sys.io.Process("haxe", testArgs);
		var testResult = testProc.stdout.readAll().toString();
		File.saveContent(paths.outputResults, testResult);
		return 0;
	}

	static function getPaths(args:RunArgs):Paths {
		function captalize(str:String)
			return str.charAt(0).toUpperCase() + str.substr(1);

		var solName = args.slug.split("-").map(captalize).join("");
		solName = '$solName.hx';
		var testName = "Test.hx";
		var tmpDir = createTmpDir();
		return {
			inputDir: args.inputDir,
			tmpDir: tmpDir,
			outputDir: args.outputDir,
			inputSolution: Path.join([args.inputDir, "src", solName]),
			inputTest: Path.join([args.inputDir, "test", testName]),
			tmpSolution: Path.join([tmpDir, solName]),
			tmpTest: Path.join([tmpDir, testName]),
			outputResults: Path.join([args.outputDir, "results.json"]),
		};
	}

	static function prepareOutputDir(paths:Paths) {
		var appDir = Path.directory(Sys.programPath());
		Fs.createDirectory(paths.outputDir);
		File.copy(paths.inputSolution, paths.tmpSolution);
		File.copy(paths.inputTest, paths.tmpTest);
		File.copy('$appDir/Reporter.hx', '${paths.tmpDir}/Reporter.hx');
		File.copy('$appDir/RunnerResult.hx', '${paths.tmpDir}/RunnerResult.hx');
		File.copy('$appDir/TestResult.hx', '${paths.tmpDir}/TestResult.hx');
	}

	static function createTmpDir():String {
		var path = "./tmp/haxe_test_runner";
		// TODO: delete existing tmpDir
		// if (Fs.exists(path))
		// 	Fs.deleteDirectory(path);
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

	static function writeTopLevelErrorJson(path:String, errorMsg:String) {
		var result = new RunnerResult();
		result.status = ResultStatus.Error(errorMsg);
		File.saveContent(path, result.toJsonString());
	}

	// Check command-line arguments and return RunArgs if valid or exits on error
	static function parseArgs():RunArgs {
		var args = Sys.args();
		// var args = [
		// 	"identity",
		// 	"D:/source/haxe/haxe-test-runner/test/error/compiletime_error_empty_solution/identity/",
		// 	"D:/source/haxe/haxe-test-runner/test/error/compiletime_error_empty_solution/out/"
		// ];
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
