#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Builds assets/dict/<lang>.mdict for the European languages from HeliBoard's wordlists
# (https://codeberg.org/Helium314/aosp-dictionaries, wordlists/*.combined). Sources and licences are
# in docs/notices/european.md.
#
#   python tool/european/build_dictionaries.py <folder with the downloaded .combined files>
#
# Each dictionary stays under 1.5 MB (sizes printed). Run from the repository root.
import os
import subprocess
import sys

ROOT = os.path.normpath(os.path.join(os.path.dirname(__file__), '..', '..'))

# lang, source file, max words, max bigrams, prepare (drop the other regional standard?)
JOBS = [
    ('es', 'main_es__experimental.combined', 70000, 70000, False),
    ('fr', 'main_fr__experimental.combined', 62000, 60000, False),
    ('de', 'main_de.combined', 56000, 46000, False),
    ('pt-BR', 'main_pt_BR.combined', 70000, 0, True),
    ('pt-PT', 'main_pt_PT__experimental.combined', 66000, 62000, True),
    ('id', 'main_id__experimental.combined', 58000, 38000, False),
    ('ru', 'main_ru__experimental.combined', 78000, 0, False),
    ('uk', 'main_uk__experimental.combined', 85000, 0, False),
]


def run(args):
    print('+', ' '.join(args))
    subprocess.run(args, cwd=ROOT, check=True)


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        return 64
    source_dir = sys.argv[1]
    scratch = os.path.join(source_dir, 'prepared')
    os.makedirs(scratch, exist_ok=True)
    for lang, name, max_words, max_bigrams, prepare in JOBS:
        combined = os.path.join(source_dir, name)
        if prepare:
            prepared = os.path.join(scratch, name)
            run([sys.executable, os.path.join('tool', 'european', 'prepare_wordlist.py'),
                 '--lang', lang, '--input', combined, '--out', prepared])
            combined = prepared
        out = os.path.join('assets', 'dict', lang + '.mdict')
        run([os.environ.get('DART', 'dart'), 'run', 'tool/build_dictionary.dart', '--input', combined, '--lang', lang, '--out', out,
             '--max-words', str(max_words), '--max-bigrams', str(max_bigrams)])
    return 0


if __name__ == '__main__':
    sys.exit(main())
