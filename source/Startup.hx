package;

import openfl.media.Sound;
import title.*;
import config.*;
import transition.data.*;

import flixel.FlxState;
import openfl.Assets;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.text.FlxText;
import openfl.system.System;

using StringTools;

class Startup extends FlxState
{
    var nextState:FlxState = new TitleVideo();

    var splash:FlxSprite;
    var loadingText:FlxText;

    var songsCached:Bool;
    public static final songs:Array<String> = ["Tutorial", "klaskiiLoop", "freakyMenu"]; //Start of the non-gameplay songs.
                                
    //List of character graphics and some other stuff.
    //Just in case it want to do something with it later.
    var charactersCached:Bool;
    var startCachingCharacters:Bool = false;
    var charI:Int = 0;
    public static final characters:Array<String> = ["BOYFRIEND", "GF_assets", "DADDY_DEAREST"];

    var graphicsCached:Bool;
    var startCachingGraphics:Bool = false;
    var gfxI:Int = 0;
    public static final graphics:Array<String> = ["logoBumpin", "logoBumpin2", "titleBG", "gfDanceTitle", "gfDanceTitle2", "titleEnter", "stageback", "stagefront", 
    "stagecurtains"];

    var cacheStart:Bool = false;

    public static var thing = false;

	override function create()
	{
        FlxG.mouse.visible = false;
        FlxG.sound.muteKeys = null;

        FlxG.save.bind('data');
		Highscore.load();
		KeyBinds.keyCheck();
		PlayerSettings.init();

        PlayerSettings.player1.controls.loadKeyBinds();
		Config.configCheck();

        UIStateExt.defaultTransIn = ScreenWipeIn;
        UIStateExt.defaultTransInArgs = [1.2];
        UIStateExt.defaultTransOut = ScreenWipeOut;
        UIStateExt.defaultTransOutArgs = [0.6];

        if (FlxG.save.data.weekUnlocked != null)
		{
			if (StoryMenuState.weekUnlocked.length < 4)
				StoryMenuState.weekUnlocked.insert(0, true);

			// QUICK PATCH OOPS!
			if (!StoryMenuState.weekUnlocked[0])
				StoryMenuState.weekUnlocked[0] = true;
		}

        if( FlxG.save.data.musicPreload2 == null ||
            FlxG.save.data.charPreload2 == null ||
            FlxG.save.data.graphicsPreload2 == null)
        {
            openPreloadSettings();
        }
        else{
            songsCached = !FlxG.save.data.musicPreload2;
            charactersCached = !FlxG.save.data.charPreload2;
            graphicsCached = !FlxG.save.data.graphicsPreload2;
        }

        splash = new FlxSprite(0, 0);
        splash.frames = Paths.getSparrowAtlas('fpsPlus/rozeSplash');
        splash.animation.addByPrefix('start', 'Splash Start', 24, false);
        splash.animation.addByPrefix('end', 'Splash End', 24, false);
        add(splash);
        splash.animation.play("start");
        splash.updateHitbox();
        splash.screenCenter();

        loadingText = new FlxText(5, FlxG.height - 30, 0, "", 24);
        loadingText.setFormat(Paths.font("vcr"), 24, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        add(loadingText);

        #if web
        FlxG.sound.play(Paths.sound("tick"), 0);   
        #end

        new FlxTimer().start(1.1, function(tmr:FlxTimer)
        {
            FlxG.sound.play(Paths.sound("splashSound"));   
        });

        super.create();
    }

    override function update(elapsed) 
    {
        
        if(splash.animation.curAnim.finished && splash.animation.curAnim.name == "start" && !cacheStart){
            
            #if web
            new FlxTimer().start(1.5, function(tmr:FlxTimer)
            {
                songsCached = true;
                charactersCached = true;
                graphicsCached = true;
            });
            #else
            preload(); 
            #end
            
            cacheStart = true;
        }
        if(splash.animation.curAnim.finished && splash.animation.curAnim.name == "end"){
            FlxG.switchState(nextState);  
        }

        if(songsCached && charactersCached && graphicsCached && splash.animation.curAnim.finished && !(splash.animation.curAnim.name == "end")){
            
            System.gc();
            splash.animation.play("end");
            splash.updateHitbox();
            splash.screenCenter();

            new FlxTimer().start(0.3, function(tmr:FlxTimer)
            {
                loadingText.text = "Done!";
            });
        }

        if(!cacheStart && FlxG.keys.justPressed.ANY){
            
           
            openPreloadSettings();

        }

        if(startCachingCharacters){
            if(charI >= characters.length){
                loadingText.text = "Characters cached...";
                startCachingCharacters = false;
                charactersCached = true;
            }
            else{
                ImageCache.add(Paths.file(characters[charI], "images", "png"));
                charI++;
            }
        }

        if(startCachingGraphics){
            if(gfxI >= graphics.length){
                loadingText.text = "Graphics cached...";
                startCachingGraphics = false;
                graphicsCached = true;
            }
            else{
                ImageCache.add(Paths.file(graphics[gfxI], "images", "png"));
                gfxI++;
            }
        }
        super.update(elapsed);
    }

    function preload(){

        loadingText.text = "Caching Assets...";
        
        if(!songsCached){ 
            #if target.threaded
            sys.thread.Thread.create(() -> {
                preloadMusic();
            });
            #else
            preloadMusic();
            #end
        }

        if(!charactersCached){
            startCachingCharacters = true;
        }

        if(!graphicsCached){
            startCachingGraphics = true;
        }

    }

    function preloadMusic(){
        for(x in songs){
            if(Assets.exists(Paths.inst(x))){
                FlxG.sound.cache(Paths.inst(x));
            }
            else{
                FlxG.sound.cache(Paths.music(x));
            }
        }
        loadingText.text = "Songs cached...";
        songsCached = true;
    }

    function preloadCharacters(){
        for(x in characters){
            ImageCache.add(Paths.file(x, "images", "png"));
            //trace("Chached " + x);
        }
        loadingText.text = "Characters cached...";
        charactersCached = true;
    }

    function preloadGraphics(){
        for(x in graphics){
            ImageCache.add(Paths.file(x, "images", "png"));
            //trace("Chached " + x);
        }
        loadingText.text = "Graphics cached...";
        graphicsCached = true;
    }

    function openPreloadSettings(){
        #if desktop
        CacheSettings.noFunMode = true;
        FlxG.switchState(new CacheSettings());
        CacheSettings.returnLoc = new Startup();
        #end
    }

}
