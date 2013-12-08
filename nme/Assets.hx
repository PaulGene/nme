package nme;

import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.media.Sound;
import nme.net.URLRequest;
import nme.text.Font;
import nme.utils.ByteArray;
import nme.utils.WeakRef;

import nme.AssetInfo;


/**
 * <p>The Assets class provides a cross-platform interface to access 
 * embedded images, fonts, sounds and other resource files.</p>
 * 
 * <p>The contents are populated automatically when an application
 * is compiled using the NME command-line tools, based on the
 * contents of the *.nmml project file.</p>
 * 
 * <p>For most platforms, the assets are included in the same directory
 * or package as the application, and the paths are handled
 * automatically. For web content, the assets are preloaded before
 * the start of the rest of the application. You can customize the 
 * preloader by extending the <code>NMEPreloader</code> class,
 * and specifying a custom preloader using <window preloader="" />
 * in the project file.</p>
 */

class Assets 
{
   public static inline var UNCACHED = 0;
   public static inline var WEAK_CACHE = 1;
   public static inline var STRONG_CACHE = 2;

   public static var info = new Map<String,AssetInfo>();
   public static var useResources = false;
   public static var cacheMode:Int = WEAK_CACHE;

   //public static var id(get_id, null):Array<String>;

   public static function getAssetPath(inName:String) : String
   {
      var i = info.get(inName);
      return i==null ? null : i.path;
   }

   static function getResource(inName:String) : ByteArray
   {
      var bytes = haxe.Resource.getBytes(inName);
      if (bytes==null)
         trace("[nme.Assets] missing resource '" + inName + "'");
      if (bytes==null)
         return null;
      #if flash
      return bytes.getData();
      #else
      return ByteArray.fromBytes(bytes);
      #end
   }

   public static function trySetCache(info:AssetInfo, useCache:Null<Bool>, data:Dynamic)
   {
      if (useCache!=false && (useCache==true || cacheMode!=UNCACHED))
         info.setCache(data, cacheMode!=STRONG_CACHE);
   }

   public static function noId(id:String, type:String)
   {
      trace("[nme.Assets] missing resource '" + id + "' of type " + type);
   }

   public static function badType(id:String, type:String)
   {
      trace("[nme.Assets] resource '" + id + "' is not of type " + type);
   }

   public static function hasBitmapData(id:String):Bool 
   {
      var i = info.get(id);

      return i!=null && i.type==IMAGE;
   }

   /**
    * Gets an instance of an embedded bitmap
    * @usage      var bitmap = new Bitmap(Assets.getBitmapData("image.jpg"));
    * @param   id      The ID or asset path for the bitmap
    * @param   useCache      (Optional) Whether to use BitmapData from the cache(Default: according to setting)
    * @return      A new BItmapData object
    */
   public static function getBitmapData(id:String, ?useCache:Null<Bool>):BitmapData 
   {
      var i = info.get(id);
      if (i==null)
      {
         noId(id,"BitmapData");
         return null;
      }
      if (i.type!=IMAGE)
      {
         badType(id,"BitmapData");
         return null;
      }
      if (useCache!=false)
      {
         var val = i.getCache();
         if (val!=null)
            return val;
      }
 
      var data =
         #if flash
         cast(Type.createInstance(i.className, []), BitmapData)
         #elseif js
         cast(ApplicationMain.loaders.get(i.path).contentLoaderInfo.content, Bitmap).bitmapData
         #else
         useResources ? BitmapData.loadFromBytes( getResource(i.path) ) :  BitmapData.load(i.path)
         #end
      ;
      trySetCache(i,useCache,data);
      return data;
   }

   public static function hasBytes(id:String):Bool
   {
      var i = info.get(id);
      return i!=null;
   }


   /**
    * Gets an instance of an embedded binary asset
    * @usage      var bytes = Assets.getBytes("file.zip");
    * @param   id      The ID or asset path for the file
    * @return      A new ByteArray object
    */
   public static function getBytes(id:String,?useCache:Null<Bool>):ByteArray 
   {
      var i = info.get(id);
      if (i==null)
      {
         noId(id,"Bytes");
         return null;
      }
      if (useCache!=false)
      {
         var val = i.getCache();
         if (val!=null)
            return val;
      }


      #if flash
      var data = Type.createInstance(i.className, []);
      #elseif js
      var asset:Dynamic = ApplicationMain.urlLoaders.get(i.path).data;
      var data:ByteArray = null;
      if (Std.is(asset, String)) 
      {
         bytes = new ByteArray();
         bytes.writeUTFBytes(asset);
      }
      else if (!Std.is(data, ByteArray)) 
      {
         badType(is,"Bytes");
         return null;
      }
      #else
      var data = ByteArray.readFile(i.path);
      #end

      if (data != null) 
         data.position = 0;

      trySetCache(i,useCache,data);

      return data;
   }

   public static function hasFont(id:String):Bool 
   {
      var i = info.get(id);

      return i!=null && i.type == FONT;
   }
   /**
    * Gets an instance of an embedded font
    * @usage      var fontName = Assets.getFont("font.ttf").fontName;
    * @param   id      The ID or asset path for the font
    * @return      A new Font object
    */
   public static function getFont(id:String,?useCache:Null<Bool>):Font 
   {
      var i = info.get(id);
      if (i==null)
      {
         noId(id,"Font");
         return null;
      }
      if (i.type!=FONT)
      {
         badType(id,"Font");
         return null;
      }
      if (useCache!=false)
      {
         var val = i.getCache();
         if (val!=null)
            return val;
      }

      var font = 
         #if (flash || js)
         cast(Type.createInstance(i.className,[]), Font)
         #else
         new Font(i.path)
         #end
      ;

      trySetCache(i,useCache,font);

      return font;
   }

   public static function hasSound(id:String):Bool 
   {
      var i = info.get(id);

      return i!=null && (i.type == SOUND || i.type==MUSIC);
   }
 

   /**
    * Gets an instance of an embedded sound
    * @usage      var sound = Assets.getSound("sound.wav");
    * @param   id      The ID or asset path for the sound
    * @return      A new Sound object
    */
   public static function getSound(id:String,?useCache:Null<Bool>):Sound 
   {
      var i = info.get(id);
      if (i==null)
      {
         noId(id,"Sound");
         return null;
      }
      if (i.type != SOUND || i.type!=MUSIC)
      {
         badType(id,"Sound");
         return null;
      }
      if (useCache!=false)
      {
         var val = i.getCache();
         if (val!=null)
            return val;
      }

      var sound =
            #if flash
            cast(Type.createInstance(i.className, []), Sound)
            #elseif js
            new Sound(new URLRequest(i.path))
            #else
            new Sound(new URLRequest(i.path), null, i.type == MUSIC)
            #end
      ;

      trySetCache(i,useCache,sound);

      return sound;
   }

   public static function hasText(id:String) { return hasBytes(id); }

   /**
    * Gets an instance of an embedded text asset
    * @usage      var text = Assets.getText("text.txt");
    * @param   id      The ID or asset path for the file
    * @return      A new String object
    */
   public static function getText(id:String,?useCache:Null<Bool>):String 
   {
      var bytes = getBytes(id,useCache);

      if (bytes == null) 
         return null;

      return bytes.readUTFBytes(bytes.length);
   }


   // Getters & Setters
   /*
   private static function get_id():Array<String> 
   {
      initialize();

      var ids = [];

      for(key in AssetData.type.keys()) 
      {
         ids.push(key);
      }

      return ids;
   }
   */
}


