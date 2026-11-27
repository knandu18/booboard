# third_party

## stable-diffusion.cpp (offline image engine)

Git submodule `third_party/stable-diffusion.cpp`, upstream `https://github.com/leejet/stable-diffusion.cpp` (MIT).
Built into the app as `libbooboard_images.so` by `android/app/src/main/cpp/CMakeLists.txt` (arm64-v8a and x86_64
only). The library has no network code; the app must never gain the INTERNET permission.

**Pinned:** tag `master-1133-52491bd`, commit `52491bd`. Its nested `ggml` submodule is pinned at `eeda9ec`.
Only `ggml` is needed; do not initialise the others (frontend, cutlass, libwebm, libwebp).

Fresh checkout:

    git submodule update --init third_party/stable-diffusion.cpp
    git -C third_party/stable-diffusion.cpp submodule update --init ggml

The submodule is marked `ignore = dirty` in `.gitmodules` because the build patches its working tree.

### Patch: `patches/sdcpp-host-headroom.patch`

`ModelManager::ensure_host_capacity` keeps 1 GB of free RAM spare before loading weights. That is fine on a desktop
but too much on a phone: on a 4 GB device the 1.7 GB model failed with "RAM weight capacity exceeded"; with the
margin at 256 MB it ran (about 1.5 GB free is needed). The patch changes that one constant to 256 MB.

CMake applies it at configure time, idempotently: `git apply --check --reverse` says it is already applied, else
`git apply --check` then `git apply`; if neither works (for example the submodule is at another commit) the
configure step fails with a message.

### Updating the engine

1. Check out the new tag in the submodule (`git -C third_party/stable-diffusion.cpp fetch --tags`, `git checkout
   <tag>`), then check out the commit its `ggml` entry points to (`git -C third_party/stable-diffusion.cpp
   submodule update --init ggml`). Commit the new submodule pointer.
2. Reset the working tree change first (`git -C third_party/stable-diffusion.cpp checkout -- .`), so the patch is
   tested on a clean tree.
3. Check the patch: `git -C third_party/stable-diffusion.cpp apply --check ../patches/sdcpp-host-headroom.patch`.
   If the code moved, redo the one-line change and regenerate the patch with `git diff` (keep the explanation lines
   at its top).
4. The C API changes between releases (this one is key based: `sd_ctx_create`, `sd_opt_set_*`,
   `sd_generate_image`). Re-read `include/stable-diffusion.h` and update `booboard_images_jni.cpp`.
5. Build both ABIs in release mode and repeat the network-symbol check on `libbooboard_images.so` (no socket,
   connect, getaddrinfo, SSL, curl, http). Update the version in `docs/waves/images.md` and
   `THIRD_PARTY_NOTICES.md`.
