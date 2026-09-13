/*
 * Copyright (C) 2023  RedNaga. https://rednaga.io
 * All rights reserved. Contact: rednaga@protonmail.com
 *
 *
 * This file is part of APKiD
 *
 *
 * Commercial License Usage
 * ------------------------
 * Licensees holding valid commercial APKiD licenses may use this file
 * in accordance with the commercial license agreement provided with the
 * Software or, alternatively, in accordance with the terms contained in
 * a written agreement between you and RedNaga.
 *
 *
 * GNU General Public License Usage
 * --------------------------------
 * Alternatively, this file may be used under the terms of the GNU General
 * Public License version 3.0 as published by the Free Software Foundation
 * and appearing in the file LICENSE.GPL included in the packaging of this
 * file. Please visit http://www.gnu.org/copyleft/gpl.html and review the
 * information to ensure the GNU General Public License version 3.0
 * requirements will be met.
 *
 **/

include "common.yara"

rule embedded_dex_in_assets : embedded
{
  meta:
    description = "DEX file embedded in assets directory"

  strings:
    $dex_magic = { 64 65 78 0A 30 ?? ?? 00 }
    $assets    = "assets/"

  condition:
    is_dex and $dex_magic and $assets
}

rule dynamic_dex_loading : embedded
{
  meta:
    description = "Dynamic DEX loading from assets or external storage"

  strings:
    $loader1 = "DexClassLoader"
    $loader2 = "InMemoryDexClassLoader"
    $asset1  = "assets/"
    $ext1    = ".jar"
    $ext2    = ".dex"

  condition:
    is_dex and any of ($loader1, $loader2) and any of ($asset1, $ext1, $ext2)
}

rule encrypted_payload_loader : embedded
{
  meta:
    description = "Loads encrypted payload from assets (common in second-stage packers)"

  strings:
    $d1      = "decrypt"
    $d2      = "Decrypt"
    $d3      = "decryptFile"
    $d4      = "decodeFromAssets"
    $loader1 = "DexClassLoader"
    $loader2 = "InMemoryDexClassLoader"

  condition:
    is_dex and any of ($d1, $d2, $d3, $d4) and any of ($loader1, $loader2)
}

rule multidex_embedded : embedded
{
  meta:
    description = "Multiple embedded DEX files (common in advanced packers)"

  strings:
    $c2 = "classes2.dex"
    $c3 = "classes3.dex"
    $c4 = "classes4.dex"
    $c5 = "classes5.dex"

  condition:
    is_dex and 2 of them
}

rule native_lib_loader : embedded
{
  meta:
    description = "Loads native library from assets or private storage (unpacking pattern)"

  strings:
    $s1 = "System.load"
    $s2 = "loadLibrary"
    $a1 = "assets/"
    $a2 = "getFilesDir"
    $a3 = "getCacheDir"

  condition:
    is_dex and any of ($s1, $s2) and any of ($a1, $a2, $a3)
}
