# zRay

In-development zig raytracing library

At the moment, this project is a zig implementation of [Ray Tracing in One Weekend](https://raytracing.github.io/books/RayTracingInOneWeekend.html)

## Task List
* Find cleaner way to handle `Shape` runtime polymorphism. It feels dirty to allocate each shape just to allow for heap-allocated shapes to point to within the `Shape` struct.
  * Thinking about using a tagged union and within `init` point `intersection` to the child `intersection` function.
  * Regular tagged union dispatch might be a bit slower due to vtable child lookup.
* Try using `@Vector` types for `Vec3` to take advantage of SIMD operations.
* Render each frame one sample at a time to allow for live viewing during the render process.
