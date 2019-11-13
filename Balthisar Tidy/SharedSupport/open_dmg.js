/**
 *  Open the specified DMG.
 *  Created by: Jim Derry
 *  Created on: 2018-04-11
 *
 *  Copyright © 2018-2019 Jim Derry. All Rights Reserved.
 *  MIT License.
 */

const app = Application.currentApplication();
const systemEvents = Application('System Events')
app.includeStandardAdditions = true;

var this_path = app.pathTo(this);


/* This is the event that the Apple Help Book calls when the script is executed. */
function helphdhp( dmgFile )
{
	app.displayDialog("Hi there!\n" + this_path);

	const dir = $.NSString.alloc.initWithUTF8String(this_path).stringByDeletingLastPathComponent.js;

	app.displayDialog("dir:\n" + dir);

	const dmgPath = $.NSString.pathWithComponents( [dir, "..", "..", "..", "..", "..", dmgFile] ).stringByStandardizingPath.js;

	Application('Finder').open(Path(dmgPath));
}

/* This event is run when the script is executed in an editor. */
function run()
{
	helphdhp("AppleScriptsforTidy.dmg");
}
	
