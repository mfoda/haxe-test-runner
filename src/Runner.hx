package;

import RunnerResult;
import sys.io.File;
import sys.FileSystem as FS;
import haxe.io.Path;
import FileTools;

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
		var args = [
			"-cp", '${paths.tmpDir}', "-L", "buddy", "-D", 'reporter=Reporter', "--run", "Test", "-resultPath", '${paths.outputDir}'
		];
		var proc = new sys.io.Process("haxe", args);
		var output = proc.stdout.readAll().toString();
		var errorResult = proc.stderr.readAll().toString();
		var exitCode = proc.exitCode();
		proc.close();
		// append user output to results
		
		if (exitCode != 0)
			writeTopLevelErrorJson(paths.outputResults, errorResult.trim());

		return exitCode;
	}

	static function getPaths(args:RunArgs):Paths {
		function captalize(str:String)
			return str.charAt(0).toUpperCase() + str.substr(1);

		// slug to classname, e.g. hello-world -> HelloWorld.hx
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
		FS.createDirectory(paths.outputDir);
		File.copy(paths.inputSolution, paths.tmpSolution);
		File.copy(paths.inputTest, paths.tmpTest);
		// copy our custom reporter to hook into it
		File.copy('$appDir/Reporter.hx', '${paths.tmpDir}/Reporter.hx');
		File.copy('$appDir/RunnerResult.hx', '${paths.tmpDir}/RunnerResult.hx');
		File.copy('$appDir/TestResult.hx', '${paths.tmpDir}/TestResult.hx');
	}

	static function createTmpDir():String {
		var path = "./tmp/haxe_test_runner";
		FileTools.deleteDirRecursively(path);
		FS.createDirectory(path);
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

	// Check command-line arguments and return RunArgs if valid or exit with error
	static function parseArgs():RunArgs {
		var args = Sys.args();
		args = [
			"identity",
			"D:/source/haxe/haxe-test-runner/test/error/compile_exception_in_solution/identity/",
			"D:/source/haxe/haxe-test-runner/test/error/compile_exception_in_solution/tmp_output/"
		];
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
		if (!FS.exists(inputDir))
			writeError('inputDir "$inputDir" does not exist');

		return {
			slug: slug,
			inputDir: inputDir,
			outputDir: outputDir
		};
	}
}
