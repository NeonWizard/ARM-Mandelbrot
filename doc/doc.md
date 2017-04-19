Bringing it all together
========================

Make these changes:

*   `run` should call `setupSubpixel` at some point before calling
    `calcPixel` for the first time.

*   Add the `antialias` parameter to all calls to `calcPixel`.

That is it! You have now create complete Mandelbrot images.

After passing this off, try experimenting with new color palettes
and try finding new and interesting regions to explore and render on
the Mandelbrot plane. If you create a cool image, send me a copy of
your `params.s` and `palette.s` files.
