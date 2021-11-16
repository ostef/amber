#scope_module

#import "Basic";  // I think we only need this dependency because of alloc ... sigh!
File :: #import "File";
#import "Windows";
#import "Windows_Registry";
#import "Windows_Utf8";
#import "File_Utilities";
#import "String";

#scope_export

//
// We want to make it so that the user doesn't have to think about resource IDs unless they want to.
// by default, we make the Manifest be resource ID 1; the icons start at 2.
// If we want to expand this to allow embedding arbitrary user data in some way (which we probably do!),
// then maybe we should designate some relatively high number, like 20 for those to begin by default.
//


set_icon_by_filename :: (exe_filename: string, icon_filename: string, resource_id : s32 = RESOURCE_ID_FIRST_ICON, delete_existing_resources := false) -> bool {
    icon_data, success := File.read_entire_file(icon_filename, context.allocator);
    if !icon_data {
        log_error("Unable to read icon file '%'.\n", icon_filename);
        return false;
    }

    defer free(icon_data);
    return set_icon_by_data(exe_filename, icon_data, resource_id, delete_existing_resources);
}

set_icon_by_data :: (exe_filename: string, icon_data: string, resource_id : s32 = RESOURCE_ID_FIRST_ICON, delete_existing_resources := false) -> bool {
    utf16_exe_filename := utf8_to_wide(exe_filename);
    
    file_handle := BeginUpdateResourceW(utf16_exe_filename, cast(BOOL) delete_existing_resources);
    if !file_handle
	{
		log_error ("BeginUpdateResourceW failed.");
		return false;  // Log this?
	}

    // @Incomplete: Assert that we are little-endian, or byteswap the struct.
    
    icondir := cast (*ICONDIR) icon_data.data;

    //
    // This is all just Windows ridiculousness. In principle we just want to paste the data from 'icon_data'
    // into the exe file. In practice, we have to process it because the source file has struct ICONDIRENTRY
    // and the dest file has struct MEMICONDIRENTRY. The only difference between ICONDIRENTRY and MEMICONDIRENTRY
    // is that the latter is 2 bytes smaller because things are referenced by resource ID instead of file offset.
    // This is all just ridiculous busywork.
    //

    // For now, punting on whether we care about the lang_id...
    // However, I did try LANG_NEUTRAL and when I do so, the icon is not used by Windows Explorer!
    // You would think that this means "use this in every language", but no! I have no idea what is going on.
    //
    //         -jblow, 24 January 2018.
    //
    lang_id := MAKELANGID(LANG_ENGLISH, SUBLANG_DEFAULT);
    
    RT_ICON       := cast(*u8) 3;  // Hmm ... right now we do not have a way to have this be a constant? 
    RT_GROUP_ICON := cast(*u8) 14;  // Hmm ... right now we do not have a way to have this be a constant?

    entries_size := size_of(MEMICONDIRENTRY) * icondir.ImageCount;
    memicondir_bytes := size_of(MEMICONDIR) + entries_size;
    memicondir : *MEMICONDIR = alloc(memicondir_bytes);
    defer free(memicondir);

    memset(memicondir, 0, memicondir_bytes);
    
    entries : *MEMICONDIRENTRY = xx(cast(*u8)memicondir + size_of(MEMICONDIR));
    entries_u8 := cast(*u8) entries;
    
    memicondir.ResourceType = 1;
    memicondir.ImageCount = icondir.ImageCount;

    cursor := icon_data.data + 6;
    for 0..icondir.ImageCount-1 {
        src_entry := cast(*ICONDIRENTRY) cursor;
        cursor += 16;

        // This multiplication hack is here because the struct comes out to alignment 16,
        // but the file expect these to be packed at alignment 1. We don't have a way right
        // now to specify alignment on the struct declaration (and it's not clear that's the
        // best way to do it anyway), so just do it manually here.
        dest_entry := cast(*MEMICONDIRENTRY) (entries_u8 + 14 * it);
        
        dest_entry.Width        = src_entry.Width;
        dest_entry.Height       = src_entry.Height;
        dest_entry.Colors       = src_entry.Colors;
        dest_entry.Reserved2    = src_entry.Reserved2;
        dest_entry.Planes       = src_entry.Planes;
        dest_entry.BitsPerPixel = src_entry.BitsPerPixel;
        dest_entry.ImageSize    = src_entry.dwBytesInResource;
        dest_entry.nID          = cast(u16)(resource_id + xx it);
        //print("\nIcon ID = %\n%\n", dest_entry.nID, <<dest_entry);
        update_success := UpdateResourceW(file_handle, RT_ICON, MAKEINTRESOURCE(dest_entry.nID), lang_id, icon_data.data + src_entry.dwImageOffset, dest_entry.ImageSize);
        //print ("%, %.\n", <<src_entry, <<dest_entry);
		if !update_success
		{
			log_error ("UpdateResourceW failed for image % (size was %x%, bits per px was %).",
				it, src_entry.Width, src_entry.Height, src_entry.BitsPerPixel);

			return false;
		}
	}
    
    update_success := UpdateResourceW(file_handle, RT_GROUP_ICON, MAKEINTRESOURCE(resource_id), lang_id, memicondir, xx(6 + entries_size));
    if !update_success
	{
		log_error ("UpdateResourceW failed.");
		return false;  // Log this?
	}

    success := EndUpdateResourceW(file_handle, 0);
    return cast(bool) success;
}

Manifest_Options :: struct {
    dpi_aware := true;
}

generate_manifest :: (options: Manifest_Options) -> string {  // Returns alloced string.
    dpi_aware_string: string;
    if options.dpi_aware {
        dpi_aware_string = DPI_AWARE_TRUE;
    } else {
        dpi_aware_string = DPI_AWARE_FALSE;
    }
    
    return sprint(MANIFEST_TEMPLATE, dpi_aware_string);
}

add_manifest_to_executable :: (exe_filename: string, options: Manifest_Options, resource_id: s32 = RESOURCE_ID_MANIFEST) -> bool {
    manifest := generate_manifest(options);
    if !manifest  return false;
    defer free(manifest);
    
    utf16_exe_filename := utf8_to_wide(exe_filename);
    file_handle := BeginUpdateResourceW(utf16_exe_filename, 0);
    if !file_handle return false;  // Log this?

    lang_id := MAKELANGID(LANG_ENGLISH, SUBLANG_DEFAULT);
    RT_MANIFEST := cast(*u8) 24;
    
    update_success := UpdateResourceW(file_handle, RT_MANIFEST, MAKEINTRESOURCE(resource_id), lang_id, manifest.data, xx manifest.count);
    if !update_success return false;
    
    success := EndUpdateResourceW(file_handle, 0);
    return cast(bool) success;
}

// BITMAPINFOHEADER and ICONDIRENTRY are needed
// by Ico_File.jai, so we do not make them private here.


ICONDIRENTRY :: struct {
    Width: u8;             // icon width. A value of 0 is interpreted as 256
    Height: u8;            // icon height. A value of 0 is interpreted as 256
    Colors: u8;            // colors (0 means more than 8 bits per pixel)
    Reserved2: u8;         // reserved, must be 0
    Planes: WORD;          // color planes
    BitsPerPixel: WORD;    // bit depth
    dwBytesInResource: DWORD; 
    dwImageOffset: DWORD;  // offset in bytes from the start of the file.
}

ICONDIR :: struct {
    Reserved1: WORD;       // reserved, must be 0
    ResourceType: WORD;    // type is 1 for icons
    ImageCount: WORD;      // number of icons in structure (1)
    // Entries: [0] ICONDIRENTRY;

    // @Compiler: If we make #no_abc work on array declarations, then we can just
    // let Entries live in the struct and dereference it normally.
}


#scope_file


RESOURCE_ID_MANIFEST   :: 1;
RESOURCE_ID_FIRST_ICON :: 2;


MEMICONDIR :: struct {
    Reserved1: WORD;       // reserved, must be 0
    ResourceType: WORD;    // type is 1 for icons
    ImageCount: WORD;      // number of icons in structure (1)
    // Entries: [0] MEMICONDIRENTRY;

    // @Compiler: If we make #no_abc work on array declarations, then we can just
    // let Entries live in the struct and dereference it normally.
}

MEMICONDIRENTRY :: struct {
    Width: u8;             // icon width
    Height: u8;            // icon height
    Colors: u8;            // colors (0 means more than 8 bits per pixel)
    Reserved2: u8;         // reserved, must be 0
    Planes: WORD;          // color planes
    BitsPerPixel: WORD;    // bit depth
    ImageSize: DWORD;      // size of structure
    nID: WORD;             // The ID.
}

MAKEINTRESOURCE :: (x: s32) -> *u16 {
    return cast(*u16) x;  // Sigh.
}

kernel32 :: #foreign_system_library "kernel32";

WORD  :: u16;
LONG  :: s32;

BeginUpdateResourceW :: (pFileName: *u16, bDeleteExistingResources: BOOL) -> HANDLE #foreign kernel32;
UpdateResourceW      :: (hUpdate: HANDLE, lpType: *u8, lpName: *u16, wLanguage: WORD, lpData: *void, cbData: DWORD) -> BOOL #foreign kernel32;
EndUpdateResourceW   :: (hUpdate: HANDLE, fDiscard: BOOL) -> BOOL #foreign kernel32;


MANIFEST_TEMPLATE :: #string DONE
<?xml version="1.0" encoding="utf-8"?>
<asmv1:assembly manifestVersion="1.0" xmlns="urn:schemas-microsoft-com:asm.v1" xmlns:asmv1="urn:schemas-microsoft-com:asm.v1" xmlns:asmv2="urn:schemas-microsoft-com:asm.v2" xmlns:asmv3="urn:schemas-microsoft-com:asm.v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <trustInfo xmlns="urn:schemas-microsoft-com:asm.v2">
    <security>
      <requestedPrivileges xmlns="urn:schemas-microsoft-com:asm.v3">
        <requestedExecutionLevel level="asInvoker" uiAccess="false" />
      </requestedPrivileges>
    </security>
  </trustInfo>
  <asmv3:application>
    <asmv3:windowsSettings>
%
    </asmv3:windowsSettings>
  </asmv3:application>
  <ms_compatibility:compatibility xmlns:ms_compatibility="urn:schemas-microsoft-com:compatibility.v1" xmlns="urn:schemas-microsoft-com:compatibility.v1">
    <ms_compatibility:application xmlns:ms_compatibility="urn:schemas-microsoft-com:compatibility.v1">
      <ms_compatibility:supportedOS xmlns:ms_compatibility="urn:schemas-microsoft-com:compatibility.v1" Id="{8e0f7a12-bfb3-4fe8-b9a5-48fd50a15a9a}"></ms_compatibility:supportedOS>
      <ms_compatibility:supportedOS xmlns:ms_compatibility="urn:schemas-microsoft-com:compatibility.v1" Id="{1f676c76-80e1-4239-95bb-83d0f6d0da78}"></ms_compatibility:supportedOS>
      <ms_compatibility:supportedOS xmlns:ms_compatibility="urn:schemas-microsoft-com:compatibility.v1" Id="{4a2f28e3-53b9-4441-ba9c-d69d4a4a6e38}"></ms_compatibility:supportedOS>
      <ms_compatibility:supportedOS xmlns:ms_compatibility="urn:schemas-microsoft-com:compatibility.v1" Id="{35138b9a-5d96-4fbd-8e2d-a2440225f93a}"></ms_compatibility:supportedOS>
      <ms_compatibility:supportedOS xmlns:ms_compatibility="urn:schemas-microsoft-com:compatibility.v1" Id="{e2011457-1546-43c5-a5fe-008deee3d3f0}"></ms_compatibility:supportedOS>
    </ms_compatibility:application>
  </ms_compatibility:compatibility>
</asmv1:assembly>
DONE

DPI_AWARE_TRUE :: #string DONE
        <dpiAware xmlns="http://schemas.microsoft.com/SMI/2005/WindowsSettings">true/pm</dpiAware> <!-- legacy -->
        <dpiAwareness xmlns="http://schemas.microsoft.com/SMI/2016/WindowsSettings">permonitorv2,permonitor</dpiAwareness> <!-- falls back to pm if pmv2 is not available -->
DONE

DPI_AWARE_FALSE :: #string DONE
        <dpiAware xmlns="http://schemas.microsoft.com/SMI/2005/WindowsSettings">unaware</dpiAware>
DONE



//
// How to find the Windows Kits folder so you can link against it:
//

#scope_export

find_windows_kit_root :: (version: string) -> string {
    key: HKEY;

    rc := RegOpenKeyExA(HKEY_LOCAL_MACHINE, "SOFTWARE\\Microsoft\\Windows Kits\\Installed Roots",
                        0, KEY_QUERY_VALUE | KEY_WOW64_32KEY | KEY_ENUMERATE_SUB_KEYS, *key);
    if rc != 0  return "";

    
    buf: [BUFFER_LENGTH] u16;
    length : u32 = BUFFER_LENGTH;
    rc = RegQueryValueExW(key, utf8_to_wide(version), null, null, xx buf.data, *length);  // We know that version is zero-terminated...
    RegCloseKey(key);
    if rc != 0  return "";

    // The documentation says that if the string for some reason was not stored
    // with zero-termination, we need to manually terminate it. Sigh!!

    if buf[length] {
        buf[length+1] = 0;
    }
    
    return wide_to_utf8(buf.data);
}

find_windows_kit_root :: () -> (root: string, windows_version: s32) {
    windows10_root := find_windows_kit_root("KitsRoot10");

    if windows10_root {
        Win10_Data :: struct {
            best_version: [4] s32;
            best_name:     string;
        }

        win10_best :: (info: *File_Visit_Info, data: *Win10_Data) {
            // For now, the most recent wins.
            success, anys := scan("%i.%i.%i.%i", info.short_name);
            if !success return;

            i0 := << cast(*int) anys[0].value_pointer;
            i1 := << cast(*int) anys[1].value_pointer;
            i2 := << cast(*int) anys[2].value_pointer;
            i3 := << cast(*int) anys[3].value_pointer;

            if i0 < data.best_version[0] return;
            else if i0 == data.best_version[0] {
                if i1 < data.best_version[1] return;
                else if i1 == data.best_version[1] {
                    if i2 < data.best_version[2] return;
                    else if i2 == data.best_version[2] {
                        if i3 < data.best_version[3] return;
                    }
                }
            }

            free(data.best_name);
            data.best_name = copy_string(info.full_name);
            
            data.best_version[0] = xx i0;
            data.best_version[1] = xx i1;
            data.best_version[2] = xx i2;
            data.best_version[3] = xx i3;
        }

        data: Win10_Data;
        windows10_lib := tprint("%Lib", windows10_root);
        visit_files(windows10_lib, false, *data, win10_best, false, true);
        if data.best_name {
            translate_path(data.best_name);
            return data.best_name, 10;
        }
    }

    windows8_root := find_windows_kit_root("KitsRoot81");

    if windows8_root {
        Win8_Data :: struct {
            best_version: [2] s32;
            best_name:    string;
        }

        win8_best :: (info: *File_Visit_Info, data: *Win8_Data) {
            // For now, the most recent wins.
            success, anys := scan("winv%i.%i", info.short_name);
            if !success return;

            i0 := << cast(*int) anys[0].value_pointer;
            i1 := << cast(*int) anys[1].value_pointer;

            if i0 < data.best_version[0] return;
            else if i0 == data.best_version[0] {
                if i1 < data.best_version[1] return;
            }

            free(data.best_name);
            data.best_name = copy_string(info.full_name);
            
            data.best_version[0] = xx i0;
            data.best_version[1] = xx i1;
        }

        windows8_lib := tprint("%Lib", windows8_root);
        data: Win8_Data;
        visit_files(windows8_lib, false, *data, win8_best, false, true);  // @Robustness: This *also* visits files, which is not what we want. Ugh.
        if data.best_name {
            translate_path(data.best_name);
            return data.best_name, 8;
        }
    }
    
    return "", 0;
}

#scope_file

//
// Do we want to factor this into something like Windows_Com?
//

BSTR :: *u16;
COLESTR :: BSTR;

SysAllocString :: (psz: *u16) -> BSTR #foreign OleAut32;
SysFreeString  :: (psz: BSTR) -> void #foreign OleAut32;  // Only frees BSTR! Do not pass it a general wide string!



IEnumSetupInstances_VTable :: struct {
    using unknown: IUnknown_VTable;

	Next:  (this: *IEnumSetupInstances, celt: u32, rgelt: **ISetupInstance, pceltFetched: *u32) -> HRESULT #foreign;
	Skip:  (this: *IEnumSetupInstances, celt: u32) -> HRESULT #foreign;
	Reset: (this: *IEnumSetupInstances) -> HRESULT  #foreign;
	Clone: (this: *IEnumSetupInstances, ppenum: **IEnumSetupInstances) -> HRESULT  #foreign;
}

IEnumSetupInstances :: struct {
    using vtable: *IEnumSetupInstances_VTable;
    uuid :: "6380BCFF-41D3-4B2E-8B2E-BF8A6810C848";
}

ISetupInstance_VTable :: struct {
    using unknown : IUnknown_VTable;

	GetInstanceId: (this: *ISetupInstance, pbstrInstanceId: *BSTR) -> HRESULT #foreign;
	GetInstallDate: (this: *ISetupInstance, pInstallDate: *FILETIME) -> HRESULT #foreign;
	GetInstallationName: (this: *ISetupInstance, pbstrInstallationName: *BSTR) -> HRESULT #foreign;
	GetInstallationPath: (this: *ISetupInstance, pbstrInstallationPath: *BSTR) -> HRESULT #foreign;
	GetInstallationVersion: (this: *ISetupInstance, pbstrInstallationVersion: *BSTR) -> HRESULT #foreign;

	GetDisplayName: (this: *ISetupInstance, lcid: LCID, pbstrDisplayName: *BSTR) -> HRESULT #foreign;

	GetDescription: (this: *ISetupInstance, lcid: LCID, pbstrDescription: *BSTR) -> HRESULT #foreign;
	ResolvePath: (this: *ISetupInstance, pwszRelativePath: *COLESTR, pbstrAbsolutePath: *BSTR) -> HRESULT #foreign;
}

ISetupInstance :: struct {
    using vtable: *ISetupInstance_VTable;
    uuid :: "B41463C3-8866-43B5-BC33-2B0676F7F42E";
}

ISetupConfiguration_VTable :: struct {
    using unknown: IUnknown_VTable;

	EnumInstances: (this: *ISetupConfiguration, ppEnumInstances: **IEnumSetupInstances) -> HRESULT #foreign;
	GetInstanceForCurrentProcess: (this: *ISetupConfiguration, ppInstance: **ISetupInstance) -> HRESULT #foreign;
	GetInstanceForPath: (this: *ISetupConfiguration, wzPath: *u16, ppInstance: **ISetupInstance) -> HRESULT #foreign;
}
    
ISetupConfiguration :: struct {
    using vtable: *ISetupConfiguration_VTable;

    uuid :: "42843719-DB4C-46C2-8E7C-64F1816EFD5B";
}


COINIT_APARTMENTTHREADED :: 0;
COINIT_MULTITHREADED     :: 1;
COINIT_DISABLE_OLE1DDE   :: 2;
COINIT_SPEED_OVER_MEMORY :: 3;



using CLSCTX :: enum_flags u32 {
    CLSCTX_INPROC_SERVER    :: 0x1;
    CLSCTX_INPROC_HANDLER   :: 0x2;
    CLSCTX_LOCAL_SERVER     :: 0x4;
    CLSCTX_INPROC_SERVER16  :: 0x8;
    CLSCTX_REMOTE_SERVER    :: 0x10;
    CLSCTX_INPROC_HANDLER16 :: 0x20;
    CLSCTX_RESERVED1        :: 0x40;
    CLSCTX_RESERVED2        :: 0x80;
    CLSCTX_RESERVED3        :: 0x100;
    CLSCTX_RESERVED4        :: 0x200;
    CLSCTX_NO_CODE_DOWNLOAD :: 0x400;
    CLSCTX_RESERVED5        :: 0x800;
    CLSCTX_NO_CUSTOM_MARSHAL    :: 0x1000;
    CLSCTX_ENABLE_CODE_DOWNLOAD :: 0x2000;
    CLSCTX_NO_FAILURE_LOG       :: 0x4000;
    CLSCTX_DISABLE_AAA          :: 0x8000;
    CLSCTX_ENABLE_AAA           :: 0x10000;
    CLSCTX_FROM_DEFAULT_CONTEXT :: 0x20000;
    CLSCTX_ACTIVATE_X86_SERVER  :: 0x40000;
    CLSCTX_ACTIVATE_32_BIT_SERVER   :: CLSCTX_ACTIVATE_X86_SERVER;
    CLSCTX_ACTIVATE_64_BIT_SERVER   :: 0x80000;
    CLSCTX_ENABLE_CLOAKING          :: 0x100000;
    CLSCTX_APPCONTAINER             :: 0x400000;
    CLSCTX_ACTIVATE_AAA_AS_IU       :: 0x800000;
    CLSCTX_RESERVED6                :: 0x1000000;
    CLSCTX_ACTIVATE_ARM32_SERVER    :: 0x2000000;
    CLSCTX_PS_DLL                   :: 0x80000000;

    CLSCTX_INPROC   :: CLSCTX_INPROC_SERVER|CLSCTX_INPROC_HANDLER;
    CLSCTX_ALL      :: CLSCTX_INPROC_SERVER|CLSCTX_INPROC_HANDLER|CLSCTX_LOCAL_SERVER|CLSCTX_REMOTE_SERVER;
    CLSCTX_SERVER   :: CLSCTX_INPROC_SERVER|CLSCTX_LOCAL_SERVER|CLSCTX_REMOTE_SERVER;
}

// @@ Move this stuff to Windows.jai or COM.jai ?
CoInitialize   :: (pvReserved: *void) -> HRESULT #foreign Ole32;
CoUninitialize :: () -> void    #foreign Ole32;
CoInitializeEx :: (pvReserved: *void, dwCoInit: DWORD) -> HRESULT #foreign Ole32;

REFCLSID :: *IID;

CoCreateInstance :: (rclsid: REFCLSID, pUnkOuter: *IUnknown, dwClsContext: CLSCTX, riid: REFIID, ppv: **void) -> HRESULT #foreign Ole32;
CoCreateFreeThreadedMarshaler :: (punkOuter: *IUnknown, ppunkMarshal: **IUnknown) -> HRESULT #foreign Ole32;


#scope_export

find_visual_studio_in_a_ridiculous_garbage_way :: () -> (library_path := "", linker_path := "") {
    // rc := CoInitializeEx(null, COINIT_MULTITHREADED);
    rc := CoInitialize(null);
    // "Subsequent valid calls return false." So ignore false.
    // if rc != S_OK  return false;

    my_uid := uid(ISetupConfiguration.uuid);
    CLSID_SetupConfiguration := uid("177F0C4A-1CD3-4DE7-A32C-71DBBB9FA36D");
    
    config: *ISetupConfiguration;
    hr := CoCreateInstance(*CLSID_SetupConfiguration, null, CLSCTX_INPROC_SERVER, *my_uid, xx *config);
    if hr != 0  return;
    defer config.Release(xx config);
    
    instances: *IEnumSetupInstances;
    hr = config.EnumInstances(config, *instances);
    if hr != 0     return;
    if !instances  return;
    defer instances.Release(xx instances);
    
    while true {
        found: u32;
        instance: *ISetupInstance;
        hr := instances.Next(instances, 1, *instance, *found);
        if hr != S_OK break;

        defer instance.Release(xx instance);
        
        bstr_inst_path: BSTR;
        hr = instance.GetInstallationPath(instance, *bstr_inst_path);
        if hr != S_OK  continue;
        defer SysFreeString(bstr_inst_path);
        
        path := wide_to_utf8(bstr_inst_path);

        tools_filename := tprint("%\\VC\\Auxiliary\\Build\\Microsoft.VCToolsVersion.default.txt", path);

        tools_file, tools_file_success := File.read_entire_file(tools_filename, context.allocator);
        if !tools_file_success  continue;
        defer free(tools_file);


        version, version_found := find_character_from_left(tools_file, #char "\r");
        if !version_found {
            version, version_found = find_character_from_left(tools_file, #char "\n");
        }

        if !version_found  continue;

        
        library_path := tprint("%\\VC\\Tools\\MSVC\\%\\lib\\x64", path, version);

        library_file := tprint("%\\vcruntime.lib", library_path);  // @Speed: Could have library_path point to this string, with a smaller count, to save on memory flailing!
        if file_exists(library_file) {
            linker_path := tprint("%\\VC\\Tools\\MSVC\\%\\bin\\Hostx64\\x64", path, version);
            return library_path, linker_path;
        }

        /*
           Clang uses the 'SetupInstance->GetInstallationVersion' / ISetupHelper->ParseVersion to find the newest version and then reads the tools file to define the tools path - which is definitely better than what i did.
 
           @Incomplete: Should probably pick the newest version...
        */
    }

    // If we get here, we didn't find Visual Studio 2017. Try earlier versions.

    vs7_key: HKEY;
    rc = RegOpenKeyExA(HKEY_LOCAL_MACHINE, "SOFTWARE\\Microsoft\\VisualStudio\\SxS\\VS7", 0, KEY_QUERY_VALUE | KEY_WOW64_32KEY, *vs7_key);

    if rc != 0  return;
    defer RegCloseKey(vs7_key);

    versions :: string.["14.0", "12.0", "11.0", "10.0"];

    for v: versions {
        dw_type: DWORD;
        cb_data: DWORD;

        rc := RegQueryValueExA(vs7_key, v.data, null, *dw_type, null, *cb_data);
        if (rc == ERROR_FILE_NOT_FOUND) || (dw_type != REG_SZ) {
            continue;
        }

        buffer := alloc(cb_data);
        if !buffer  return "";
        defer free(buffer);
        
        rc = RegQueryValueExA(vs7_key, v.data, null, null, buffer, *cb_data);
        if rc != 0  continue;

        s: string;
        s.data = buffer;
        s.count = c_style_strlen(buffer);

        path := tprint("%VC\\Lib\\amd64", s);

        vcruntime_filename := tprint("%\\vcruntime.lib", path);
        exists := file_exists(vcruntime_filename);

        if exists {
            linker_path := tprint("%VC\\bin", buffer);
            return path, linker_path;  // Ignore vcruntime_filename!
        }
    }
        
    return;
}

#scope_file

BUFFER_LENGTH :: 10000;
Ole32    :: #foreign_system_library "Ole32";
OleAut32 :: #foreign_system_library "OleAut32";
