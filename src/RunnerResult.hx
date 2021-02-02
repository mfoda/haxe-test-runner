package;

import haxe.Json;

enum ResultStatus {
	Pass;
	Fail(?message:String);
	Error(message:String);
}

class RunnerResult {
	final version = 2;

	public var status:ResultStatus;
	public var message:String;
	public var tests:Array<TestResult>;

	public function new() {}

	public function toJsonString():String {
		var message:String = null;
		switch (status) {
			case Fail(msg), Error(msg):
				message = msg;
			case Pass:
		}
		// var testsEncoded = tests.map(x -> Json.parse(x.toJsonString()));
		return Json.stringify({
			// version: version,
			status: status.getName().toLowerCase(),
			tests: tests,
			message: message
		}, "  ");
	}
}
