#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Prepares a HeliBoard/AOSP ".combined" word list for tool/build_dictionary.dart:
# drops the words that belong to the other regional standard of the same language
# (Brazilian words out of pt-PT, European words out of pt-BR), keeping every other entry
# and its bigrams untouched.
#
#   python tool/european/prepare_wordlist.py --lang pt-BR --input in.combined --out out.combined
import argparse

# Words used in Portugal but not in Brazil (kept out of pt-BR).
PT_PT_ONLY = {
    'autocarro', 'autocarros', 'equipa', 'equipas', 'telemóvel', 'telemóveis', 'ecrã', 'ecrãs',
    'frigorífico', 'frigoríficos', 'rapariga', 'raparigas', 'rapaz', 'rapazes', 'pequeno-almoço',
    'comboio', 'comboios', 'sumo', 'sumos', 'ténis', 'chávena', 'chávenas',
    'casa-de-banho', 'cacifo', 'cacifos', 'miúdo', 'miúdos', 'miúda', 'miúdas',
    'fixe', 'bué', 'autoclismo', 'pastelaria', 'pastelarias', 'talho', 'talhos',
    'rebuçado', 'rebuçados', 'camisola', 'camisolas',
}

# Words used in Brazil but not in Portugal (kept out of pt-PT).
PT_BR_ONLY = {
    'ônibus', 'trem', 'trens', 'celular', 'celulares', 'banheiro', 'banheiros', 'geladeira',
    'geladeiras', 'garoto', 'garotos', 'garota', 'garotas', 'sorvete', 'sorvetes', 'xícara',
    'xícaras', 'suco', 'sucos', 'tênis', 'calcinha', 'calcinhas', 'cadê', 'bacana', 'bacanas',
    'moleque', 'moleques', 'caminhão', 'caminhões', 'cafezinho', 'cafezinhos', 'mano', 'manos',
}


def drop_set(lang):
    if lang == 'pt-BR':
        return {w.lower() for w in PT_PT_ONLY}
    if lang == 'pt-PT':
        return {w.lower() for w in PT_BR_ONLY}
    return set()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--lang', required=True)
    parser.add_argument('--input', required=True)
    parser.add_argument('--out', required=True)
    args = parser.parse_args()

    drop = drop_set(args.lang)
    dropped = 0
    skipping = False
    with open(args.input, encoding='utf-8') as src, open(args.out, 'w', encoding='utf-8', newline='\n') as dst:
        for line in src:
            if line.startswith(' word='):
                word = line.strip().split(',')[0][len('word='):]
                skipping = word.lower() in drop
                if skipping:
                    dropped += 1
                    continue
            elif line.startswith('  ') and skipping:
                continue
            else:
                skipping = False
                if line.startswith('dictionary='):
                    dst.write(line)
                    continue
                if not line.startswith(' ') and line.strip():
                    skipping = False
            dst.write(line)
    print('dropped', dropped, 'entries for', args.lang)


if __name__ == '__main__':
    main()
