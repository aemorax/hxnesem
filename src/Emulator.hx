package;

import h2d.TileGroup;
import h2d.Bitmap;
import hxd.PixelFormat;
import hxd.Pixels;
import h2d.Tile;
import model.Bus;

class Emulator extends hxd.App {
	public static var bus:Bus;
	public static var sp:Pixels;
	public static var bmp:Bitmap;
	public static var resTime:Float;

	override function init() {
		sp = new Pixels(256, 240, bus.ppu.screen, PixelFormat.RGBA, 0);
		bmp = new Bitmap(Tile.fromPixels(sp), s2d);
	}

	override function update(_) {
		if (resTime > 0) {
			resTime -= hxd.Timer.dt;
		} else {
			resTime += (1 / 60) - hxd.Timer.dt;
			do {
				bus.clock();
			} while (!bus.ppu.frameDone);
			bus.ppu.frameDone = false;
		}

		sp.bytes = bus.ppu.screen;
		bmp.tile = Tile.fromPixels(sp);
	}

	static function main() {
		bus = new Bus();
		new Emulator();
	}
}
