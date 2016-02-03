## Description
 
Use this plugin to build for the electron platform.
## Usage:
`$ duell build electron`
## Arguments:

## Project Configuration Documentation:
* `<js-source>` &ndash; Use this to include external javascript code.E.g.:
`<js-source path="libs/mylib.js" applyTemplate="true|false" renamePackage="oldPackageName-newPackageName"/>`. It supports multiple tags. The applyTemplate and renamePackages attributes are optional.
* `<win-size>` &ndash; Use this to specifie the canvas dimension(width x height) in the application html page. E.g.:
`<win-size width="1024" height="768"/>`. It supports multiple tags. The applyTemplate and renamePackages attributes are optional.