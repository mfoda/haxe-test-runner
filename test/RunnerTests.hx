package;

import haxe.io.Path;
import sys.io.File;
import haxe.Json;
import sys.FileSystem as FS;

using buddy.Should;
using StringTools;
using Lambda;

class RunnerTests extends buddy.SingleSuite {
	static final appDir = Path.directory(Sys.programPath());
	static final runnerBin = Path.join([appDir, "..", "bin", "runner.n"]);

	public function new() {
		describe("Test results against golden tests", {
			function filterDirs(path)
				return FS.readDirectory(path).map(x -> Path.join([path, x])).filter(FS.isDirectory);

			for (status in ["error", "pass", "fail"]) {
				var testsPath = Path.join([appDir, status]);
				var testDirs = filterDirs(testsPath);
				for (testDir in testDirs) {
					var slug = filterDirs(testDir)[0].split("/").pop();
					var inputDir = Path.join([testDir, slug]);
					var outputDir = Path.join([testDir, "tmp_output"]);
					var runnerProc = new sys.io.Process("neko", [
						runnerBin,
						slug,
						Path.addTrailingSlash(inputDir),
						Path.addTrailingSlash(outputDir)
					]);
					// wait for runner process to finish
					var exitCode = runnerProc.exitCode(true);

					it("runner exit code should only be 1 on error", {
						if (status == "error")
							exitCode.should.be(1);
						if (status == "fail" || status == "pass")
							exitCode.should.be(0);
					});

					it("runner results.json should match expected_results.json", {
						var expectedFile = Path.join([testDir, "expected_results.json"]);
						var expectedResults = Json.parse(File.getContent(expectedFile));
						var actualFile = Path.join([outputDir, "results.json"]);
						var actualResults = Json.parse(File.getContent(actualFile));
						// convert back to json string for comparison
						Json.stringify(actualResults).should.be(Json.stringify(expectedResults));
					});
					break;
				}
				break;
			}
		});
	}
}
