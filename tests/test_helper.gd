class_name TestHelper
extends RefCounted

var _passed: int = 0
var _failed: int = 0

func check(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: ", label)
	else:
		_failed += 1
		print("  FAIL: ", label)

func eq(actual, expected, label: String) -> void:
	check(actual == expected, "%s (expected %s, got %s)" % [label, str(expected), str(actual)])

# 返回进程退出码：0 全过，1 有失败
func summary(suite: String) -> int:
	print("[%s] passed=%d failed=%d" % [suite, _passed, _failed])
	return 0 if _failed == 0 else 1
