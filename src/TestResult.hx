package;

import RunnerResult;

class TestResult {
	public var name:String;
	public var status:ResultStatus;
	public var message:String;
	public var output:String;
	public var testCode:String;

	public function new() {}

	public function toJsonString():String {
		return haxe.Json.stringify({
			name: name,
			status: status.getName(),
			message: message,
			output: output,
			testCode: testCode
		});
	}
}
