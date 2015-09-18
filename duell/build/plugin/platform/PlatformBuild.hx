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

class PlatformBuild
{
    // Need to run duell setup electron first
 	public var requiredSetups = ["electron"];

    // Cross-platform baby
	public var supportedHostPlatforms = [WINDOWS, MAC, LINUX];

    // constants
    private static inline var TEST_RESULT_FILENAME = "test_result_electron.xml";
    private static inline var DEFAULT_SERVER_URL = "http://localhost:3000/";
    private static inline var DELAY_BETWEEN_PYTHON_LISTENER_AND_RUNNING_THE_APP = 2;

    // cmd arguments
    private var isDebug : Bool = false;
    private var isTest : Bool = false;
    private var applicationWillRunAfterBuild : Bool = false;

    private var fullTestResultPath : String;
    private var targetDirectory : String;
    private var duellBuildElectronPath : String;
    private var projectDirectory : String;

 	public function new()
 	{
 		checkArguments();
 	}
	public function checkArguments():Void
 	{
        if (Arguments.isSet("-debug"))
        {
            isDebug = true;
        }

        if(!Arguments.isSet("-norun"))
        {
            applicationWillRunAfterBuild = true;
        }

        if (Arguments.isSet("-test"))
		{
			isTest = true;
			applicationWillRunAfterBuild = true;
			Configuration.addParsingDefine("test");
		}

        if (isDebug)
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
        prepareVariables();

        convertDuellAndHaxelibsIntoHaxeCompilationFlags();
        convertParsingDefinesToCompilationDefines();
        forceHaxeJson();
        forceDeprecationWarnings();

 	}

    private function prepareVariables(): Void
    {
        targetDirectory = Configuration.getData().OUTPUT;
 	    projectDirectory = Path.join([targetDirectory, "electron"]);
		fullTestResultPath = Path.join([Configuration.getData().OUTPUT, "test", TEST_RESULT_FILENAME]);
 	    duellBuildElectronPath = DuellLib.getDuellLib("duellbuildelectron").getPath();
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

	private function forceDeprecationWarnings(): Void
	{
		Configuration.getData().HAXE_COMPILE_ARGS.push("-D deprecation-warnings");
	}
    public function createDirectoryAndCopyTemplate() : Void
 	{
 		/// Create directories
 		PathHelper.mkdir(targetDirectory);

 	    ///copying template files
 	    /// index.html, index.js
 	    TemplateHelper.recursiveCopyTemplatedFiles(Path.join([duellBuildElectronPath, "template", "electron"]), projectDirectory, Configuration.getData(), Configuration.getData().TEMPLATE_FUNCTIONS);
 	}
 	public function build(): Void
 	{
 	}

 	public function run(): Void
 	{
 	}

	public function test(): Void
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
