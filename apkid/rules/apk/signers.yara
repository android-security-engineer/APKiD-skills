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

rule debug_certificate : signer
{
  meta:
    description = "Android Debug Certificate"

  strings:
    $cn = "CN=Android Debug"

  condition:
    is_apk and $cn
}

rule apktool_default_certificate : signer
{
  meta:
    description = "APKTool Default Test Certificate"
    url         = "https://github.com/iBotPeaches/Apktool"

  strings:
    $s1 = "CN=Android,OU=Android,O=Android"

  condition:
    is_apk and $s1
}

rule uber_apk_signer : signer
{
  meta:
    description = "uber-apk-signer Test Certificate"
    url         = "https://github.com/patrickfav/uber-apk-signer"

  strings:
    $s1 = "CN=Uber Cert"
    $s2 = "uber-apk-signer"

  condition:
    is_apk and any of them
}

rule sign_apk_repacker : signer
{
  meta:
    description = "Common repack/resign tool certificate"

  strings:
    $s1 = "CN=re-signer"
    $s2 = "OU=re-signer"
    $s3 = "O=re-signer"

  condition:
    is_apk and any of them
}

rule keytool_test_certificate : signer
{
  meta:
    description = "Generic keytool-generated test certificate (default CN)"

  strings:
    $s1 = "CN=Unknown, OU=Unknown, O=Unknown"
    $s2 = "CN=Test Key"
    $s3 = "OU=Test"

  condition:
    is_apk and any of them
}

rule apksign_repacker : signer
{
  meta:
    description = "APKSign / generic repacker certificate"

  strings:
    $s1 = "CN=apksign"
    $s2 = "OU=apksign"
    $s3 = "O=apksign"

  condition:
    is_apk and any of them
}
