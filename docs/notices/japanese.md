# Japanese notices (Wave 4-B)

## dict-ja-mozc: the Japanese dictionary pack

- **Source:** Mozc open-source dictionary, `src/data/dictionary_oss/` (dictionary00.txt to dictionary09.txt,
  connection_single_column.txt, id.def, README.txt), https://github.com/google/mozc
- **Commit:** `1527a4cd1217cec4611cd4bc8d46f8c66ea79e6a` (master on 2026-11-20). `tool/packs/japanese/stage_mozc.ps1`
  downloads exactly this commit.
- **Licence:** BSD-3-Clause for the Mozc code and data (full text below). The dictionary README also carries the
  IPAdic terms (mecab-ipadic-2.7.0-20070801, NAIST and ICOT; full text below) and the Okinawa dictionary, which
  is public domain.
- **Changes made:** the entries are converted into `japanese.lex.gz` (reading trie-like index, surfaces, word ids and
  costs) and `japanese.conn.gz` (the connection matrix), by `tool/japanese/build_mozc_lexicon.dart`. Readings are
  folded to hiragana, and entries whose reading has any other character are dropped (3,550 of 1,289,076 lines
  skipped, including malformed ones). Costs are stored as 16-bit values.
- **Attribution:** "Japanese dictionary: Mozc open-source dictionary (Google), IPAdic 2.7.0 (NAIST, ICOT), Okinawa dictionary."

## Romaji table

`lib/src/engine/lang/japanese/romaji.dart` is written for this project from the common Hepburn and Kunrei spellings.
No table from Mozc or any other source is copied.

## Golden corpus (test data only)

`test/engine/lang/japanese/golden_ja.tsv` (300 items) is built by `tool/japanese/build_golden_tatoeba.py` from the
Tatoeba Japanese furigana transcriptions (https://downloads.tatoeba.org/exports/transcriptions.tar.bz2, export of
2026-11-21), licence CC BY 2.0 FR (https://creativecommons.org/licenses/by/2.0/fr/), © Tatoeba contributors. Each
row keeps its sentence id (`tatoeba:<id>`, https://tatoeba.org/en/sentences/show/<id>). Rows are cut from the
sentences at punctuation and keep only hiragana and annotated kanji. The corpus is not shipped in the app.

The first corpus (Aozora Bunko ruby texts by 岡本かの子, built by a since-removed `build_golden.dart`) was replaced in the Wave 4
merge: its pre-war spellings were mostly missing from Mozc, and the ruby transcriptions have no licence from the
COMMON.md list.

## Licence texts

### Mozc LICENSE (BSD-3-Clause)

```text
Copyright 2010-2018, Google Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

  * Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above
    copyright notice, this list of conditions and the following disclaimer
    in the documentation and/or other materials provided with the
    distribution.
  * Neither the name of Google Inc. nor the names of its
    contributors may be used to endorse or promote products derived from
    this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

---

Files: src/data/dictionary*

Copyright 2000, 2001, 2002, 2003 Nara Institute of Science
and Technology.  All Rights Reserved.

Use, reproduction, and distribution of this software is permitted.
Any copy of this software, whether in its original form or modified,
must include both the above copyright notice and the following
paragraphs.

Nara Institute of Science and Technology (NAIST),
the copyright holders, disclaims all warranties with regard to this
software, including all implied warranties of merchantability and
fitness, in no event shall NAIST be liable for
any special, indirect or consequential damages or any damages
whatsoever resulting from loss of use, data or profits, whether in an
action of contract, negligence or other tortuous action, arising out
of or in connection with the use or performance of this software.

A large portion of the dictionary entries
originate from ICOT Free Software.  The following conditions for ICOT
Free Software applies to the current dictionary as well.

Each User may also freely distribute the Program, whether in its
original form or modified, to any third party or parties, PROVIDED
that the provisions of Section 3 ("NO WARRANTY") will ALWAYS appear
on, or be attached to, the Program, which is distributed substantially
in the same form as set out herein and that such intended
distribution, if actually made, will neither violate or otherwise
contravene any of the laws and regulations of the countries having
jurisdiction over the User or the intended distribution itself.

NO WARRANTY

The program was produced on an experimental basis in the course of the
research and development conducted during the project and is provided
to users as so produced on an experimental basis.  Accordingly, the
program is provided without any warranty whatsoever, whether express,
implied, statutory or otherwise.  The term "warranty" used herein
includes, but is not limited to, any warranty of the quality,
performance, merchantability and fitness for a particular purpose of
the program and the nonexistence of any infringement or violation of
any right of any third party.

Each user of the program will agree and understand, and be deemed to
have agreed and understood, that there is no warranty whatsoever for
the program and, accordingly, the entire risk arising from or
otherwise connected with the program is assumed by the user.

Therefore, neither ICOT, the copyright holder, or any other
organization that participated in or was otherwise related to the
development of the program and their respective officials, directors,
officers and other employees shall be held liable for any and all
damages, including, without limitation, general, special, incidental
and consequential damages, arising out of or otherwise in connection
with the use or inability to use the program or any product, material
or result produced or otherwise obtained by using the program,
regardless of whether they have been advised of, or otherwise had
knowledge of, the possibility of such damages at any time during the
project or thereafter.  Each user will be deemed to have agreed to the
foregoing by his or her commencement of use of the program.  The term
"use" as used herein includes, but is not limited to, the use,
modification, copying and distribution of the program and the
production of secondary products from the program.

In the case where the program, whether in its original form or
modified, was distributed or delivered to or received by a user from
any person, organization or entity other than ICOT, unless it makes or
grants independently of ICOT any specific warranty to the user in
writing, such person, organization or entity, will also be exempted
from and not be held liable to the user for any such damages as noted
above as far as the program is concerned.

---

Files: src/data/dictionary*

Public Domain Dataです。使用・変更・配布に関しては一切の制限をつけません。
商品などに組み込むことも自由に行なってください。すでにいくつかの辞書には沖縄辞書が採用されています。
勝手ながら、沖縄辞書に寄贈された辞書も in the Public Domain' 扱いとさせていただきます。
```

### dictionary_oss README (IPAdic and Okinawa dictionary terms)

```text
Open source mozc dictionary is different from the dictionary
used for Google Japanese Input. The differences are as follows:

- Large vocabulary set generated from the Web corpus is not included.
- The vocabulary set is basically the same as that of IPAdic.
  The licenses of IPAdic is found below.
  Here's the version of IPAdic Mozc uses.
  * mecab-ipadic-2.7.0-20070801 (ipadic-2.7.0)
- Okinawa Dictionary is used to enrich named entities.
  http://sourceforge.jp/projects/o-dic/
  The license of Okinawa dictionary is found below.
- Google manually added some extra adjective/verbs which are not in IPAdic.
- Many Katakana words are included in the dictionary. They are collected as unknown words
  during the text processing over the Web data.
- To improve the conversion quality of Mozc, several compound words
  (like 社員証, 再起動) are added. We basically collected these compounds from the Web
  by using MeCab and IPAdic.
- Open source version doesn't include Japanese postal code dictionary.

You can add zip code dictionary by follows:
1. Download zip code data from http://www.post.japanpost.jp/zipcode/download.html
2. Extract them
3. Update zip_code_seed.tsv by
  PYTHONPATH="${PYTHONPATH}:../../"  \
    python ../../dictionary/gen_zip_code_seed.py \
    --zip_code=KEN_ALL.CSV --jigyosyo=JIGYOSYO.CSV >> dictionary09.txt


-------------------------------------------------------------------------------
IPAdic is licensed as follows:

Copyright 2000, 2001, 2002, 2003 Nara Institute of Science
and Technology.  All Rights Reserved.

Use, reproduction, and distribution of this software is permitted.
Any copy of this software, whether in its original form or modified,
must include both the above copyright notice and the following
paragraphs.

Nara Institute of Science and Technology (NAIST),
the copyright holders, disclaims all warranties with regard to this
software, including all implied warranties of merchantability and
fitness, in no event shall NAIST be liable for
any special, indirect or consequential damages or any damages
whatsoever resulting from loss of use, data or profits, whether in an
action of contract, negligence or other tortuous action, arising out
of or in connection with the use or performance of this software.

A large portion of the dictionary entries
originate from ICOT Free Software.  The following conditions for ICOT
Free Software applies to the current dictionary as well.

Each User may also freely distribute the Program, whether in its
original form or modified, to any third party or parties, PROVIDED
that the provisions of Section 3 ("NO WARRANTY") will ALWAYS appear
on, or be attached to, the Program, which is distributed substantially
in the same form as set out herein and that such intended
distribution, if actually made, will neither violate or otherwise
contravene any of the laws and regulations of the countries having
jurisdiction over the User or the intended distribution itself.

NO WARRANTY

The program was produced on an experimental basis in the course of the
research and development conducted during the project and is provided
to users as so produced on an experimental basis.  Accordingly, the
program is provided without any warranty whatsoever, whether express,
implied, statutory or otherwise.  The term "warranty" used herein
includes, but is not limited to, any warranty of the quality,
performance, merchantability and fitness for a particular purpose of
the program and the nonexistence of any infringement or violation of
any right of any third party.

Each user of the program will agree and understand, and be deemed to
have agreed and understood, that there is no warranty whatsoever for
the program and, accordingly, the entire risk arising from or
otherwise connected with the program is assumed by the user.

Therefore, neither ICOT, the copyright holder, or any other
organization that participated in or was otherwise related to the
development of the program and their respective officials, directors,
officers and other employees shall be held liable for any and all
damages, including, without limitation, general, special, incidental
and consequential damages, arising out of or otherwise in connection
with the use or inability to use the program or any product, material
or result produced or otherwise obtained by using the program,
regardless of whether they have been advised of, or otherwise had
knowledge of, the possibility of such damages at any time during the
project or thereafter.  Each user will be deemed to have agreed to the
foregoing by his or her commencement of use of the program.  The term
"use" as used herein includes, but is not limited to, the use,
modification, copying and distribution of the program and the
production of secondary products from the program.

In the case where the program, whether in its original form or
modified, was distributed or delivered to or received by a user from
any person, organization or entity other than ICOT, unless it makes or
grants independently of ICOT any specific warranty to the user in
writing, such person, organization or entity, will also be exempted
from and not be held liable to the user for any such damages as noted
above as far as the program is concerned.

-------------------------------------------------------------------------------
Okinawa dictionary is licensed as follows

Public Domain Dataです。使用・変更・配布に関しては一切の制限をつけません。
商品などに組み込むことも自由に行なってください。すでにいくつかの辞書には沖縄辞書が採用されています。
勝手ながら、沖縄辞書に寄贈された辞書も in the Public Domain' 扱いとさせていただきます。
```
