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

rule checks_su_binary : root
{
  meta:
    description = "Checks for su binary (root detection)"

  strings:
    $s1 = "/system/bin/su"
    $s2 = "/system/xbin/su"
    $s3 = "/data/local/bin/su"
    $s4 = "/data/local/xbin/su"
    $s5 = "/sbin/su"

  condition:
    is_dex and 2 of them
}

rule detects_magisk : root
{
  meta:
    description = "Detects Magisk root"
    url         = "https://github.com/topjohnwu/Magisk"

  strings:
    $s1 = ".magisk"
    $s2 = "/data/adb/magisk"
    $s3 = "io.github.huskydg.magisk"
    $s4 = "com.topjohnwu.magisk"

  condition:
    is_dex and any of them
}

rule detects_supersu : root
{
  meta:
    description = "Detects SuperSU or Superuser"

  strings:
    $s1 = "eu.chainfire.supersu"
    $s2 = "com.noshufou.android.su"
    $s3 = "com.koushikdutta.superuser"
    $s4 = "com.thirdparty.superuser"

  condition:
    is_dex and any of them
}

rule rootbeer_library : root
{
  meta:
    description = "RootBeer Root Detection Library"
    url         = "https://github.com/scottyab/rootbeer"

  strings:
    $s1 = "Lcom/scottyab/rootbeer/"
    $s2 = "com.scottyab.rootbeer"

  condition:
    is_dex and any of them
}

rule generic_root_check : root
{
  meta:
    description = "Generic root detection utility methods"

  strings:
    $s1 = "isRooted"
    $s2 = "isDeviceRooted"
    $s3 = "checkRootAccess"
    $s4 = "detectRoot"
    $s5 = "RootDetection"
    $s6 = "RootChecker"

  condition:
    is_dex and 2 of them
}

rule kingroot : root
{
  meta:
    description = "KingRoot / VRoot"

  strings:
    $s1 = "com.kingroot.kinguser"
    $s2 = "com.kingroot.master"
    $s3 = "com.vroot"

  condition:
    is_dex and any of them
}

rule checks_build_tags_rooted : root
{
  meta:
    description = "Checks android.os.Build.TAGS for test-keys (rooted device indicator)"

  strings:
    $s1 = "test-keys"
    $s2 = "BUILD/TAGS"
    $s3 = "ro.build.tags"

  condition:
    is_dex and any of them
}
