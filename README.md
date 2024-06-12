# zRay

In-development zig raytracing library

At the moment, this project is a zig implementation of [Ray Tracing in One Weekend](https://raytracing.github.io/books/RayTracingInOneWeekend.html)

![Demo Image](https://github.com/abelleisle/zray/blob/master/outputs/random_balls_1000.png?raw=true)

## Task List
* Find cleaner way to handle `Shape` runtime polymorphism. It feels dirty to allocate each shape just to allow for heap-allocated shapes to point to within the `Shape` struct.
  * Thinking about using a tagged union and within `init` point `intersection` to the child `intersection` function.
  * Regular tagged union dispatch might be a bit slower due to vtable child lookup.
* Try using `@Vector` types for `Vec3` to take advantage of SIMD operations.
* Render each frame one sample at a time to allow for live viewing during the render process.

## Benchmarks

To benchmark this software, I use the following camera settings with 16 bounces and 50 samples:
```zig
const cameraSettings = Camera.CameraSettings{
    .lookFrom         = Vec3f.init(13, 2, 3),
    .lookAt           = Vec3f.init(0, 0, 0),
    .imageWidth       = 800,
    .imageAspectRatio = 16.0 / 9.0,
    .vFOV             = 20.0,
    .upDirection      = Vec3f.init(0, 1, 0),
    .defocusAngle     = 0.6,
    .focusDistance    = 10.0,
};
```

The executable is built with `zig build -Doptimize=ReleaseFast`.

### Table

| State    | Commit                                   | Time (s) |
| -------- | ---------------------------------------- | -------- |
| Pre-SIMD | 7abaeb9c2e81cb1d5bae8623e3ac1327fa6ed96b | 56.135s  |
