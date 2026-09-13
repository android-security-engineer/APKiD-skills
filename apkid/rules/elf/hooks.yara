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

rule frida_gadget_elf : hook
{
  meta:
    description = "Frida Gadget embedded in ELF"
    url         = "https://frida.re"

  strings:
    $s1 = "frida-gadget" ascii wide
    $s2 = "frida_agent_main" ascii
    $s3 = "GumInterceptor" ascii
    $s4 = "gum-js-loop" ascii
    $s5 = "frida:rpc" ascii

  condition:
    is_elf and any of them
}

rule substrate_elf : hook
{
  meta:
    description = "Cydia Substrate native library"
    url         = "http://www.cydiasubstrate.com/"

  strings:
    $s1 = "SubstrateHook" ascii
    $s2 = "MSHookFunction" ascii
    $s3 = "SubstrateMain" ascii
    $s4 = "MSGetImageByName" ascii

  condition:
    is_elf and any of them
}

rule xhook_elf : hook
{
  meta:
    description = "xHook PLT Hook Library"
    url         = "https://github.com/iqiyi/xHook"

  strings:
    $s1 = "xhook_register" ascii
    $s2 = "xhook_refresh" ascii
    $s3 = "xhook_ignore" ascii

  condition:
    is_elf and any of them
}

rule whale_elf : hook
{
  meta:
    description = "Whale Hook Framework (ELF)"
    url         = "https://github.com/asLody/whale"

  strings:
    $s1 = "whale_hook_function" ascii
    $s2 = "WInlineHook" ascii

  condition:
    is_elf and any of them
}

rule dobby_elf : hook
{
  meta:
    description = "Dobby Inline Hook Framework"
    url         = "https://github.com/jmpews/Dobby"

  strings:
    $s1 = "DobbyHook" ascii
    $s2 = "DobbySymbolResolver" ascii
    $s3 = "dobby_" ascii

  condition:
    is_elf and 2 of them
}

rule shadowhook_elf : hook
{
  meta:
    description = "ShadowHook (ByteDance)"
    url         = "https://github.com/bytedance/android-inline-hook"

  strings:
    $s1 = "shadowhook_hook_func_addr" ascii
    $s2 = "shadowhook_" ascii

  condition:
    is_elf and 2 of them
}
