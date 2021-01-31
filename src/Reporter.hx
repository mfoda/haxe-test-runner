package;

import RunnerResult;
import promhx.Deferred;
import buddy.BuddySuite;
import promhx.Promise;

using Lambda;
using StringTools;

/**
 * A custom reporter to output test results as json conforming to the exercism v3 spec
 */
class Reporter implements buddy.reporting.Reporter {
	public function new() {}

	public function start():Promise<Bool> {
		return resolveImmediately(true);
	}

	public function progress(spec:Spec):Promise<Spec> {
		return resolveImmediately(spec);
	}

	public function done(suites:Iterable<Suite>, status:Bool):Promise<Iterable<Suite>> {
		var testResults = [for (s in suites) suiteToTestResults(s)].flatten();
		var resultStatus = status ? ResultStatus.Pass : ResultStatus.Fail();
		var runnerResult = new RunnerResult();
		runnerResult.status = resultStatus;
		runnerResult.tests = testResults;

		Sys.print(runnerResult.toJsonString());
		return resolveImmediately(suites);
	}

	static function suiteToTestResults(suite:Suite):Array<TestResult> {
		var results = new Array<TestResult>();
		for (step in suite.steps) {
			switch step {
				case TSpec(spec):
					results.push(specToTestResult(spec));
				case TSuite(sui):
					results = results.concat(suiteToTestResults(sui));
			}
		}
		return results;
	}

	static function specToTestResult(spec:Spec):TestResult {
		var result = new TestResult();
		result.name = spec.fileName;
		var status:ResultStatus;
		switch (spec.status) {
			case Unknown:
				status = ResultStatus.Error(spec.description);
			case Passed:
				status = ResultStatus.Pass;
			case Pending:
				status = ResultStatus.Pass;
			case Failed:
				status = ResultStatus.Fail(spec.description);
		}
		result.status = status;
		result.message = spec.traces.join("\n");
		result.output = spec.description;
		result.testCode = "";
		return result;
	}

	// Convenience method
	private function resolveImmediately<T>(obj:T):Promise<T> {
		var deferred = new Deferred<T>();
		var promise = deferred.promise();
		deferred.resolve(obj);
		return promise;
	}
}
