# HTML5 Optimizations for SR Engine

This document details the optimizations implemented to improve the performance of SR Engine when running in web browsers.

## Client Preferences Optimizations
- Reduced default frame rate from 60 to 30 FPS for HTML5 builds
- Enabled low quality mode by default on HTML5
- Disabled note splashes by default to reduce rendering overhead
- Reduced maximum splash limit from 16 to 8 for HTML5
- Disabled anti-aliasing by default for better performance
- Disabled shaders by default to reduce GPU usage
- Reduced maximum notes limit to 800 for HTML5 builds
- Disabled character backgrounds and animations by default
- Simplified icon bounce animations on HTML5
- Limited animation frequency (every other beat) for better performance

## Project Configuration Optimizations
- Added HTML5-specific window dimensions (1024x600)
- Added HTML5 compilation flags for better performance:
  - `js-classic` for better compatibility
  - `js-es5` for compatibility with older browsers
  - `webgl-no-extensions` for broader compatibility
  - `js-maximum-gc-pressure` for better memory management

## Graphics and Animation Optimizations
- Removed anti-aliasing for HTML5 builds to reduce GPU usage
- Limited note splash spawning to 2 per frame on HTML5 (down from unlimited)
- Simplified icon bounce animations for better performance
- Reduced character animation frequency (every other beat instead of every beat)
- Reduced complexity of animation tweens on HTML5

## Memory Management Improvements
- Added soft memory limit of 100MB for HTML5 builds
- Added explicit garbage collection calls in destroy functions
- Reduced preloading of audio assets on HTML5 to save memory

## Audio Optimizations
- Reduced hitsound preloading on HTML5 builds
- Added minimum volume threshold (0.1) for hitsounds on HTML5
- Only play hitsounds when volume is above threshold to reduce processing

## Performance Recommendations
- For best performance, use modern browsers with WebGL support
- Enable hardware acceleration in browser settings
- Consider limiting screen size for better performance on lower-end devices
- The game will run better on devices with more RAM and faster CPUs

## Build Instructions
To build for HTML5, run: `lime build html5 -release`

The optimized game will be available in the `export/release/html5/bin` directory.

## Testing Results
These optimizations have resulted in:
- Improved frame rates on lower-end devices
- Reduced memory usage
- Better compatibility with various web browsers
- Faster loading times due to reduced asset preloading