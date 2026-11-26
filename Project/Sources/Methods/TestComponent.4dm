// Headless self-test for the demo and for the miyako/mesh component.
//
//   tool4d --dataless --skip-onstartup --startup-method TestComponent \
//     --project Project/mesh-demo.4DProject --user-param /tmp/mesh-demo-report.json
//
// Prints PASS/FAIL to the standard outputs and, when --user-param names a
// path, writes the same checks as JSON.

#DECLARE()

var $checks : Collection
var $ok : Boolean
var $reportPath : Text
var $target : Text
var $tool : cs.MeshPreview.Thumbnailer

$checks:=New collection()
$ok:=True
Get database parameter(User param value; $reportPath)

$target:="macOS-universal"
If (Is Windows)
	$target:="Windows-x64"
End if 

$tool:=cs.MeshPreview.Thumbnailer.new($target)

// --- version / capabilities ---------------------------------------------

var $ver : Object
$ver:=$tool.version()
$checks.push(demoCheck("version is 0.3.0"; $ver.ok && ($ver.value.version="0.3.0"); String($ver.value.version)))

var $caps : Object
$caps:=$tool.capabilities()
$checks.push(demoCheck("capabilities.ok"; $caps.ok; String($caps.exitCode)))
If ($caps.ok)
	$checks.push(demoCheck("capabilities lists stl and ply"; (Position("stl"; $caps.value.formats.join(","))>0) && (Position("ply"; $caps.value.formats.join(","))>0); $caps.value.formats.join(",")))
	$checks.push(demoCheck("capabilities max size 8192"; ($caps.value.max_output_dimension=8192); String($caps.value.max_output_dimension)))
Else 
	$checks.push(demoCheck("capabilities.ok"; False; String($caps.error.message)))
End if 

// --- render every fixture in every view, at two sizes --------------------

var $fixtures : Collection
var $views : Collection
var $folder : 4D.Folder
var $outFolder : 4D.Folder
$fixtures:=New collection("cube_ascii.stl"; "ring_ascii.ply"; "tri_binary.stl")
$views:=New collection("iso"; "top"; "front"; "side")
$folder:=Folder("/RESOURCES/fixtures")
$outFolder:=Folder(fk database folder).folder("output/test")
If (Not($outFolder.exists))
	$outFolder.create()
End if 

var $f; $v; $size : Text
For each ($f; $fixtures)
	For each ($v; $views)
		For each ($size; New collection("96"; "256"))
			var $out : 4D.File
			var $r : Object
			var $label : Text
			$label:=Substring($f; 1; Position("."; $f)-1)+"-"+$v+"-"+$size+".png"
			$out:=$outFolder.file($label)
			$r:=$tool.render($folder.file($f); $out; {size: Num($size); view: $v; quality: 2})
			$checks.push(demoCheck("render "+$f+" "+$v+" "+$size; $r.ok && $out.exists && ($out.size>0); String($r.error.message)))
		End for each 
	End for each 
End for each 

// --- inspect --------------------------------------------------------------

For each ($f; $fixtures)
	var $info : Object
	$info:=$tool.inspect($folder.file($f))
	$checks.push(demoCheck("inspect "+$f; $info.ok && ($info.value.geometry.vertices>0); String($info.value.geometry.vertices)+" vertices / "+String($info.value.geometry.kind)))
End for each 

// --- structured failures ---------------------------------------------------

var $broken : 4D.Folder
$broken:=Folder("/RESOURCES/broken")
var $bad : Object
$bad:=$tool.render($broken.file("truncated.stl"); $outFolder.file("bad.png"); {size: 96; view: "iso"; quality: 1})
$checks.push(demoCheck("truncated STL -> invalid_stl"; (Not($bad.ok)) && ($bad.error.code="invalid_stl"); String($bad.error.code)+": "+String($bad.error.message)))

$bad:=$tool.render($broken.file("not_a_mesh.bin"); $outFolder.file("bad2.png"); {size: 96; view: "iso"; quality: 1})
$checks.push(demoCheck("unknown format -> unsupported_format"; (Not($bad.ok)) && ($bad.error.code="unsupported_format"); String($bad.error.code)))

$bad:=$tool.render($folder.file("cube_ascii.stl"); $outFolder.file("bad3.png"); {size: 96; view: "iso"; quality: 99})
$checks.push(demoCheck("quality 99 -> invalid_argument (wrapper validates)"; (Not($bad.ok)) && ($bad.error.code="invalid_argument"); String($bad.error.code)+": "+String($bad.error.message)))

$bad:=$tool.render($folder.file("cube_ascii.stl"); $outFolder.file("bad4.png"); {size: 70000; view: "iso"; quality: 1})
$checks.push(demoCheck("size 70000 -> resource_limit_exceeded"; (Not($bad.ok)) && ($bad.error.code="resource_limit_exceeded"); String($bad.error.code)))

// --- the form class itself, headless --------------------------------------

var $form : cs.StudioForm
$form:=cs.StudioForm.new()
$form.init()
$checks.push(demoCheck("StudioForm.init lists 3 fixtures"; ($form.fileList.values.length=3); String($form.fileList.values.length)))
$checks.push(demoCheck("StudioForm.init rendered a preview"; (Position("No PNG"; $form.stats)=0) && (Position("PNG"; $form.stats)>0); $form.stats))
$checks.push(demoCheck("StudioForm geometry text"; (Position("vertices"; $form.geometryText)>0); $form.geometryText))
$checks.push(demoCheck("StudioForm capabilities text"; (Position("stl"; $form.capabilitiesText)>0); $form.capabilitiesText))
$checks.push(demoCheck("StudioForm version text"; (Position("mesh-thumb"; $form.versionText)>0); $form.versionText))

$form.setView("top")
$checks.push(demoCheck("setView(top) re-renders"; ($form.view="top") && (Position("No PNG"; $form.stats)=0); $form.stats))

$form.demoError()
$checks.push(demoCheck("demoError shows invalid_stl"; (Position("invalid_stl"; $form.status)>0); $form.status))

$form.demoError()
$checks.push(demoCheck("demoError alternates to unsupported_format"; (Position("not_a_mesh.bin"; $form.status)>0) && (Position("unsupported_format"; $form.status)>0); $form.status))

$form.size:=5000
$form.quality:=0
$form.render()
$checks.push(demoCheck("render clamps typed size/quality"; ($form.size=1024) && ($form.quality=1) && (Position("No PNG"; $form.stats)=0); String($form.size)+" / "+String($form.quality)))

$checks.push(demoCheck("fileMeta describes the selected fixture"; (Position("bytes"; $form.fileMeta)>0); $form.fileMeta))

$form.reset()
$checks.push(demoCheck("reset restores defaults"; ($form.size=256) && ($form.quality=2) && ($form.view="iso"); String($form.size)))

// --- report ---------------------------------------------------------------

// 4D Collections are 0-based: iterate 0 .. length-1.
var $i : Integer
For ($i; 0; $checks.length-1)
	If ($checks[$i].ok=False)
		$ok:=False
	End if 
	LOG EVENT(Into system standard outputs; $checks[$i].name+": "+Choose($checks[$i].ok; "ok"; "FAIL")+" -- "+$checks[$i].detail)
End for 

If ($reportPath#"")
	var $report : Object
	$report:=New object("ok"; $ok; "checks"; $checks; "target"; $target)
	var $file : 4D.File
	$file:=File($reportPath)
	$file.setText(JSON Stringify($report; *))
End if 

If ($ok)
	LOG EVENT(Into system standard outputs; "PASS "+String($checks.length)+" checks")
Else 
	LOG EVENT(Into system standard outputs; "FAIL")
End if 
