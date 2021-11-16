CreateWindowExA :: (dwExStyle : DWORD, lpClassName : *CHAR, lpWindowName : *CHAR, dwStyle : DWORD, x : INT, y : INT, nWidth : INT, nHeight : INT, hWndParent : HWND, hMenu : HMENU, hInstance : HINSTANCE, lpParam : *VOID) -> HWND #must #foreign user32;
CreateWindowExW :: (dwExStyle : DWORD, lpClassName : *WCHAR, lpWindowName : *WCHAR, dwStyle : DWORD, x : INT, y : INT, nWidth : INT, nHeight : INT, hWndParent : HWND, hMenu : HMENU, hInstance : HINSTANCE, lpParam : *VOID) -> HWND #must #foreign user32;
DestroyWindow :: (hWnd : HWND) -> BOOL #foreign user32;
EnableWindow :: (hWnd : HWND, bEnable : BOOL) -> BOOL #foreign user32;
ShowWindow :: (hWnd : HWND, nCmdShow : INT) -> BOOL #foreign user32;
SetWindowLongPtrW :: (hWnd : HWND, nIndex : INT, dwNewLong : *LONG) -> *LONG #foreign user32;
GetWindowLongPtrW :: (hWnd : HWND, nIndex : INT) -> *LONG #foreign user32;
GetDC :: (hWnd : HWND) -> HDC #foreign user32;
ReleaseDC :: (hWnd : HWND, hDC : HDC) -> INT #foreign user32;
ChoosePixelFormat :: (hdc : HDC, ppfd : *PIXELFORMATDESCRIPTOR) -> INT #foreign gdi32;
SetPixelFormat :: (hdc : HDC, format : INT, ppfd : *PIXELFORMATDESCRIPTOR) -> BOOL #foreign gdi32;
PeekMessageA :: (lpMsg : *MSG, hWnd : HWND, wMsgFilterMin : UINT, wMsgFilterMax : UINT, wRemoveMsg : UINT) -> BOOL #foreign user32;
PeekMessageW :: (lpMsg : *MSG, hWnd : HWND, wMsgFilterMin : UINT, wMsgFilterMax : UINT, wRemoveMsg : UINT) -> BOOL #foreign user32;
GetMessageA :: (lpMsg : *MSG, hWnd : HWND, wMsgFilterMin : UINT, wMsgFilterMax : UINT) -> BOOL #foreign user32;
GetMessageW :: (lpMsg : *MSG, hWnd : HWND, wMsgFilterMin : UINT, wMsgFilterMax : UINT) -> BOOL #foreign user32;
TranslateMessage :: (lpMsg : *MSG) -> BOOL #foreign user32;
DispatchMessageA :: (lpMsg : *MSG) -> BOOL #foreign user32;
DispatchMessageW :: (lpMsg : *MSG) -> BOOL #foreign user32;
SwapBuffers :: (hdc : HDC) -> BOOL #foreign gdi32;
GetWindowRect :: (hWnd : HWND, lpRect : *RECT) -> BOOL #foreign user32;
GetClientRect :: (hWnd : HWND, lpRect : *RECT) -> BOOL #foreign user32;

// ShowWindow, nCmdShow
SW_HIDE            : INT : 0;
SW_SHOWNORMAL      : INT : 1;
SW_SHOWMINIMIZED   : INT : 2;
SW_MAXIMIZE        : INT : 3;
SW_SHOWMAXIMIZED   : INT : 3;
SW_SHOWNOACTIVATE  : INT : 4;
SW_SHOW            : INT : 5;
SW_MINIMIZE        : INT : 6;
SW_SHOWMINNOACTIVE : INT : 7;
SW_SHOWNA          : INT : 8;
SW_RESTORE         : INT : 9;
SW_SHOWDEFAULT     : INT : 10;
SW_FORCEMINIMIZE   : INT : 11;

// SetWindowLongPtrW, GetWindowLongPtrW
GWLP_USERDATA  : INT : -21;
GWL_EXSTYLE    : INT : -20;
GWL_STYLE      : INT : -16;
GWLP_ID        : INT : -12;
GWLP_HINSTANCE : INT : -6;
GWLP_WNDPROC   : INT : -4;

// Window class styles
// Window styles

PIXELFORMATDESCRIPTOR :: struct
{
	nSize           : WORD;
	nVersion        : WORD;
	dwFlags         : DWORD;
	iPixelType      : BYTE;
	cColorBits      : BYTE;
	cRedBits        : BYTE;
	cRedShift       : BYTE;
	cGreenBits      : BYTE;
	cGreenShift     : BYTE;
	cBlueBits       : BYTE;
	cBlueShift      : BYTE;
	cAlphaBits      : BYTE;
	cAlphaShift     : BYTE;
	cAccumBits      : BYTE;
	cAccumRedBits   : BYTE;
	cAccumGreenBits : BYTE;
	cAccumBlueBits  : BYTE;
	cAccumAlphaBits : BYTE;
	cDepthBits      : BYTE;
	cStencilBits    : BYTE;
	cAuxBuffers     : BYTE;
	iLayerType      : BYTE;
	bReserved       : BYTE;
	dwLayerMask     : DWORD;
	dwVisibleMask   : DWORD;
	dwDamageMask    : DWORD;
}

MSG :: struct
{
	hwnd     : HWND;
	message  : UINT;
	wParam   : WPARAM;
	lParam   : LPARAM;
	time     : DWORD;
	pt       : POINT;
	lPrivate : DWORD;
}

// Clipboard
OpenClipboard :: (hWndNewOwner : HWND) -> BOOL #foreign user32;
CloseClipboard :: () -> BOOL #foreign user32;
EmptyClipboard :: () -> BOOL #foreign user32;
GetClipboardData :: (uFormat : UINT) -> HANDLE #foreign user32;
SetClipboardData :: (uFormat : UINT, hMem : HANDLE) -> HANDLE #foreign user32;

CF_BITMAP          : UINT : 2;
CF_DIB             : UINT : 8;
CF_DIBVS           : UINT : 17;
CF_DIF             : UINT : 5;
CF_DSPBITMAP       : UINT : 0x0082;
CF_DSPENHMETAFILE  : UINT : 0x008e;
CF_DSPMETAFILEPICT : UINT : 0x0083;
CF_DSPTEXT         : UINT : 0x0081;
CF_ENHMETAFILE     : UINT : 14;
CF_GDIOBJFIRST     : UINT : 0x0300;
CF_GDIOBJLAST      : UINT : 0x03ff;
CF_HDROP           : UINT : 15;
CF_LOCALE          : UINT : 16;
CF_METAFILEPICT    : UINT : 3;
CF_OEMTEXT         : UINT : 7;
CF_OWNERDISPLAY    : UINT : 0x0080;
CF_PALETTE         : UINT : 9;
CF_PENDATA         : UINT : 10;
CF_PRIVATEFIRST    : UINT : 0x0200;
CF_PRIVATELAST     : UINT : 0x02ff;
CF_RIFF            : UINT : 11;
CF_SYLK            : UINT : 4;
CF_TEXT            : UINT : 1;
CF_TIFF            : UINT : 6;
CF_UNICODETEXT     : UINT : 13;
CF_WAVE            : UINT : 12;

#scope_file

user32 :: #foreign_system_library "user32";
gdi32  :: #foreign_system_library "gdi32";
