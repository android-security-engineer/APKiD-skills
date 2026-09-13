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

rule detects_xposed : anti_hook
{
  meta:
    description = "Detects Xposed Framework presence"

  strings:
    $s1 = "de.robv.android.xposed.installer"
    $s2 = "/data/data/de.robv.android.xposed"
    $s3 = "XposedBridge"
    $s4 = "de/robv/android/xposed"

  condition:
    is_dex and any of them
}

rule detects_frida : anti_hook
{
  meta:
    description = "Detects Frida instrumentation"

  strings:
    $s1 = "frida-agent"
    $s2 = "frida-gadget"
    $s3 = "gum-js-loop"
    $s4 = "linjector"
    $s5 = "re.frida.agent"

  condition:
    is_dex and any of them
}

rule checks_proc_maps_for_hooks : anti_hook
{
  meta:
    description = "Checks /proc/self/maps for injected hook libraries"

  strings:
    $maps    = "/proc/self/maps"
    $frida   = "frida"
    $sub     = "substrate"
    $xposed  = "xposed"

  condition:
    is_dex and $maps and any of ($frida, $sub, $xposed)
}

rule integrity_check_hook : anti_hook
{
  meta:
    description = "Possible inline hook detection (function integrity check)"

  strings:
    $s1 = "checkIntegrity"
    $s2 = "detectHook"
    $s3 = "isHooked"
    $s4 = "hookDetect"
    $s5 = "antiHook"
    $s6 = "AntiHook"

  condition:
    is_dex and any of them
}

rule checks_substrate_loaded : anti_hook
{
  meta:
    description = "Checks whether Cydia Substrate is loaded"

  strings:
    $s1 = "com.saurik.substrate"
    $s2 = "substrate"
    $s3 = "MSHookMethod"

  condition:
    is_dex and any of them
}
