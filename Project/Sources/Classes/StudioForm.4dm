// Interactive studio for the miyako/mesh 4D component.
// The component (cs.MeshPreview.Thumbnailer) wraps the mesh-thumb CLI.
// The form class is the only place that talks to it; object methods are one-liners.

property tool : cs.MeshPreview.Thumbnailer
property fileList : Object
property view : Text
property size : Integer
property quality : Integer
property background : Text
property status : Text
property preview : Picture
property fileMeta : Text
property geometryText : Text
property capabilitiesText : Text
property versionText : Text
property stats : Text
property howText : Text
property tryText : Text

Class constructor
	This.fileList:=New object("values"; New collection(); "index"; 0; "currentValue"; "")
	This.view:="iso"
	This.size:=256
	This.quality:=2
	This.background:="#20242B"
	This.status:="Starting..."
	This.fileMeta:=""
	This.geometryText:=""
	This.capabilitiesText:=""
	This.versionText:=""
	This.stats:=""
	This.howText:="StudioForm.init() creates cs.MeshPreview.Thumbnailer, then renders on every option change. The component launches the mesh-thumb binary bundled in its own Resources/bin folder through 4D.SystemWorker, parses the JSON envelope (schema_version 1) and hands back a picture plus geometry stats. No native plug-in, no helper process left behind."
	This.tryText:="1. Use the Iso / Top / Front / Side buttons.\n2. Push size to 512 and quality to 4.\n3. Pick ring_ascii.ply: a point cloud, not a mesh.\n4. Choose the transparent background.\n5. Render the corrupt STL and read the error envelope."

Function init()
	var $target : Text
	$target:="macOS-universal"
	If (Is Windows)
		$target:="Windows-x64"
	End if 
	This.tool:=cs.MeshPreview.Thumbnailer.new($target)
	This.loadFixtures()
	This.loadCapabilities()
	This.render()

Function loadFixtures()
	var $folder : 4D.Folder
	var $names : Collection
	var $file : 4D.File
	$folder:=Folder("/RESOURCES/fixtures")
	$names:=New collection()
	If ($folder.exists)
		For each ($file; $folder.files())
			$names.push($file.fullName)
		End for each 
	End if 
	$names.sort()
	This.fileList.values:=$names
	If ($names.length>0)
		This.fileList.index:=0
	Else 
		This.fileList.index:=-1
		This.status:="No fixtures found in /RESOURCES/fixtures"
	End if 

Function selectedFileName()->$name : Text
	$name:=""
	If ((This.fileList.values.length>0) && (This.fileList.index>=0) && (This.fileList.index<This.fileList.values.length))
		$name:=This.fileList.values[This.fileList.index]
	End if 

Function render()
	var $name : Text
	var $input : 4D.File
	var $result : Object
	var $options : Object
	var $started
	var $elapsed
	var $output : 4D.File
	var $png : Picture

	$name:=This.selectedFileName()
	If ($name="")
		This.status:="Pick a geometry file first."
		return 
	End if 
	$input:=Folder("/RESOURCES/fixtures").file($name)
	$output:=This.outputFile($name+".png")
	$options:=New object("size"; This.size; "view"; This.view; "background"; This.background; "quality"; This.quality)
	$started:=Milliseconds
	$result:=This.tool.render($input; $output; $options)
	$elapsed:=Milliseconds-$started
	If ($result.ok)
		READ PICTURE FILE($output.platformPath; $png)
		This.preview:=$png
		This.stats:=This.describeRender($result; $elapsed)
		This.status:="Rendered in "+String($elapsed)+" ms"
		This.inspectGeometry($input)
	Else 
		This.stats:="No PNG written"
		This.status:=This.describeError($result)
	End if 

Function inspectGeometry($input : 4D.File)
	var $result : Object
	$result:=This.tool.inspect($input)
	If ($result.ok)
		This.geometryText:=This.describeGeometry($result.value)
	Else 
		This.geometryText:="inspect() failed: "+String($result.error.message)
	End if 

Function describeGeometry($value : Object)->$text : Text
	var $g : Object
	$g:=$value.geometry
	$text:="format     "+String($value.input.format)+" ("+String($value.input.file_size)+" bytes)"
	$text:=$text+"\nkind       "+String($g.kind)
	$text:=$text+"\nvertices   "+String($g.vertices)
	$text:=$text+"\ntriangles  "+String($g.triangles)
	If ($g.bounds.valid)
		$text:=$text+"\nbounds min "+This.pointText($g.bounds.min)
		$text:=$text+"\nbounds max "+This.pointText($g.bounds.max)
	End if 
	$text:=$text+"\ncolors     "+This.flagText($g.colors)+"    normals "+This.flagText($g.normals)
	$text:=$text+"\nwarnings   degenerate "+String($value.warnings.degenerate_triangles)+" / non-finite "+String($value.warnings.non_finite_vertices)
	return $text

Function describeRender($result : Object; $elapsed)->$text : Text
	$text:=String($result.value.width)+" x "+String($result.value.height)+" PNG"
	$text:=$text+"  ·  "+String($result.value.geometry.triangles)+" triangles"
	$text:=$text+"  ·  cache "+String($result.value.cache)
	$text:=$text+"  ·  process "+String($elapsed)+" ms"
	return $text

Function describeError($result : Object)->$text : Text
	$text:="render() failed as designed.\ncode: "+String($result.error.code)
	$text:=$text+"\nmessage: "+String($result.error.message)
	If (String($result.error.stage)#"")
		$text:=$text+"\nstage: "+String($result.error.stage)
	End if 
	return $text

Function pointText($p : Collection)->$text : Text
	$text:="("+String($p[0])+", "+String($p[1])+", "+String($p[2])+")"
	return $text

Function flagText($flag : Boolean)->$text : Text
	$text:="no"
	If ($flag)
		$text:="yes"
	End if 
	return $text

Function loadCapabilities()
	var $result : Object
	$result:=This.tool.capabilities()
	If ($result.ok)
		This.capabilitiesText:=This.describeCapabilities($result.value)
	Else 
		This.capabilitiesText:="capabilities() failed: "+String($result.error.message)
	End if 
	var $v : Object
	$v:=This.tool.version()
	If ($v.ok)
		This.versionText:="mesh-thumb "+String($v.value.version)
	Else 
		This.versionText:="mesh-thumb (version failed)"
	End if 

Function describeCapabilities($value : Object)->$text : Text
	$text:="binary     "+String($value.app)+" "+String($value.version)
	$text:=$text+"\nformats    "+$value.formats.join(", ")
	$text:=$text+"\nviews      "+$value.views.join(", ")
	$text:=$text+"\nquality    1 - "+String($value.max_quality)
	$text:=$text+"\nmax size   "+String($value.max_output_dimension)+" px"
	$text:=$text+"\nmax pixels "+String($value.max_output_pixels)
	$text:=$text+"\ngpu        "+This.flagText($value.gpu_backend_available)
	return $text

Function setView($view : Text)
	This.view:=$view
	This.render()

Function demoError()
	var $input : 4D.File
	var $output : 4D.File
	var $result : Object
	$input:=Folder("/RESOURCES/broken").file("truncated.stl")
	$output:=This.outputFile("error-demo.png")
	$result:=This.tool.render($input; $output; {size: This.size; view: This.view; background: This.background; quality: This.quality})
	If ($result.ok)
		This.status:="Unexpected success -- the corrupt fixture parsed."
	Else 
		This.status:=This.describeError($result)
	End if 

Function reset()
	This.view:="iso"
	This.size:=256
	This.quality:=2
	This.background:="#20242B"
	This.status:="Reset to defaults"
	This.render()

Function outputFile($name : Text)->$file : 4D.File
	// Renders land in <database>/output so the results are easy to inspect.
	// Folder(fk temporary folder) returns Null under tool4d --dataless.
	var $folder : 4D.Folder
	$folder:=Folder(fk database folder).folder("output")
	If (Not($folder.exists))
		$folder.create()
	End if 
	$file:=$folder.file($name)
