package gameObjects;

import gameObjects.animateatlas.AtlasFrameMaker;
import gameObjects.*;
import meta.data.*;
import meta.states.*;
import meta.states.substate.*;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.effects.FlxTrail;
import flixel.animation.FlxBaseAnimation;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import meta.data.Section.SwagSection;
#if MODS_ALLOWED
import sys.io.File;
import sys.FileSystem;
#end
import openfl.utils.AssetType;
import openfl.utils.Assets;
import haxe.Json;
import haxe.format.JsonParser;

using StringTools;

typedef CrowdAnim = {
	var time:Float;
	var data:Int;
	var length:Int;
}


class FNFSprite extends FlxSprite
{
	public static var DEFAULT_CHARACTER:String = 'bf'; //In case a character is missing, it will use BF on its place
	public var curCharacter:String = DEFAULT_CHARACTER;

	public var offsets:Map<String,Array<Float>>=[];
	public var holdTimer:Float = 0;
	public var stepsToHold:Float = 6.1; // dadVar
	public var canResetIdle:Bool = false;

	public var imageFile:String = '';
	public var jsonScale:Float = 1;
	public var noAntialiasing:Bool = false;
	public var originalFlipX:Bool = false;

	public var animationsArray:Array<Character.AnimArray> = [];

	public var positionArray:Array<Float> = [0, 0];

	override function update(elapsed:Float)
	{
		if(animation.curAnim != null)
		{
			if (animation.curAnim.name.startsWith('sing'))
				holdTimer += elapsed;
			else
				holdTimer=0;

			canResetIdle = (holdTimer >= Conductor.stepCrochet * 0.001 * stepsToHold) || holdTimer == 0 && !animation.curAnim.name.startsWith('sing') ;
		}
		super.update(elapsed);
	}


	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		animation.play(AnimName, Force, Reversed, Frame);

		var daOffset = offsets.get(AnimName);
		if (offsets.exists(AnimName))
		{
			offset.set(daOffset[0], daOffset[1]);
		}
		else
			offset.set(0, 0);

	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		offsets[name] = [x, y];
	}

	public function loadFromJson(character:String, ?mod:Bool = false){
		var json:Character.CharacterFile = getCharacterFile(character, mod);
		var spriteType = "sparrow";
		//sparrow
		//packer
		//texture
		#if MODS_ALLOWED
		var modTxtToFind:String = Paths.modsTxt(json.image);
		var txtToFind:String = Paths.getPath('images/' + json.image + '.txt', TEXT);

		//var modTextureToFind:String = Paths.modFolders("images/"+json.image);
		//var textureToFind:String = Paths.getPath('images/' + json.image, new AssetType();

		if (FileSystem.exists(modTxtToFind) || FileSystem.exists(txtToFind) || Assets.exists(txtToFind))
		#else
		if (Assets.exists(Paths.getPath('images/' + json.image + '.txt', TEXT)))
		#end
		{
			spriteType = "packer";
		}

		#if MODS_ALLOWED
		var modAnimToFind:String = Paths.modFolders('images/' + json.image + '/Animation.json');
		var animToFind:String = Paths.getPath('images/' + json.image + '/Animation.json', TEXT);

		//var modTextureToFind:String = Paths.modFolders("images/"+json.image);
		//var textureToFind:String = Paths.getPath('images/' + json.image, new AssetType();

		if (FileSystem.exists(modAnimToFind) || FileSystem.exists(animToFind) || Assets.exists(animToFind))
		#else
		if (Assets.exists(Paths.getPath('images/' + json.image + '/Animation.json', TEXT)))
		#end
		{
			spriteType = "texture";
		}

		switch (spriteType){

			case "packer":
				frames = Paths.getPackerAtlas(json.image);

			case "sparrow":
				frames = Paths.getSparrowAtlas(json.image);

			case "texture":
				frames = AtlasFrameMaker.construct(json.image);
		}
		imageFile = json.image;

		if(json.scale != 1) {
			jsonScale = json.scale;
			setGraphicSize(Std.int(width * jsonScale));
			updateHitbox();
		}

		flipX = !!json.flip_x;
		if(json.no_antialiasing) {
			antialiasing = false;
			noAntialiasing = true;
		}

		antialiasing = !noAntialiasing;
		if(!ClientPrefs.data.antialiasing) antialiasing = false;

		animationsArray = json.animations;
		if(animationsArray != null && animationsArray.length > 0) {
			for (anim in animationsArray) {
				var animAnim:String = '' + anim.anim;
				var animName:String = '' + anim.name;
				var animFps:Int = anim.fps;
				var animLoop:Bool = !!anim.loop; //Bruh
				var animIndices:Array<Int> = anim.indices;
				if(animIndices != null && animIndices.length > 0) {
					animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
				} else {
					animation.addByPrefix(animAnim, animName, animFps, animLoop);
				}

				if(anim.offsets != null && anim.offsets.length > 1) {
					addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
				}
			}
		}
	}

	public function getCharacterFile(character:String, ?mod:Bool = false){
		var characterPath:String = 'characters/' + character + '.json';
		var rawJson:Dynamic;
			var path:String = Paths.getPreloadPath(characterPath);
			if (!Assets.exists(path))
			{
				path = Paths.getPreloadPath('characters/' + DEFAULT_CHARACTER + '.json'); //If a character couldn't be found, change him to BF just to prevent a crash
			}

			rawJson = Assets.getText(path);
	  	return cast Json.parse(rawJson);
		}
}
