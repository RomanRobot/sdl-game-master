"""Defines an SDL_Error."""

from sys.ffi import DLHandle
from ._sdl import SDL_Fn

@value
@register_passable("trivial")
struct SDL_Error:
    """A wrapper around sdl errors."""

    var _get_error: SDL_Fn["SDL_GetError", fn () -> Ptr[CharC]]
    var _set_error: SDL_Fn["SDL_SetError", fn (Ptr[CharC]) -> IntC]
    var _clear_error: SDL_Fn["SDL_ClearError", fn () -> NoneType]

    @always_inline("nodebug")
    fn __init__(mut self, _handle: DLHandle):
        self._get_error = __type_of(self._get_error)(_handle)
        self._set_error = __type_of(self._set_error)(_handle)
        self._clear_error = __type_of(self._clear_error)(_handle)

    @always_inline("nodebug")
    fn __call__(self) -> Error:
        @parameter
        if error_level == 2:
            return String.write("SDL_Error: ", self._get_error.call())
        else:
            return "SDL_Error"

    @always_inline("nodebug")
    fn __call__(self, msg: StringLiteral) -> Error:
        @parameter
        if error_level == 2:
            return String.write("SDL_Error: ", msg, ", ", self._get_error.call())
        else:
            return String.write("SDL_Error: ", msg)

    @always_inline("nodebug")
    fn set_error(self, fmt: StringLiteral) raises:
        _ = self._set_error.call(fmt.unsafe_cstr_ptr().bitcast[CharC]())
        raise self(fmt)

    @always_inline("nodebug")
    fn clear_error(self):
        self._clear_error.call()

    @always_inline("nodebug")
    fn if_null(self, ptr: Ptr, msg: StringLiteral) raises -> __type_of(ptr):
        """Raises an error if the pointer is null."""
        if ptr:
            return ptr

        @parameter
        if error_level > 0:
            raise self(msg)

    @always_inline("nodebug")
    fn if_code(self, code: IntC, msg: StringLiteral) raises:
        """Raises an error if the error code is not zero."""

        @parameter
        if error_level > 0:
            if code != 0:
                raise self(msg)

    @always_inline("nodebug")
    fn if_false(self, bool: BoolC, msg: StringLiteral) raises -> __type_of(bool):
        """Raises an error if the bool is false."""
        if bool:
            return bool

        @parameter
        if error_level > 0:
            raise self(msg)
