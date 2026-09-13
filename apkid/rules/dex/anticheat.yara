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

rule tencent_ace : anticheat
{
  meta:
    description = "Tencent Anti-Cheat Expert (ACE)"
    url         = "https://ie.tencent.com/ACE"

  strings:
    $s1 = "Lcom/tencent/anti_cheat/"
    $s2 = "libtersafe"
    $s3 = "Lcom/tencent/tersafe/"

  condition:
    is_dex and any of them
}

rule netease_yidun_anticheat : anticheat
{
  meta:
    description = "NetEase YiDun Anti-Cheat"

  strings:
    $s1 = "Lcom/netease/nimgame/anticheat/"
    $s2 = "Lcom/netease/yidun/"
    $s3 = "com.netease.yidun"

  condition:
    is_dex and any of them
}

rule easy_anti_cheat : anticheat
{
  meta:
    description = "Easy Anti-Cheat"
    url         = "https://www.easyanticheat.net/"

  strings:
    $s1 = "EasyAntiCheat"
    $s2 = "easyanticheat"
    $s3 = "Lcom/epicgames/mobile/easyanticheat/"

  condition:
    is_dex and any of them
}

rule detects_gameguardian : anticheat
{
  meta:
    description = "Detects GameGuardian presence (anti-cheat measure)"

  strings:
    $s1 = "catch.me.if.you.can"
    $s2 = "gameguardian"
    $s3 = "GameGuardian"
    $s4 = "Lxiaoyao/gamekiller/"

  condition:
    is_dex and any of them
}

rule qq_game_anticheat : anticheat
{
  meta:
    description = "QQ Game / Tencent game anti-cheat SDK"

  strings:
    $s1 = "Lcom/tencent/qqgamebid/"
    $s2 = "Lcom/tencent/tmgp/anticheat/"
    $s3 = "com.tencent.tmgp.anticheat"

  condition:
    is_dex and any of them
}

rule armorfly_anticheat : anticheat
{
  meta:
    description = "ArmorFly Anti-Cheat SDK"

  strings:
    $s1 = "Lcom/armorfly/"
    $s2 = "armorfly"

  condition:
    is_dex and any of them
}
