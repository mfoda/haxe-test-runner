import haxe.Json;
import sys.io.File;
import promhx.Deferred;
import buddy.BuddySuite;
import promhx.Promise;

using StringTools;
using Lambda;

enum JsonTestStatus {
	Pass;
	Fail(message:String);
	Error(message:String);
}

typedef JsonTestResult = {
	name:String,
	status:JsonTestStatus,
	output:String
}

typedef ResultJson = {
	status:JsonTestStatus,
	tests:List<JsonTestResult>
}

class JsonReporter implements buddy.reporting.Reporter {
	public function start():Promise<Bool> {
		return resolveImmediately(true);
	}

	public function progress(spec:Spec):Promise<Spec> {
		return resolveImmediately(spec);
	}

	public function done(suites:Iterable<Suite>, status:Bool):Promise<Iterable<Suite>> {
		var total = 0;
		var failures = 0;
		var pending = 0;

		var countTests:Suite->Void = null;
		countTests = function(s:Suite) {
			if (s.error != null)
				failures++; // Count a crashed BuddySuite as a failure?

			for (sp in s.steps)
				switch sp {
					case TSpec(sp):
						total++;
						if (sp.status == Failed)
							failures++;
						else if (sp.status == Pending)
							pending++;
					case TSuite(s):
						countTests(s);
				}
		};
		suites.iter(countTests);

		return resolveImmediately(suites);
	}

	/**
	 * Convenience method.
	 */
	private function resolveImmediately<T>(o:T):Promise<T> {
		var def = new Deferred<T>();
		var pr = def.promise();
		def.resolve(o);
		return pr;
	}
}

class JsonOutputFormatter {
	var outpath:String;
	var testErrors = new List<String>();
	var stackTrace:String;

	public function new(outpath:String) {
		this.outpath = outpath;
	}

	function replacer(key:Dynamic, value:Dynamic):Dynamic {
		return null;
	}

	public function addError(err:String) {
		testErrors.add(err);
	}

	public function close() {
		var resultObj:Dynamic;
		File.saveContent(outpath, Json.stringify(resultObj));
	}
}
