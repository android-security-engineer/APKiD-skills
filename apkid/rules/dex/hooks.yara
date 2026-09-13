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

rule xposed_framework : hook
{
  meta:
    description = "Xposed Framework embedded"
    url         = "https://github.com/rovo89/Xposed"

  strings:
    $s1 = "Lde/robv/android/xposed/XposedBridge;"
    $s2 = "de/robv/android/xposed/XposedHelpers"
    $s3 = "de.robv.android.xposed.XposedBridge"
    $s4 = "XposedBridge.jar"

  condition:
    is_dex and any of them
}

rule lsposed_framework : hook
{
  meta:
    description = "LSPosed / LSPlant Framework embedded"
    url         = "https://github.com/LSPosed/LSPosed"

  strings:
    $s1 = "Lorg/lsposed/lsparanoid/"
    $s2 = "io.github.lsposed"
    $s3 = "LSPosed"
    $s4 = "Lorg/lsposed/hiddenapibypass/"

  condition:
    is_dex and any of them
}

rule frida_gadget_dex : hook
{
  meta:
    description = "Frida Gadget (DEX-side indicator)"
    url         = "https://frida.re"

  strings:
    $s1 = "frida-gadget"
    $s2 = "re.frida.agent"
    $s3 = "Lre/frida/"

  condition:
    is_dex and any of them
}

rule cydia_substrate : hook
{
  meta:
    description = "Cydia Substrate (com.saurik.substrate)"
    url         = "http://www.cydiasubstrate.com/"

  strings:
    $s1 = "Lcom/saurik/substrate/MS;"
    $s2 = "com.saurik.substrate"
    $s3 = "Lcom/saurik/substrate/"

  condition:
    is_dex and any of them
}

rule virtualxposed : hook
{
  meta:
    description = "VirtualXposed / VirtualApp"
    url         = "https://github.com/android-hacker/VirtualXposed"

  strings:
    $s1 = "Lcom/lody/virtual/"
    $s2 = "com.lody.virtual"
    $s3 = "io.virtualapp"

  condition:
    is_dex and any of them
}

rule taichi_framework : hook
{
  meta:
    description = "Taichi Xposed Framework"
    url         = "https://github.com/tiann/taichi"

  strings:
    $s1 = "me.weishu.exposed"
    $s2 = "Lme/weishu/exposed/"
    $s3 = "me.weishu.exp"

  condition:
    is_dex and any of them
}
