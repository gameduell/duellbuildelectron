/*
* Copyright (c) 2003-2015, GameDuell GmbH
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice,
* this list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice,
* this list of conditions and the following disclaimer in the documentation
* and/or other materials provided with the distribution.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
* DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
* LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
* ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
* (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
* SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

package duell.build.plugin.platform;

import duell.build.objects.Configuration;
import duell.build.objects.DuellProjectXML;
import duell.objects.Arguments;
import duell.objects.DuellLib;
import duell.helpers.PathHelper;
import duell.helpers.TemplateHelper;
import duell.helpers.PlatformHelper;
import duell.helpers.CommandHelper;
import duell.helpers.DuellConfigHelper;
import duell.helpers.FileHelper;
import duell.helpers.LogHelper;

using StringTools;

import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;

class PlatformBuild
{
    // Need to run duell setup electron first
    public var requiredSetups = [{name: "electron", version: "master"}];

    // Cross-platform baby
    public var supportedHostPlatforms = [WINDOWS, MAC, LINUX];

    private var targetDirectory : String;
    private var duellBuildElectronPath : String;
    private var projectDirectory : String;
    private var templateConfig : String;

    public function new()
    {
        checkArguments();
    }

    public function checkArguments():Void
    {
        if (Arguments.isSet("-debug"))
        {
            Configuration.addParsingDefine("debug");
        }
        else
        {
            Configuration.addParsingDefine("release");
        }
    }

    public function parse() : Void
    {
        parseProject();
    }

    public function parseProject() : Void
    {
        var projectXML = DuellProjectXML.getConfig();
        projectXML.parse();
    }

    public function prepareBuild() : Void
    {
        if (Arguments.isSet("-debug"))
        {
            Configuration.getData().PLATFORM.DEBUG = true;
        }
        
        prepareVariables();

        convertDuellAndHaxelibsIntoHaxeCompilationFlags();
        convertParsingDefinesToCompilationDefines();
        forceHaxeJson();
        createDirectoryAndCopyTemplate();
        copyJSIncludes();
    }

    private function prepareVariables(): Void
    {
        targetDirectory = Configuration.getData().OUTPUT;
        projectDirectory = Path.join([targetDirectory, "electron"]);
        duellBuildElectronPath = DuellLib.getDuellLib("duellbuildelectron").getPath();
        templateConfig = PlatformConfiguration.getData().MAIN_CLASS_SOURCE == null ? "default.config" : "hxMain.config"; //use default config
    }

    private function convertDuellAndHaxelibsIntoHaxeCompilationFlags()
    {
        for (haxelib in Configuration.getData().DEPENDENCIES.HAXELIBS)
        {
            var version = haxelib.version;
            if (version.startsWith("ssh") || version.startsWith("http"))
            version = "git";
            Configuration.getData().HAXE_COMPILE_ARGS.push("-lib " + haxelib.name + (version != "" ? ":" + version : ""));
        }

        for (duelllib in Configuration.getData().DEPENDENCIES.DUELLLIBS)
        {
            Configuration.getData().HAXE_COMPILE_ARGS.push("-cp " + DuellLib.getDuellLib(duelllib.name, duelllib.version).getPath());
        }

        for (path in Configuration.getData().SOURCES)
        {
            Configuration.getData().HAXE_COMPILE_ARGS.push("-cp " + path);
        }
    }

    private function convertParsingDefinesToCompilationDefines()
    {

        for (define in DuellProjectXML.getConfig().parsingConditions)
        {
            if (define == "debug" )
            {
                Configuration.getData().HAXE_COMPILE_ARGS.push("-debug");
                continue;
            }

            Configuration.getData().HAXE_COMPILE_ARGS.push("-D " + define);
        }
    }

    private function forceHaxeJson(): Void
    {
        Configuration.getData().HAXE_COMPILE_ARGS.push("-D haxeJSON");
    }

    /**
        function createDirectoryAndCopyTemplate
        @return Void

        Copies certain template files, which are defined in '..template/*.config'
        into the target folder.
    **/
    public function createDirectoryAndCopyTemplate() : Void
    {
        /// Create directories
        PathHelper.mkdir(targetDirectory);

        var sourcePath = Path.join([duellBuildElectronPath, "template"]);
        var fileContent = File.getContent(Path.join([sourcePath, templateConfig]));
        var fileList = fileContent.split("\n");
        for ( file in fileList )
        {
            var fullFilePath = Path.join([targetDirectory, file]);
            var targetDir = Path.directory(fullFilePath);
            PathHelper.mkdir(targetDir);

            TemplateHelper.copyTemplateFile(
                Path.join([sourcePath, file]),
                fullFilePath,
                Configuration.getData(),
                Configuration.getData().TEMPLATE_FUNCTIONS
            );
        }
    }

    private function copyJSIncludes()
    {
        if( PlatformConfiguration.getData().JS_SOURCES.length == 0 && PlatformConfiguration.getData().JQUERY == null ) return;

        if( PlatformConfiguration.getData().JQUERY != null )
        {
            PlatformConfiguration.getData().JS_SOURCES.push( PlatformConfiguration.getData().JQUERY );
        }

        var targetFolder = Path.join([projectDirectory,"libs"]);

        if (!FileSystem.exists( targetFolder ))
        {
            FileSystem.createDirectory( targetFolder );
        }

        for ( jsSource in PlatformConfiguration.getData().JS_SOURCES )
        {
            var target = Path.join([projectDirectory, jsSource.target]);

            if(FileSystem.exists( target ))
            {
                FileSystem.deleteFile( target );
            }

            var fileOutput = File.write( target );

            if(jsSource.applyTemplate == true)
            {
                var fileContents:String = File.getContent( jsSource.source );
                var template:Template = new Template( fileContents );
                var result:String = template.execute(Configuration.getData(), Configuration.getData().TEMPLATE_FUNCTIONS);
                fileOutput.writeString( result );
            }
            else
            {
                var fileContents:String = File.getContent( jsSource.source );
                fileOutput.writeString( fileContents );
            }

            fileOutput.close();
        }
    }

    public function build(): Void
    {
        var buildPath : String = Path.join([targetDirectory,"electron","hxml"]);

        if(PlatformConfiguration.getData().MAIN_CLASS_SOURCE != null)
        {
            CommandHelper.runHaxe( buildPath,
                                ["BuildMain.hxml"],
                                {
                                    logOnlyIfVerbose : false,
                                    systemCommand : true,
                                    errorMessage: "compiling the haxe code for main process",
                                    exitOnError: true
                                });
        }

        CommandHelper.runHaxe( buildPath,
                                ["Build.hxml"],
                                {
                                    logOnlyIfVerbose : false,
                                    systemCommand : true,
                                    errorMessage: "compiling the haxe code",
                                    exitOnError: true
                                });
    }

    public function run(): Void
    {
        var args = [Path.join([projectDirectory, PlatformConfiguration.getData().MAIN_CLASS_EXPORT])];
        if(Arguments.isSet("-verbose"))
        {
            args.push("--enable-logging");
        }

        var electronFolder = Path.join([DuellConfigHelper.getDuellConfigFolderLocation(),
                                        "electron", "bin"]);
        CommandHelper.runCommand(electronFolder, "electron",
                                args,
                                {
                                    systemCommand: false
                                });
    }

    public function test(): Void
    {
    }

    public function clean(): Void
    {
    }

    public function handleError(): Void
    {
    }

    public function publish(): Void
    {
        throw "Publishing is not yet implemented for this platform";
    }

    public function fast(): Void
    {
    }

}
