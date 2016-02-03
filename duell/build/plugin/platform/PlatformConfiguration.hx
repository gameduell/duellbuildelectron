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

typedef JSSource = {
	source : String,
	target : String
}

typedef PlatformConfigurationData = {
	PLATFORM_NAME : String,
	WIDTH : String,
	HEIGHT : String,
	BGCOLOR : String,
	JS_SOURCES : Array<JSSource>,
	JQUERY : JSSource
}

class PlatformConfiguration
{
	public static var _configuration : PlatformConfigurationData = null;
	public static var _parsingDefines : Array<String> = ["electron", "html5"];

	public function new()
	{}

	public static function getData() : PlatformConfigurationData
	{
		if(_configuration == null)
			initConfig();

		return _configuration;
	}

	public static function getConfigParsingDefines() : Array<String>
	{
		return _parsingDefines;
	}

	public static function initConfig() : Void
	{
		_configuration =
		{
			PLATFORM_NAME : "electron",
			WIDTH : "1024",
			HEIGHT : "768",
			BGCOLOR : "#FFF",//same as #FFFFFF
			JS_SOURCES : [],
			JQUERY : null
		};
	}
}
