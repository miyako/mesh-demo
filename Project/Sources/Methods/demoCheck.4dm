// Builds one self-test entry for TestComponent.
#DECLARE($name : Text; $ok : Boolean; $detail : Text)->$check : Object
$check:=New object("name"; $name; "ok"; $ok; "detail"; $detail)
