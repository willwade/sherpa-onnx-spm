import plistlib
import sys

def patch_info_plist(plist_path, slice_name, library_name):
    with open(plist_path, "rb") as f:
        plist = plistlib.load(f)

    available_libraries = plist.get("AvailableLibraries", [])

    new_lib = {
        "BinaryPath": library_name,
        "DebugSymbolsPath": "",
        "LibraryIdentifier": slice_name,
        "LibraryPath": library_name,
        "HeadersPath": "Headers",
    }

    existing = {
        (lib.get("LibraryIdentifier"), lib.get("BinaryPath"))
        for lib in available_libraries
    }
    if (slice_name, library_name) not in existing:
        available_libraries.append(new_lib)
        plist["AvailableLibraries"] = available_libraries
        with open(plist_path, "wb") as f:
            plistlib.dump(plist, f)
        print(f"Added {library_name} for {slice_name} to Info.plist")
    else:
        print(f"{slice_name}/{library_name} already in Info.plist, skipping")

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print(f"Usage: {sys.argv[0]} <Info.plist> <slice_name> <library_name>")
        sys.exit(1)
    patch_info_plist(sys.argv[1], sys.argv[2], sys.argv[3])
