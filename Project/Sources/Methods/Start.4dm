// Startup method, called without parameters by the On Startup database method
// and with a parameter by itself through CALL WORKER (see the 4dstartup skill).

#DECLARE($params : Object)

var $title : Text
var $window : Integer
var $i : Integer
$title:="Mesh Thumbnail Studio"

If (Count parameters=0)

	// already open? bring it to the front instead of opening a duplicate
	ARRAY LONGINT($windows; 0)
	WINDOW LIST($windows)
	For ($i; 1; Size of array($windows))
		$window:=$windows{$i}
		If (Window process($window)=1) && (Get window title($window)=$title)
			var $left; $top; $right; $bottom : Integer
			GET WINDOW RECT($left; $top; $right; $bottom; $window)
			CALL FORM($window; Formula(SET WINDOW RECT($left; $top; $right; $bottom; $window)))
			return 
		End if 
	End for 

	CALL WORKER(1; Current method name; {})

Else 

	SET MENU BAR(1)
	$window:=Open form window("Studio"; Plain form window; Horizontally centered; Vertically centered)
	SET WINDOW TITLE($title; $window)
	DIALOG("Studio")

End if 
