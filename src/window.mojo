"""Defines an SDL Window."""

from collections import Optional, InlineArray
from ._sdl import _SDL

alias windowpos_undefined_mask = 0x1FFF0000
alias windowpos_centered_mask = 0x2FFF0000
alias WINDOWPOS_UNDEFINED = windowpos_undefined_display(0)
alias WINDOWPOS_CENTERED = windowpos_centered_display(0)


@always_inline
fn windowpos_undefined_display(x: Int32) -> Int32:
    return windowpos_undefined_mask | (x & 0xFFFF)


@always_inline
fn windowpos_centered_display(x: Int32) -> Int32:
    return windowpos_centered_mask | (x & 0xFFFF)


struct Window[lif: ImmutableOrigin]:
    """A higher level wrapper around an SDL_Window."""

    var sdl: Pointer[SDL, lif]
    var _window_ptr: Ptr[_Window]

    fn __init__(
        mut self,
        ref [lif]sdl: SDL,
        name: String,
        width: Int32,
        height: Int32,
        xpos: Optional[Int32] = None,
        ypos: Optional[Int32] = None,
        xcenter: Bool = False,
        ycenter: Bool = False,
        fullscreen: Bool = False,
        opengl: Bool = False,
        shown: Bool = False,
        hidden: Bool = False,
        borderless: Bool = False,
        resizable: Bool = False,
        minimized: Bool = False,
        maximized: Bool = False,
        input_grabbed: Bool = False,
        allow_highdpi: Bool = False,
    ) raises:
        # set sdl
        self.sdl = Pointer.address_of(sdl)

        # calculate window position
        if xpos and xcenter:
            raise Error("Expected only one of `xpos` or `xcenter` but got both")
        if ypos and ycenter:
            raise Error("Expected only one of `ypos` or `ycenter` but got both")
        var x = xpos.or_else(WINDOWPOS_CENTERED if xcenter else WINDOWPOS_UNDEFINED)
        var y = ypos.or_else(WINDOWPOS_CENTERED if ycenter else WINDOWPOS_UNDEFINED)

        # set window flags
        var flags: UInt32 = 0
        flags |= WindowFlags.FULLSCREEN * fullscreen
        flags |= WindowFlags.OPENGL * opengl
        flags |= WindowFlags.SHOWN * shown
        flags |= WindowFlags.HIDDEN * hidden
        flags |= WindowFlags.BORDERLESS * borderless
        flags |= WindowFlags.RESIZABLE * resizable
        flags |= WindowFlags.MINIMIZED * minimized
        flags |= WindowFlags.MAXIMIZED * maximized
        flags |= WindowFlags.INPUT_GRABBED * input_grabbed
        flags |= WindowFlags.ALLOW_HIGHDPI * allow_highdpi

        self._window_ptr = self.sdl[]._sdl.create_window(
            name.unsafe_cstr_ptr().bitcast[CharC](),
            x,
            y,
            width,
            height,
            flags,
        )

    fn __init__(mut self, ref [lif]sdl: SDL, _window_ptr: Ptr[_Window] = Ptr[_Window]()):
        self.sdl = Pointer.address_of(sdl)
        self._window_ptr = _window_ptr

    fn __moveinit__(mut self, owned other: Self):
        self.sdl = other.sdl
        self._window_ptr = other._window_ptr

    fn __del__(owned self):
        self.sdl[]._sdl.destroy_window(self._window_ptr)

    fn set_fullscreen(mut self, flags: UInt32) raises:
        self.sdl[]._sdl.set_window_fullscreen(self._window_ptr, flags)

    fn get_surface(mut self) raises -> Surface[lif]:
        var surface = Surface(self.sdl[], self.sdl[]._sdl.get_window_surface(self._window_ptr))
        surface._surface_ptr[].refcount += 1
        return surface^
    
    fn get_native_window(self) raises -> UnsafePointer[_NSWindow]:
        var wm_info = _SysWMinfo()
        self.sdl[]._sdl.get_window_info(self._window_ptr, UnsafePointer[_SysWMinfo].address_of(wm_info))
        # TODO: Handle other platforms
        return wm_info.cocoa_window

    fn update_surface(self) raises:
        self.sdl[]._sdl.update_window_surface(self._window_ptr)

    fn destroy_surface(mut self) raises:
        self.sdl[]._sdl.destroy_window_surface(self._window_ptr)


@register_passable("trivial")
struct _Window:
    """The opaque type used to identify a window."""

    pass

struct WindowFlags:
    """Window Flags."""

    alias FULLSCREEN = 0x00000001
    """Fullscreen window."""

    alias OPENGL = 0x00000002
    """Window usable with OpenGL context."""
    alias SHOWN = 0x00000004
    """Window is visible."""
    alias HIDDEN = 0x00000008
    """Window is not visible."""
    alias BORDERLESS = 0x00000010
    """No window decoration."""
    alias RESIZABLE = 0x00000020
    """Window can be resized."""
    alias MINIMIZED = 0x00000040
    """Window is minimized."""
    alias MAXIMIZED = 0x00000080
    """Window is maximized."""
    alias MOUSE_GRABBED = 0x00000100
    """Window has grabbed mouse input."""
    alias INPUT_FOCUS = 0x00000200
    """Window has input focus."""
    alias MOUSE_FOCUS = 0x00000400
    """Window has mouse focus."""
    alias FULLSCREEN_DESKTOP = (Self.FULLSCREEN | 0x00001000)
    """Fullscreen desktop window."""
    alias FOREIGN = 0x00000800
    """Window not created by SDL."""
    alias ALLOW_HIGHDPI = 0x00002000
    """Window should be created in high-DPI mode if supported.
    On macOS NSHighResolutionCapable must be set true in the application's Info.plist for this to have any effect."""
    alias MOUSE_CAPTURE = 0x00004000
    """Window has mouse captured (unrelated to MOUSE_GRABBED)."""
    alias ALWAYS_ON_TOP = 0x00008000
    """Window should always be above others."""
    alias SKIP_TASKBAR = 0x00010000
    """Window should not be added to the taskbar."""
    alias UTILITY = 0x00020000
    """Window should be treated as a utility window."""
    alias TOOLTIP = 0x00040000
    """Window should be treated as a tooltip."""
    alias POPUP_MENU = 0x00080000
    """Window should be treated as a popup menu."""
    alias KEYBOARD_GRABBED = 0x00100000
    """Window has grabbed keyboard input."""
    alias VULKAN = 0x10000000
    """Window usable for Vulkan surface."""
    alias METAL = 0x20000000
    """Window usable for Metal view."""

    alias INPUT_GRABBED = Self.MOUSE_GRABBED
    """Equivalent to SDL_WINDOW_MOUSE_GRABBED for compatibility."""


struct DisplayMode:
    """The structure that defines a display mode."""

    var format: UInt32
    """Pixel format."""
    var w: IntC
    """Width, in screen coordinates."""
    var h: IntC
    """Height, in screen coordinates."""
    var refresh_rate: IntC
    """Refresh rate (or zero for unspecified)."""
    var driverdata: Ptr[NoneType]
    """Driver-specific data, initialize to 0."""


struct FlashOperation:
    """Window flash operation."""

    alias FLASH_CANCEL: IntC = 0
    """Cancel any window flash state."""
    alias FLASH_BRIEFLY: IntC = 1
    """Flash the window briefly to get attention."""
    alias SDL_FLASH_UNTIL_FOCUSED: IntC = 2
    """Flash the window until it gets focus."""


@register_passable("trivial")
struct _GLContext:
    pass

struct SDL_version:
    """Information about the version of SDL in use."""

    var major: UInt8
    var minor: UInt8
    var patch: UInt8

    fn __init__(out self):
        self.major = 2
        self.minor = 30
        self.patch = 10

struct SDL_SYSWM_TYPE:
    """These are the various supported windowing subsystems"""

    var value: UInt32

    fn __init__(out self, value: UInt32):
        self.value = value

    alias SDL_SYSWM_UNKNOWN = Self(0)
    alias SDL_SYSWM_WINDOWS = Self(1)
    alias SDL_SYSWM_X11 = Self(2)
    alias SDL_SYSWM_DIRECTFB = Self(3)
    alias SDL_SYSWM_COCOA = Self(4)
    alias SDL_SYSWM_UIKIT = Self(5)
    alias SDL_SYSWM_WAYLAND = Self(6)
    alias SDL_SYSWM_MIR = Self(7) # no longer available, left for API/ABI compatibility. Remove in 2.1!
    alias SDL_SYSWM_WINRT = Self(8)
    alias SDL_SYSWM_ANDROID = Self(9)
    alias SDL_SYSWM_VIVANTE = Self(10)
    alias SDL_SYSWM_OS2 = Self(11)
    alias SDL_SYSWM_HAIKU = Self(12)
    alias SDL_SYSWM_KMSDRM = Self(13)
    alias SDL_SYSWM_RISCOS = Self(14)

struct _SysWMinfo:
    """The custom window manager information structure."""

    var version: SDL_version
    var subsystem: SDL_SYSWM_TYPE
    var cocoa_window: Ptr[_NSWindow]
    var dummy: InlineArray[UInt8, 43]

    fn __init__(out self):
        self.version = SDL_version()
        self.subsystem = SDL_SYSWM_TYPE.SDL_SYSWM_UNKNOWN
        self.cocoa_window = Ptr[_NSWindow]()
        self.dummy = InlineArray[UInt8, 43](0)


struct _NSWindow:
    pass
