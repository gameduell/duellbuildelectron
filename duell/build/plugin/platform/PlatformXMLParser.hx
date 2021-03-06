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

import haxe.xml.Fast;

import duell.build.objects.DuellProjectXML;
import duell.build.objects.Configuration;
import duell.helpers.XMLHelper;
import duell.helpers.LogHelper;

import haxe.io.Path;

 class PlatformXMLParser
 {
 	public function new()
 	{}

 	public static function parse(xml : Fast) : Void
	{
		for (element in xml.elements)
		{
			switch(element.name)
			{
			case 'electron':
					parsePlatform(element);
			}
		}
	}
	public static function parsePlatform(xml: Fast) : Void
	{
		for (element in xml.elements)
		{
			if (!XMLHelper.isValidElement(element, DuellProjectXML.getConfig().parsingConditions))
				continue;

			switch (element.name)
			{
				case "win-size":
					parseWinSizeElement(element);
				case "js-source":
					parseJSSourceElement(element);
				case "jquery":
					parseJQueryElement(element);
				case "main":
					parseMainElement(element);
			}
		}
	}

	public static function parseWinSizeElement(element : Fast) : Void
	{
		if(element.has.width)
		{
			PlatformConfiguration.getData().WIDTH = element.att.width;
		}

		if(element.has.height)
		{
			PlatformConfiguration.getData().HEIGHT = element.att.height;
		}
	}

	private static function parseJSSourceElement(element : Fast): Void
	{
		if(element.has.path)
		{
			var pathResolved = resolvePath(element.att.path);
			var path = new Path( pathResolved );

			PlatformConfiguration.getData().JS_SOURCES.push({
				source : pathResolved, 
				target : "libs/" + path.file + "." + path.ext,
				applyTemplate : element.has.applyTemplate ? element.att.applyTemplate == "true" : false
			});
		}
		else
		{
			LogHelper.info("Element 'js-source' doesn't has a 'path' attribute!");
		}
	}

	private static function parseJQueryElement(element : Fast): Void
	{
		if(element.has.path)
		{
			var pathResolved = resolvePath(element.att.path);
			var path = new Path( pathResolved );

			PlatformConfiguration.getData().JQUERY = {
				source : pathResolved, 
				target : "libs/" + path.file + "." + path.ext,
				applyTemplate : false
			};
		}
		else
		{
			LogHelper.info("Element 'js-source' doesn't has a 'path' attribute!");
		}
	}

	private static function parseMainElement(element : Fast): Void
	{
		if(element.has.source && element.has.targetName)
		{
			PlatformConfiguration.getData().MAIN_CLASS_SOURCE = element.att.source;
			PlatformConfiguration.getData().MAIN_CLASS_EXPORT = element.att.targetName;
		}
	}

	private static function resolvePath(string : String) : String /// convenience method
	{
		return DuellProjectXML.getConfig().resolvePath( string );
	}
 }
