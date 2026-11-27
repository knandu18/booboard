// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'BooBoard';

  @override
  String get homeTagline => 'Digitação privada, neste celular';

  @override
  String get homeOfflinePromise =>
      'O BooBoard funciona offline e *não envia nada a lugar nenhum.*';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Excluir';

  @override
  String get save => 'Salvar';

  @override
  String get useAction => 'Usar';

  @override
  String get off => 'Desativado';

  @override
  String get left => 'Esquerda';

  @override
  String get right => 'Direita';

  @override
  String get settingsLanguages => 'Idiomas';

  @override
  String get settingsTyping => 'Digitação';

  @override
  String get settingsFeel => 'Sensação';

  @override
  String get settingsThemes => 'Temas';

  @override
  String get settingsPanels => 'Painéis';

  @override
  String get settingsVoice => 'Voz';

  @override
  String get settingsTranslation => 'Tradução';

  @override
  String get settingsPrivacy => 'Privacidade';

  @override
  String get settingsAbout => 'Sobre';

  @override
  String get settingsModelPacks => 'Pacotes de modelos';

  @override
  String get homeSetupTurnOn =>
      'Ative o BooBoard na lista de teclados do Android.';

  @override
  String get homeSetupChoose =>
      'Escolha o BooBoard como o teclado que você usa.';

  @override
  String get homeFinishSetup => 'Concluir a configuração do BooBoard';

  @override
  String get homeTypingSubtitle => 'Correções, sugestões, teclas e deslizar';

  @override
  String get homeFeelSubtitle => 'Vibração, sons, altura e modo de uma mão';

  @override
  String get homePanelsSubtitle => 'Área de transferência e emoji';

  @override
  String get homeVoiceSubtitle => 'Fale para digitar, neste celular';

  @override
  String get homeTranslationSubtitle => 'Traduz enquanto você digita, offline';

  @override
  String get homePrivacySubtitle =>
      'O que é guardado, incógnito, bloqueio do app e backup';

  @override
  String get homeAboutSubtitle => 'Versão, licenças e código-fonte';

  @override
  String get homeImages => 'Imagens';

  @override
  String get homeAboutBooBoard => 'Sobre o BooBoard';

  @override
  String get websiteOpenHint => 'Abre booboard.com no seu navegador';

  @override
  String get websiteNoBrowser => 'Nenhum navegador pode abrir booboard.com.';

  @override
  String get imagesSoonTitle => 'Imagens *em breve*';

  @override
  String get imagesSoonBody =>
      'Crie imagens a partir das suas palavras, aqui neste telefone. Como tudo no BooBoard, vai funcionar offline.';

  @override
  String get aboutWebsite => 'Site';

  @override
  String get aboutTitle => 'Sobre';

  @override
  String aboutVersion(String versionCode, String versionName) {
    return 'Versão $versionName ($versionCode)';
  }

  @override
  String aboutVersionDebug(String versionCode, String versionName) {
    return 'Versão $versionName ($versionCode) · build de depuração';
  }

  @override
  String get aboutReadingVersion => 'Lendo a versão…';

  @override
  String get aboutPrivacy => 'Privacidade';

  @override
  String get aboutNoInternet => 'O BooBoard não pode usar a internet';

  @override
  String get aboutNoInternetBody =>
      'As versões de lançamento não têm permissão de internet, então nada do que você digita sai deste celular.';

  @override
  String get aboutLicence => 'Licença';

  @override
  String get aboutGplTitle => 'Licença Pública Geral GNU v3 ou posterior';

  @override
  String get aboutGplBody =>
      'O BooBoard é software livre. Você pode estudá-lo, alterá-lo e compartilhá-lo sob a GPL.';

  @override
  String get aboutSourceCode => 'Código-fonte';

  @override
  String get aboutSourceBody =>
      'O BooBoard é GPL-3.0-or-later. O código-fonte está disponível na página do projeto.';

  @override
  String get aboutLicences => 'Licenças';

  @override
  String get aboutOpenSource => 'Licenças de código aberto';

  @override
  String get aboutOpenSourceBody =>
      'Flutter, material_ui e todos os pacotes que o BooBoard usa';

  @override
  String get aboutTextLoadFailed => 'Não foi possível carregar este texto.';

  @override
  String get languagesEnabledHeader => 'Ativados; o primeiro é o padrão';

  @override
  String get languagesActive => 'Idioma ativo';

  @override
  String get languagesAdd => 'Adicionar um idioma';

  @override
  String get languagesAllEnabled => 'Todos os idiomas estão ativados';

  @override
  String get languagesAllEnabledBody => 'Remova um acima para abrir espaço.';

  @override
  String get languagesMultilingual => 'Digitação multilíngue';

  @override
  String get languagesMultilingualBody =>
      'Sugere palavras de até três idiomas ativados que usam a mesma escrita do teclado. Uma palavra que qualquer um deles conheça nunca é corrigida automaticamente.';

  @override
  String get languagesNativeDigits => 'Dígitos nativos';

  @override
  String get languagesNativeDigitsBody =>
      'Digita números na escrita do idioma ativo quando ele os tem (०१२, ٠١٢).';

  @override
  String get languagesOptions => 'Opções de idioma';

  @override
  String get languagesZhSubtitle =>
      'Pinyin, caracteres tradicionais e pacotes de dicionário';

  @override
  String get languagesJaSubtitle =>
      'Entrada por deslize, conversão e pacotes de dicionário';

  @override
  String languagesReorderLabel(String language) {
    return 'Arraste para reordenar $language';
  }

  @override
  String languageDefaultLabel(String language) {
    return '$language, padrão';
  }

  @override
  String languageLayoutTooltip(String language) {
    return 'Layout para $language';
  }

  @override
  String languageRemoveTooltip(String language) {
    return 'Remover $language';
  }

  @override
  String get feelHaptics => 'Háptica';

  @override
  String get feelHapticFeedback => 'Retorno tátil';

  @override
  String get feelHapticFeedbackBody =>
      'Uma vibração curta em cada tecla, seguindo a configuração do sistema';

  @override
  String get feelHapticStrength => 'Intensidade tátil';

  @override
  String get feelSounds => 'Sons';

  @override
  String get feelKeySounds => 'Sons das teclas';

  @override
  String get feelKeySoundsBody => 'Cliques para teclas, espaço, apagar e enter';

  @override
  String get feelUseSystemVolume => 'Usar o volume do sistema';

  @override
  String get feelKeySoundVolume => 'Volume dos sons das teclas';

  @override
  String get feelHeight => 'Altura';

  @override
  String get feelPortraitHeight => 'Altura em retrato';

  @override
  String get feelLandscapeHeight => 'Altura em paisagem';

  @override
  String get feelOneHandedFloating => 'Uma mão e flutuante';

  @override
  String get feelOneHandedSide => 'Lado do modo de uma mão';

  @override
  String get feelFloatingKeyboard => 'Teclado flutuante';

  @override
  String get feelFloatingBody => 'Arraste para qualquer parte da tela';

  @override
  String get panelsClipboard => 'Área de transferência';

  @override
  String get panelsClipboardHistory => 'Histórico da área de transferência';

  @override
  String get panelsClipboardHistoryBody =>
      'Guarda o que você copia, criptografado neste celular';

  @override
  String get panelsRecentChip => 'Chip de cópia recente';

  @override
  String get panelsRecentChipBody =>
      'Oferece sua última cópia na barra de sugestões por um minuto';

  @override
  String get panelsKeepUnpinned => 'Manter cópias não fixadas por';

  @override
  String get panelsClipsToKeep => 'Clipes a manter';

  @override
  String get panelsEmoji => 'Emoji';

  @override
  String get emojiSuggestions => 'Sugestões de emoji';

  @override
  String get emojiSuggestionsPanelBody =>
      'Oferece um emoji para algumas palavras na barra de sugestões';

  @override
  String get panelsPasswordsNeverSaved => 'Senhas nunca são salvas';

  @override
  String get panelsSensitiveBody =>
      'Cópias que o Android marca como sensíveis nunca são mantidas.';

  @override
  String get typingCorrections => 'Correções';

  @override
  String get typingAutocorrect => 'Autocorreção';

  @override
  String get typingAutocorrectBody =>
      'Corrige prováveis erros de digitação ao terminar uma palavra';

  @override
  String get typingAutoCapitalise => 'Maiúscula automática';

  @override
  String get typingAutoCapitaliseBody => 'Maiúsculas no início das frases';

  @override
  String get typingDoubleSpace => 'Espaço duplo para ponto';

  @override
  String get typingDoubleSpaceBody =>
      'Dois toques na barra de espaço escrevem “. ”';

  @override
  String get typingSmartPunctuation => 'Pontuação inteligente';

  @override
  String get typingSmartPunctuationBody =>
      'Ajusta espaços ao redor da pontuação e usa aspas locais';

  @override
  String get typingSuggestions => 'Sugestões';

  @override
  String get typingSuggestionsBody => 'Mostra palavras na barra de sugestões';

  @override
  String get typingNextWord => 'Previsão da próxima palavra';

  @override
  String get typingNextWordBody => 'Sugere a palavra que costuma vir depois';

  @override
  String get typingEmojiBody => 'Oferece um emoji para algumas palavras';

  @override
  String get typingHideOffensive => 'Ocultar palavras ofensivas';

  @override
  String get typingHideOffensiveBody =>
      'Nunca sugere, a menos que você os digite por completo';

  @override
  String get typingKeys => 'Teclas';

  @override
  String get typingKeyPopups => 'Pop-ups das teclas';

  @override
  String get typingKeyPopupsBody => 'Aumenta a tecla enquanto você a pressiona';

  @override
  String get typingLongPressDelay => 'Atraso do toque longo';

  @override
  String get typingNumberRow => 'Linha de números';

  @override
  String get typingNumberRowBody => 'Mostra de 0 a 9 acima das letras';

  @override
  String get typingHintLabels => 'Rótulos de dica';

  @override
  String get typingHintLabelsBody =>
      'Pequenos símbolos nas teclas, como acentos';

  @override
  String get typingLowercaseLabels => 'Rótulos em minúsculas';

  @override
  String get typingLowercaseLabelsBody =>
      'Mantém as letras em minúscula com Shift ativado';

  @override
  String get typingSwipe => 'Deslizar';

  @override
  String get typingSwipeTyping => 'Digitação por deslize';

  @override
  String get typingSwipeTypingBody =>
      'Deslize sobre as letras para escrever uma palavra';

  @override
  String get typingShowTrail => 'Mostrar o rastro';

  @override
  String get typingTrailWidth => 'Largura do rastro';

  @override
  String get typingTrailFade => 'Desvanecimento do rastro';

  @override
  String get typingLivePreview => 'Visualização ao vivo';

  @override
  String get typingLivePreviewBody =>
      'Mostra a palavra provável enquanto você desliza';

  @override
  String get typingSpaceMovesCursor => 'A barra de espaço move o cursor';

  @override
  String get typingSpaceMovesCursorBody =>
      'Arraste na barra de espaço para mover o cursor';

  @override
  String get typingSwipeBackspace => 'Deslizar em apagar para excluir palavras';

  @override
  String get typingSwipeBackspaceBody =>
      'Deslize para a esquerda em apagar para selecionar e excluir palavras';

  @override
  String get voiceTyping => 'Digitação por voz';

  @override
  String get voiceTypingBody =>
      'Fale em inglês para digitar. O reconhecimento roda neste celular.';

  @override
  String get voiceRecognition => 'Reconhecimento';

  @override
  String get voiceModelPacksBody =>
      'Instalar ou remover pacotes de voz e tradução';

  @override
  String get voiceAudioStays => 'O áudio fica neste celular e nunca é salvo.';

  @override
  String get voicePackAutomatic => 'Automático';

  @override
  String get voicePackAutomaticSelected => 'Automático (selecionado)';

  @override
  String get voicePack => 'Pacote de voz';

  @override
  String get voiceNoPack =>
      'Nenhum pacote de voz está instalado. Instale um em Pacotes de modelos.';

  @override
  String get voiceLooking => 'Procurando pacotes instalados';

  @override
  String voicePackItem(String name, String size) {
    return '$name · $size';
  }

  @override
  String voicePackItemSelected(String name, String size) {
    return '$name · $size (selecionado)';
  }

  @override
  String megabytes(num count) {
    return '$count MB';
  }

  @override
  String milliseconds(num count) {
    return '$count ms';
  }

  @override
  String dpValue(num count) {
    return '$count dp';
  }

  @override
  String get packsOpenFailed =>
      'O BooBoard não conseguiu abrir o seletor de arquivos.';

  @override
  String packsInstalled(String name) {
    return '$name instalado.';
  }

  @override
  String packsDeleteTitle(String name) {
    return 'Excluir $name?';
  }

  @override
  String get packsDeleteBody =>
      'Os arquivos dele são removidos deste celular. Você pode importar o pacote de novo depois, a partir do arquivo.';

  @override
  String packsDeleted(String name) {
    return '$name excluído.';
  }

  @override
  String packsDeleteFailed(String name) {
    return 'O BooBoard não conseguiu excluir $name. Tente de novo.';
  }

  @override
  String get packsIntro =>
      'Os pacotes são verificados antes de serem instalados. Contêm apenas dados, nunca código.';

  @override
  String get packsImport => 'Importar';

  @override
  String get packsImportTitle => 'Importar um arquivo de pacote';

  @override
  String get packsChecking => 'Verificando e instalando…';

  @override
  String get packsImportBody =>
      'Um arquivo .boopack, por exemplo dos Downloads';

  @override
  String get packsNoVoice => 'Nenhum pacote de voz instalado';

  @override
  String get packsNoVoiceBody =>
      'A digitação por voz precisa de um pacote de voz.';

  @override
  String get packsNoTranslation => 'Nenhum pacote de tradução instalado';

  @override
  String get packsNoTranslationBody =>
      'A tradução precisa de um pacote para cada direção.';

  @override
  String get packsDictionaries => 'Dicionários';

  @override
  String get packsNoDictionary => 'Nenhum pacote de dicionário instalado';

  @override
  String get packsNoDictionaryBody =>
      'A digitação em chinês e japonês precisa de um pacote de dicionário.';

  @override
  String get packsGetTitle => 'Obter pacotes';

  @override
  String get packsExplainTitle =>
      'Os pacotes são arquivos que você mesmo adiciona.';

  @override
  String get packsExplainBody =>
      'Baixe-os na página de lançamentos do projeto em outro aparelho, copie-os para este celular e depois importe.';

  @override
  String get packsCopyLink => 'Copiar o link da página de lançamentos';

  @override
  String get packsPrivateTitle => 'Como os downloads continuam privados';

  @override
  String get packsPrivateBody =>
      'O BooBoard não tem permissão de internet e nunca se conecta. Baixar abre seu navegador, que busca o pacote na publicação do projeto no GitHub. Depois, o BooBoard verifica a assinatura do pacote neste celular antes de instalar qualquer coisa.';

  @override
  String get packsAvailableTitle => 'Pacotes que você pode adicionar';

  @override
  String get packsDownload => 'Baixar';

  @override
  String packsDownloadMeta(String size) {
    return '$size · abre seu navegador';
  }

  @override
  String packsDownloadStarted(String name) {
    return 'Seu navegador está baixando $name. Quando terminar, toque em Importar um arquivo de pacote.';
  }

  @override
  String get packsNoBrowser =>
      'Nenhum navegador pode abrir o link. Copie o link da página de publicações.';

  @override
  String get packsImportCheckedBody =>
      'Escolha o arquivo .boopack baixado. Ele é verificado neste celular e depois instalado.';

  @override
  String get packsAllInstalled =>
      'Todos os pacotes publicados estão instalados.';

  @override
  String get packsLinkCopied => 'Link copiado. Abra-o em outro aparelho.';

  @override
  String get packsPlayTitle => 'Obter pelo Google Play';

  @override
  String get packsPlayNote =>
      'O Google Play baixa estes pacotes, não o BooBoard. O próprio BooBoard nunca usa a rede.';

  @override
  String get packsGet => 'Obter';

  @override
  String get packsStatusNotRequested => 'Ainda não baixado';

  @override
  String get packsStatusWaiting => 'Aguardando Wi-Fi ou dados móveis';

  @override
  String get packsStatusDownloading => 'Baixando pelo Google Play';

  @override
  String get packsStatusInstalling => 'Verificando e instalando';

  @override
  String get packsStatusFailed =>
      'O Google Play não conseguiu entregar. Tente de novo.';

  @override
  String packsOfferMeta(Object size, Object status) {
    return '$size · $status';
  }

  @override
  String get packsVerifyTitle => 'Verificar pacotes instalados';

  @override
  String get packsVerifyBody =>
      'Confere cada arquivo de cada pacote instalado com a lista assinada. Nada é alterado.';

  @override
  String packsVerifyOk(Object count) {
    return '$count pacotes instalados verificados. Todos os arquivos conferem.';
  }

  @override
  String packsVerifyDamaged(Object count) {
    return '$count pacotes instalados têm arquivos danificados ou ausentes. Apague-os e importe de novo.';
  }

  @override
  String get packsVerifyUnavailable =>
      'A verificação de pacotes não está disponível nesta versão do BooBoard.';

  @override
  String get packsVerifyFailed =>
      'O BooBoard não conseguiu verificar os pacotes. Nada foi alterado.';

  @override
  String packsFreeSpace(Object size) {
    return '$size livres neste celular.';
  }

  @override
  String get packsNothingStored => 'Nada guardado ainda.';

  @override
  String packsInstalledUse(String size) {
    return 'Os pacotes instalados usam $size neste celular.';
  }

  @override
  String get packErrorBadSignature =>
      'Este pacote não está assinado para o BooBoard, então nada foi instalado.';

  @override
  String get packErrorBadFormat =>
      'Este arquivo não é um pacote do BooBoard. Nada foi instalado.';

  @override
  String get packErrorTooLarge =>
      'Este pacote é grande demais para este celular.';

  @override
  String get packErrorVersion =>
      'Este pacote precisa de uma versão mais nova do BooBoard.';

  @override
  String get packErrorNoSpace =>
      'Não há espaço livre suficiente para instalar este pacote.';

  @override
  String get packErrorGeneric =>
      'Não foi possível instalar o pacote. Nada foi alterado.';

  @override
  String get translateDefaultPair => 'Par de idiomas padrão';

  @override
  String translatePairName(String from, String to) {
    return '$from → $to';
  }

  @override
  String get translateOffline => 'Tradução offline';

  @override
  String get translateOfflineBody =>
      'Traduz enquanto você digita no teclado e o texto selecionado em qualquer app.';

  @override
  String get translateDefaultPairTile => 'Par padrão';

  @override
  String get translatePackInstalled => 'Pacote instalado';

  @override
  String get translatePackNotInstalled =>
      'Pacote não instalado. Obtenha-o em Pacotes de modelos.';

  @override
  String get translateInstalled => 'Direções instaladas';

  @override
  String get translateInstalledBody =>
      'Cada direção é um pacote, por exemplo inglês → espanhol.';

  @override
  String translatePackMeta(String license, String size) {
    return '$size · $license';
  }

  @override
  String get translateModelPacksBody =>
      'Instalar ou excluir pacotes de tradução';

  @override
  String get translateRunsOnPhone =>
      'A tradução roda neste celular. Nada do que você traduz é salvo.';

  @override
  String get privacyUnlockReason =>
      'Desbloqueie o BooBoard para ver suas configurações e dados';

  @override
  String get privacyLockUnavailable =>
      'O bloqueio do dispositivo não está disponível agora. Tente novamente em instantes.';

  @override
  String get privacyLockedTitle => 'O BooBoard está bloqueado';

  @override
  String get privacyLockedBody =>
      'Desbloqueie com sua digital ou o PIN do dispositivo para continuar.';

  @override
  String get privacyUnlock => 'Desbloquear';

  @override
  String backupSaved(String size) {
    return 'Backup salvo ($size). Guarde bem sua frase-senha.';
  }

  @override
  String get backupUnlockRetrySaved =>
      'Desbloqueie o celular e tente de novo. Nada foi salvo.';

  @override
  String get backupSaveFailed =>
      'Não foi possível salvar o backup. Nada foi alterado.';

  @override
  String get backupCheckFailed =>
      'Não foi possível verificar o arquivo salvo; ele pode estar danificado. Salve o backup novamente como um arquivo novo.';

  @override
  String get backupWrongPassphrase =>
      'Frase-senha incorreta ou arquivo danificado. Nada foi alterado.';

  @override
  String get backupInvalidFile =>
      'Este arquivo não é um backup válido do BooBoard. Nada foi alterado.';

  @override
  String get backupTooLarge =>
      'Este arquivo é grande demais para ser um backup do BooBoard.';

  @override
  String get backupNewerVersion =>
      'Este backup foi feito por uma versão mais nova do BooBoard. Atualize o BooBoard para restaurá-lo.';

  @override
  String get backupBusy =>
      'Feche primeiro a outra janela de arquivos e tente de novo.';

  @override
  String get backupOpenFailed =>
      'Não foi possível abrir o backup. Nada foi alterado.';

  @override
  String get backupEmpty => 'Este backup não tem nada.';

  @override
  String get backupRestoreTitle => 'Restaurar backup';

  @override
  String backupMadeBy(String date, String version) {
    return 'Feito em $date pelo BooBoard $version.';
  }

  @override
  String get backupMerge => 'Mesclar';

  @override
  String get backupMergeBody =>
      'Mantém o que está neste celular e adiciona o que está no backup.';

  @override
  String get backupReplace => 'Substituir';

  @override
  String get backupReplaceBody =>
      'Faz as seções escolhidas corresponderem ao backup. Os dados atuais são apagados antes.';

  @override
  String get commonContinue => 'Continuar';

  @override
  String get backupReplaceTitle => 'Substituir os dados deste celular?';

  @override
  String get backupReplaceConfirm =>
      'As seções escolhidas neste celular são apagadas e substituídas. Não é possível desfazer.';

  @override
  String get backupPrivacyChangesTitle =>
      'Este backup altera suas configurações de privacidade';

  @override
  String get backupPrivacyChangesBody =>
      'Restaurar as configurações vai alterar estas configurações de privacidade neste telefone. Confira antes de continuar.';

  @override
  String backupPrivacyChangeLine(String setting, String from, String to) {
    return '$setting: $from → $to';
  }

  @override
  String get backupStateOn => 'Ativado';

  @override
  String backupAppsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apps',
      one: '1 app',
    );
    return '$_temp0';
  }

  @override
  String get backupRestoreAndChange => 'Restaurar e alterar';

  @override
  String get backupUnlockRetryChanged =>
      'Desbloqueie o celular e tente de novo. Nada foi alterado.';

  @override
  String get backupRestoreFailed =>
      'O BooBoard não conseguiu concluir a restauração. Alguns dados podem não ter sido gravados.';

  @override
  String get restoreNothingNew => 'Nada novo foi restaurado.';

  @override
  String restoreSummary(String items) {
    return 'Restaurado: $items.';
  }

  @override
  String restoreSummarySkipped(String added, String skipped) {
    return '$added Ignorado: $skipped.';
  }

  @override
  String restoreLearnedFor(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count idiomas',
      one: '1 idioma',
    );
    return 'palavras aprendidas em $_temp0';
  }

  @override
  String countFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arquivos',
      one: '1 arquivo',
    );
    return '$_temp0';
  }

  @override
  String countWords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count palavras',
      one: '1 palavra',
    );
    return '$_temp0';
  }

  @override
  String countLanguages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count idiomas',
      one: '1 idioma',
    );
    return '$_temp0';
  }

  @override
  String countShortcuts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count atalhos',
      one: '1 atalho',
    );
    return '$_temp0';
  }

  @override
  String countClipboardItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count itens da área de transferência',
      one: '1 item da área de transferência',
    );
    return '$_temp0';
  }

  @override
  String countThemeFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arquivos de tema',
      one: '1 arquivo de tema',
    );
    return '$_temp0';
  }

  @override
  String countPinnedItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count itens fixados',
      one: '1 item fixado',
    );
    return '$_temp0';
  }

  @override
  String countPacks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pacotes',
      one: '1 pacote',
    );
    return '$_temp0';
  }

  @override
  String countBlockedWords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count palavras bloqueadas',
      one: '1 palavra bloqueada',
    );
    return '$_temp0';
  }

  @override
  String countTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vezes',
      one: '1 vez',
    );
    return '$_temp0';
  }

  @override
  String timeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'há $count minutos',
      one: 'há 1 minuto',
    );
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'há $count horas',
      one: 'há 1 hora',
    );
    return '$_temp0';
  }

  @override
  String timeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'há $count dias',
      one: 'há 1 dia',
    );
    return '$_temp0';
  }

  @override
  String get timeJustNow => 'agora mesmo';

  @override
  String get languagePortuguese => 'Português';

  @override
  String packMeta(String languages, String license, String size) {
    return '$languages · $size · $license';
  }

  @override
  String privacyLearnedWordsTitle(String language) {
    return 'Palavras aprendidas ($language)';
  }

  @override
  String privacyClearLanguageTitle(String language) {
    return 'Apagar as palavras de $language?';
  }

  @override
  String get privacyClearLanguageBody =>
      'Isso apaga todas as palavras aprendidas neste idioma e as palavras bloqueadas. Não é possível desfazer.';

  @override
  String get privacyClear => 'Limpar';

  @override
  String get privacySaveFailed =>
      'Não foi possível salvar a alteração. Tente novamente.';

  @override
  String get privacyCouldNotReadWords =>
      'O BooBoard não conseguiu ler estas palavras.';

  @override
  String get privacyCannotReadWordsNow =>
      'O BooBoard não pode ler estas palavras agora. Desbloqueie o celular e tente de novo.';

  @override
  String get privacyNoWordsLanguage =>
      'Nenhuma palavra aprendida neste idioma ainda. O BooBoard aprende uma palavra depois que você a digita algumas vezes.';

  @override
  String privacyBlockedWordsTooltip(num count) {
    return 'Palavras bloqueadas ($count)';
  }

  @override
  String get privacySortTooltip => 'Ordenar';

  @override
  String get privacySortMostUsed => 'Mais usadas primeiro';

  @override
  String get privacySortAZ => 'De A a Z';

  @override
  String get privacyMoreTooltip => 'Mais';

  @override
  String get privacyClearThisLanguage => 'Limpar este idioma';

  @override
  String get privacySearchWords => 'Pesquisar palavras';

  @override
  String privacyWordsSummary(String blocked, String words) {
    return '$words · $blocked';
  }

  @override
  String get privacyNoWordsYet => 'Nenhuma palavra ainda.';

  @override
  String privacyNoWordsMatch(String query) {
    return 'Nenhuma palavra corresponde a \"$query\".';
  }

  @override
  String get privacyNeverSuggested => 'Nunca sugeridas';

  @override
  String get privacyBlockedExplain =>
      'O BooBoard não vai sugerir nem corrigir para estas palavras.';

  @override
  String get privacyNoBlockedWords => 'Nenhuma palavra bloqueada.';

  @override
  String get privacyAllowAgain => 'Permitir de novo';

  @override
  String privacyWordLastUsed(int count, String when) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vezes',
      one: 'uma vez',
    );
    return 'Digitada $_temp0 · última vez $when';
  }

  @override
  String privacyWordNotYetSuggested(String when) {
    return 'Digitada uma vez até agora, ainda não sugerida · última vez $when';
  }

  @override
  String get privacyToday => 'hoje';

  @override
  String get privacyYesterday => 'ontem';

  @override
  String privacyActionsFor(String word) {
    return 'Ações para $word';
  }

  @override
  String get privacyForgetWord => 'Esquecer esta palavra';

  @override
  String get privacyNeverSuggestWord => 'Nunca sugerir esta palavra';

  @override
  String get privacyTryAgain => 'Tentar de novo';

  @override
  String get privacyCenterLoadFailed =>
      'O BooBoard não conseguiu ler seus dados de privacidade. Tente mais tarde.';

  @override
  String get privacyDevBuildNetwork =>
      'Esta versão pede acesso à internet. O BooBoard nunca deveria fazer isso. Por favor, informe.';

  @override
  String get privacyNoInternetPermission =>
      'O BooBoard não tem permissão de internet. Ele não pode enviar nada.';

  @override
  String get privacyDevBuildNote =>
      'Esta é uma versão de desenvolvimento. Sua permissão de rede é só para ferramentas de desenvolvimento.';

  @override
  String get privacyDevBuildShort =>
      'Versão de desenvolvimento. O BooBoard continua sem permissão de internet.';

  @override
  String privacyStorageSize(String size, String when) {
    return '$size · alterado $when';
  }

  @override
  String get privacyCustomThemes => 'Temas personalizados';

  @override
  String get privacyNoPacks =>
      'Nenhum instalado. Pacotes de voz e tradução aparecem aqui.';

  @override
  String privacyPacksSize(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pacotes',
      one: '1 pacote',
    );
    return '$_temp0 · $size';
  }

  @override
  String get privacyWhatBooBoardStores => 'O que o BooBoard armazena';

  @override
  String get privacyShowsSizesOnly =>
      'O BooBoard mostra aqui só tamanhos, nunca o conteúdo. Os tamanhos incluem a última cópia salva, que protege seus dados se um salvamento for interrompido.';

  @override
  String get privacyTypingPrivacy => 'Privacidade ao digitar';

  @override
  String get privacyLearnNewWords => 'Aprender palavras novas';

  @override
  String get privacyLearnNewWordsBody =>
      'Aprende palavras e frases do que você digita. Nunca em campos de senha ou no modo anônimo.';

  @override
  String get privacyIncognito => 'Anônimo';

  @override
  String get privacyIncognitoBody =>
      'Não aprende nem lembra de nada enquanto estiver ativo. Abas anônimas do navegador ativam isso sozinhas.';

  @override
  String get privacyHideScreenshots => 'Ocultar de capturas de tela';

  @override
  String get privacyHideScreenshotsBody =>
      'Impede capturas e gravações de tela do teclado em todos os apps. Campos de senha estão sempre ocultos.';

  @override
  String get privacyAutoOffApps => 'Desativado automaticamente nestes apps';

  @override
  String get privacyAutoOffAppsBody =>
      'O BooBoard guarda nomes de apps só para preencher esta lista. Eles são criptografados, nunca registrados no anônimo, e você pode limpá-los abaixo.';

  @override
  String get privacyNoAppsYet => 'Nenhum app ainda';

  @override
  String get privacyNoAppsYetBody =>
      'Os apps onde você digita aparecerão aqui.';

  @override
  String get privacyAlwaysIncognitoApps => 'Apps sempre anônimos';

  @override
  String get privacyPersonalShortcuts => 'Atalhos pessoais';

  @override
  String get privacyOfferShortcuts => 'Oferecer atalhos';

  @override
  String get privacyOfferShortcutsBody =>
      'Mostra suas abreviações, como \"omw\", como primeira sugestão.';

  @override
  String get privacyEditShortcuts => 'Editar atalhos';

  @override
  String get privacyNoShortcutsYet => 'Nenhum ainda';

  @override
  String get privacyLearnedAndClipboard =>
      'Palavras aprendidas e área de transferência';

  @override
  String get privacyNoWordsLearnedYet => 'Nenhuma palavra aprendida ainda';

  @override
  String get privacyWordsLearnedBody =>
      'As palavras que você digita são aprendidas aqui depois que o BooBoard as viu algumas vezes.';

  @override
  String privacyReviewWords(String when) {
    return 'Revise, remova ou bloqueie palavras · $when';
  }

  @override
  String get privacyClipboardHistoryEmpty =>
      'O histórico está vazio. Altere as configurações da área de transferência em Painéis.';

  @override
  String privacyClipboardInHistory(String size) {
    return '$size no histórico. Altere as configurações da área de transferência em Painéis.';
  }

  @override
  String get privacyAppLock => 'Bloqueio do app';

  @override
  String get privacyLockBooBoard => 'Bloquear o BooBoard';

  @override
  String get privacyLockBooBoardBody =>
      'Pede sua digital ou o PIN do dispositivo ao abrir o app ou depois de ficar em segundo plano.';

  @override
  String get privacyLockAfter => 'Bloquear após';

  @override
  String get privacySetScreenLockFirst => 'Primeiro defina um bloqueio de tela';

  @override
  String get privacySetScreenLockBody =>
      'O bloqueio do app usa sua digital ou o PIN do dispositivo. Defina um PIN, padrão ou senha nas configurações de segurança do Android e volte.';

  @override
  String get privacyTurnOnAppLockReason =>
      'Ativar o bloqueio do app para o BooBoard';

  @override
  String get privacyNotAvailable => 'Não disponível agora';

  @override
  String get privacyNotAvailableBody =>
      'Não foi possível usar o bloqueio do dispositivo. O bloqueio do app continua desativado.';

  @override
  String get privacyBackupTitle => 'Backup';

  @override
  String get privacyBackupRestore => 'Backup e restauração';

  @override
  String get privacyBackupRestoreBody =>
      'Um arquivo .boobackup criptografado que você guarda. Você escolhe o que vai nele.';

  @override
  String get privacyDeleteData => 'Excluir dados';

  @override
  String get privacyEraseEverything => 'Apagar tudo';

  @override
  String get privacyEraseEverythingBody =>
      'Todas as categorias acima, seus temas personalizados e a chave que os protege.';

  @override
  String privacyDeleteTitle(String category) {
    return 'Excluir $category?';
  }

  @override
  String get privacyEraseTitle => 'Apagar tudo?';

  @override
  String get privacyWillDelete => 'Isto excluirá permanentemente:';

  @override
  String get privacyResetSettings =>
      'Também redefinir todas as configurações para o padrão';

  @override
  String get privacyCannotBeUndone => 'Não é possível desfazer.';

  @override
  String get privacyDeleted => 'Excluído.';

  @override
  String get privacyDeleteFailed =>
      'O BooBoard não conseguiu excluir tudo. Tente novamente.';

  @override
  String get privacyOk => 'OK';

  @override
  String get backupMakeTitle => 'Fazer um backup';

  @override
  String get backupIncludeImages => 'Incluir imagens de fundo';

  @override
  String get backupPhotosLarger => 'As fotos deixam o arquivo bem maior.';

  @override
  String get backupCreateButton => 'Criar backup criptografado';

  @override
  String get backupRestoreSection => 'Restaurar';

  @override
  String get backupRestoreFromFile => 'Restaurar de um arquivo de backup';

  @override
  String get backupRestoreFromFileBody =>
      'Abra um arquivo .boobackup, veja o que há nele e depois combine ou substitua.';

  @override
  String get backupChoosePassphrase => 'Escolha uma frase-senha';

  @override
  String get backupEnterPassphrase => 'Digite a frase-senha';

  @override
  String get backupWriteItDown =>
      'Anote em um lugar seguro. Uma frase-senha perdida não pode ser recuperada.';

  @override
  String get backupPassphrase => 'Frase-senha';

  @override
  String get backupTypeAgain => 'Digite novamente';

  @override
  String get backupMismatch => 'As frases-senha não coincidem';

  @override
  String backupStrength(String strength) {
    return 'Força da frase-senha: $strength';
  }

  @override
  String get strengthTooShort => 'Use pelo menos 8 caracteres';

  @override
  String get strengthWeak => 'Fraca';

  @override
  String get strengthFair => 'Razoável';

  @override
  String get strengthGood => 'Boa';

  @override
  String get strengthStrong => 'Forte';

  @override
  String get backupOpen => 'Abrir';

  @override
  String get backupNothingYet => 'Nada ainda';

  @override
  String get backupSettingsSummary =>
      'Tema, idiomas, digitação e opções de privacidade';

  @override
  String backupLearnedSummary(String languages, String words) {
    return '$words em $languages';
  }

  @override
  String backupPinnedOff(String items) {
    return '$items. Desativado, a menos que você ative.';
  }

  @override
  String backupAlreadyHere(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count atalhos já existem',
      one: '1 atalho já existe',
    );
    return '$_temp0';
  }

  @override
  String backupThemesAlreadyHere(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arquivos de tema já existem',
      one: '1 arquivo de tema já existe',
    );
    return '$_temp0';
  }

  @override
  String get backupClipboardKept =>
      'área de transferência mantida (layout desconhecido)';

  @override
  String get backupEmojiKept => 'emojis recentes mantidos';

  @override
  String get backupSettingsApplied => 'configurações';

  @override
  String backupLearnedAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count idiomas',
      one: '1 idioma',
    );
    return 'palavras aprendidas em $_temp0';
  }

  @override
  String shortcutDeleteTitle(String trigger) {
    return 'Excluir \"$trigger\"?';
  }

  @override
  String get shortcutDeleteBody =>
      'Isso remove o atalho. Não é possível desfazer.';

  @override
  String get shortcutAdd => 'Adicionar atalho';

  @override
  String get shortcutSearch => 'Pesquisar atalhos';

  @override
  String get shortcutNoMatch => 'Nenhum atalho corresponde à sua busca.';

  @override
  String shortcutDeleteTooltip(String trigger) {
    return 'Excluir $trigger';
  }

  @override
  String get shortcutNoneYet => 'Nenhum atalho ainda';

  @override
  String get shortcutExplain =>
      'Um atalho transforma uma abreviação em um texto mais longo. Exemplos:';

  @override
  String shortcutExamples(String first, String second) {
    return '$first\n$second';
  }

  @override
  String get shortcutEncrypted =>
      'Os atalhos são criptografados neste celular, como suas palavras aprendidas.';

  @override
  String get shortcutNew => 'Novo atalho';

  @override
  String get shortcutEdit => 'Editar atalho';

  @override
  String get shortcutShortForm => 'Abreviação';

  @override
  String get shortcutExpandsTo => 'Expande para';

  @override
  String get privacyMascotLabel => 'Mascote de privacidade do BooBoard';

  @override
  String get privacyStoredEmoji => 'Emojis recentes';

  @override
  String get privacyStoredApps => 'Lista de apps';

  @override
  String get privacyStoredOther => 'Outros dados armazenados';

  @override
  String privacyUnitBytes(num count) {
    return '$count B';
  }

  @override
  String privacyUnitKilobytes(num count) {
    return '$count KB';
  }

  @override
  String privacyUnitMegabytes(num count) {
    return '$count MB';
  }

  @override
  String get shortcutProblemEmptyTrigger =>
      'Digite a abreviação que você quer expandir.';

  @override
  String shortcutProblemTriggerTooLong(num count) {
    return 'A abreviação pode ter no máximo $count caracteres.';
  }

  @override
  String get shortcutProblemTriggerCharacters =>
      'Use apenas letras, números e apóstrofos na abreviação.';

  @override
  String get shortcutProblemEmptyExpansion =>
      'Digite o que a abreviação deve expandir.';

  @override
  String shortcutProblemExpansionTooLong(num count) {
    return 'A expansão pode ter no máximo $count caracteres.';
  }

  @override
  String get shortcutProblemDuplicate =>
      'Você já tem um atalho com esta abreviação.';

  @override
  String shortcutProblemTooMany(num count) {
    return 'Você pode manter no máximo $count atalhos.';
  }

  @override
  String get onboardingWelcomeTitle => 'Oi, eu sou o *Boo.*';

  @override
  String get onboardingWelcomeBody =>
      'Sou um teclado que nunca fica online. O que você digita fica neste celular, trancado.';

  @override
  String get onboardingWelcomeStart => 'Vamos configurar';

  @override
  String get onboardingMascotLabel => 'Boo, o fantasma do BooBoard';

  @override
  String get onboardingFactNoInternet => 'Sem permissão de internet';

  @override
  String get onboardingFactOpenSource => 'Código aberto';

  @override
  String get onboardingFactOpenSourceBody =>
      'Qualquer pessoa pode ler o código e conferir.';

  @override
  String get onboardingDemoKeyboards => 'Apps de teclado';

  @override
  String get onboardingDemoOtherKeyboard => 'Outro teclado';

  @override
  String get onboardingDemoAttention => 'Atenção';

  @override
  String get onboardingDemoAttentionBody =>
      'Este teclado pode coletar todo o texto que você digita…';

  @override
  String get onboardingDemoOk => 'OK';

  @override
  String get onboardingDemoChooseInput => 'Escolher método de entrada';

  @override
  String get onboardingDemoSwitchOn => 'Ativar';

  @override
  String get onboardingDemoTapOk => 'OK e OK';

  @override
  String get onboardingDemoComeBack => 'Volte';

  @override
  String get onboardingDemoPick => 'Escolha BooBoard';

  @override
  String get onboardingDemoStartTyping => 'Comece a digitar';

  @override
  String get onboardingDemoRebootNote =>
      'Observação: depois de reiniciar, este app só pode ser iniciado quando você desbloquear o smartphone';

  @override
  String get onboardingDemoChatIn => 'Até às 7?';

  @override
  String get onboardingDemoChatOut => 'Estou indo';

  @override
  String get onboardingDemoMessage => 'Mensagem';

  @override
  String get onboardingShh => 'psiu';

  @override
  String get onboardingTryMe => 'Me teste';

  @override
  String get onboardingTurnOnTitle => 'Ative o *BooBoard*';

  @override
  String get onboardingTurnOnBody =>
      'Ative-o na lista de teclados do Android e volte. Esta página percebe sozinha.';

  @override
  String get onboardingKeyboardOn => 'BooBoard está ativado';

  @override
  String get onboardingKeyboardOff => 'Ainda não ativado';

  @override
  String get onboardingOpenKeyboardSettings => 'Abrir configurações do teclado';

  @override
  String get onboardingSwitchTitle => 'Deixe-o *seu*';

  @override
  String get onboardingSwitchBody =>
      'Escolha o BooBoard na lista curta do Android. Você pode trocar de volta quando quiser.';

  @override
  String get onboardingKeyboardIsYours => 'BooBoard é seu teclado';

  @override
  String get onboardingKeyboardNotYours => 'Ainda não é seu teclado';

  @override
  String get onboardingTurnOnFirst => 'Ative-o primeiro';

  @override
  String get onboardingChooseKeyboard => 'Escolher teclado';

  @override
  String get onboardingCheckingPermissions =>
      'Verificando as permissões do app…';

  @override
  String get onboardingDebugInternet =>
      'Esta versão de depuração pode acessar a internet. Builds de depuração têm essa permissão só para desenvolvimento.';

  @override
  String get onboardingReleaseInternet =>
      'Esta versão pode acessar a internet.';

  @override
  String get onboardingNoInternet =>
      'O BooBoard não tem permissão de internet, então não pode enviar nada a lugar nenhum.';

  @override
  String get onboardingWarningTitle => 'Sobre aquele *aviso*';

  @override
  String get onboardingWarningBody =>
      'O Android mostra isso para todo teclado, porque um teclado poderia enviar o que você digita para a internet. O BooBoard não pode.';

  @override
  String get onboardingInternetAccess => 'Acesso à internet';

  @override
  String get onboardingEverythingHere => 'Fica neste celular';

  @override
  String get onboardingEverythingHereBody =>
      'Palavras aprendidas, área de transferência e ajustes são criptografados com uma chave no Android Keystore.';

  @override
  String get onboardingLanguagesTitle => 'Seus *idiomas*';

  @override
  String get onboardingThemeTitle => 'Tema';

  @override
  String get onboardingTryTyping => 'Digite uma frase';

  @override
  String get onboardingTrySwipe => 'Deslize uma palavra, letra a letra';

  @override
  String get onboardingTryAccents => 'Segure uma letra para ver acentos';

  @override
  String get onboardingTryTitle => 'Experimente *agora*';

  @override
  String get onboardingTryField => 'Digite algo aqui';

  @override
  String get onboardingAllSetTitle => 'Tudo *pronto.*';

  @override
  String get onboardingAllSetBody =>
      'Idiomas, digitação, temas e mais estão nos Ajustes quando você quiser.';

  @override
  String onboardingStepOf(String step, String total) {
    return 'Etapa $step de $total';
  }

  @override
  String get onboardingBack => 'Voltar';

  @override
  String get onboardingNext => 'Próximo';

  @override
  String get onboardingDone => 'Concluído';

  @override
  String get onboardingSearchLanguages => 'Pesquisar idiomas';

  @override
  String onboardingSelected(String languages) {
    return 'Selecionados: $languages';
  }

  @override
  String get onboardingNoLanguageMatch =>
      'Nenhum idioma corresponde a essa busca.';

  @override
  String get themeCreate => 'Criar tema';

  @override
  String themeSelectedLabel(String name) {
    return '$name, selecionado';
  }

  @override
  String themeCardOptions(String name) {
    return 'Opções de $name';
  }

  @override
  String get themeEdit => 'Editar';

  @override
  String get themeDuplicate => 'Duplicar';

  @override
  String get themeRename => 'Renomear';

  @override
  String get themeDeleteAction => 'Excluir';

  @override
  String get themeTryTyping => 'Teste digitando';

  @override
  String get themeTryLabel => 'Digite aqui para testar o tema';

  @override
  String get themeTryHelper =>
      'O teclado aparece aqui quando o BooBoard está selecionado.';

  @override
  String get themeRenameTitle => 'Renomear tema';

  @override
  String get themeNameField => 'Nome';

  @override
  String get themeEditTitle => 'Editar tema';

  @override
  String get themeNewTitle => 'Novo tema';

  @override
  String get themeEditorTitle => 'Tema';

  @override
  String get themeOpenFailed => 'Não foi possível abrir este tema.';

  @override
  String get themeSaveFailed => 'Não foi possível salvar o tema.';

  @override
  String get themePhotoPickerFailed =>
      'Não foi possível abrir o seletor de fotos.';

  @override
  String get themeDiscardTitle => 'Descartar alterações?';

  @override
  String get themeDiscardBody => 'As alterações neste tema serão perdidas.';

  @override
  String get themeKeepEditing => 'Continuar editando';

  @override
  String get themeDiscard => 'Descartar';

  @override
  String get themeSave => 'Salvar';

  @override
  String get themeNameRequired => 'Um nome é obrigatório';

  @override
  String get themeNameLabel => 'Nome do tema';

  @override
  String get themeDefaultName => 'Meu tema';

  @override
  String get themeSectionName => 'Nome';

  @override
  String get themeSectionLook => 'Aparência';

  @override
  String get themeDarkMode => 'Modo escuro';

  @override
  String get themeChoiceSystem => 'Sistema';

  @override
  String get themeChoiceLight => 'Claro';

  @override
  String get themeChoiceDark => 'Escuro';

  @override
  String get themePureBlack => 'Preto puro';

  @override
  String get themePureBlackBody => 'Fundo preto';

  @override
  String get themePureBlackOnlyDark => 'Somente no modo escuro';

  @override
  String get themeGalleryPureBlackDark => 'Fundo preto no modo escuro';

  @override
  String get themeContrast => 'Contraste';

  @override
  String get themeChoiceStandard => 'Padrão';

  @override
  String get themeChoiceMedium => 'Médio';

  @override
  String get themeChoiceHigh => 'Alto';

  @override
  String get themeKeyboardHeight => 'Altura do teclado';

  @override
  String get themeSectionColours => 'Cores';

  @override
  String get themeSource => 'Origem';

  @override
  String get themeSourceWallpaper => 'Papel de parede';

  @override
  String get themeSourceSeed => 'Cor base';

  @override
  String get themeSourcePerRole => 'Por função';

  @override
  String get themeWallpaperNeedsAndroid12 =>
      'As cores do papel de parede precisam do Android 12 ou mais recente.';

  @override
  String get themeSeedColour => 'Cor base';

  @override
  String get themeScheme => 'Esquema';

  @override
  String get themeColourRoles => 'Funções de cor';

  @override
  String themeEditingColours(String mode) {
    String _temp0 = intl.Intl.selectLogic(mode, {
      'dark': 'Editando as cores escuras',
      'other': 'Editando as cores claras',
    });
    return '$_temp0';
  }

  @override
  String get themeResetRoles => 'Redefinir todas as funções';

  @override
  String get themeKeys => 'Teclas';

  @override
  String get themeShape => 'Forma';

  @override
  String get themeShapePill => 'Pílula';

  @override
  String get themeShapeRounded => 'Arredondada';

  @override
  String get themeShapeSquare => 'Quadrada';

  @override
  String get themeKeyBorders => 'Bordas das teclas';

  @override
  String get themeBorderWidth => 'Largura da borda';

  @override
  String get themeKeyGap => 'Espaço entre teclas';

  @override
  String get themeFontWeight => 'Espessura da fonte';

  @override
  String get themeFontSize => 'Tamanho da fonte';

  @override
  String get themeHintCharacters => 'Caracteres de dica';

  @override
  String get themeHintCharactersBody =>
      'Caracteres pequenos ao pressionar por muito tempo';

  @override
  String get themeBackground => 'Fundo';

  @override
  String get themeBackgroundType => 'Tipo';

  @override
  String get themeTypeSolid => 'Sólido';

  @override
  String get themeTypeGradient => 'Gradiente';

  @override
  String get themeTypePhoto => 'Foto';

  @override
  String get themeNoPhotoYet =>
      'Nenhuma foto ainda. Escolha uma para recortá-la ao teclado.';

  @override
  String get themeChoosePhoto => 'Escolher foto';

  @override
  String get themeEditCrop => 'Editar recorte e desfoque';

  @override
  String get themeDim => 'Escurecer';

  @override
  String get themeSectionPopups => 'Pop-ups e rastro';

  @override
  String get themeSolidPopups => 'Pop-ups sólidos';

  @override
  String get themeSolidPopupsBodyWallpaper =>
      'Não com cores do papel de parede';

  @override
  String get themeSolidPopupsBodyPrimary => 'Pop-ups na cor primária';

  @override
  String get themeSwipeTrail => 'Rastro do deslize';

  @override
  String get themeTrailWidth => 'Largura do rastro';

  @override
  String get themeTrailFade => 'Desvanecimento do rastro';

  @override
  String get themeTrailInstant => 'Instantâneo';

  @override
  String get themeTrailColours => 'Cores do rastro';

  @override
  String get themeTrailStart => 'Início';

  @override
  String get themeTrailEnd => 'Fim';

  @override
  String get themeTrailStartTitle => 'Início do rastro';

  @override
  String get themeTrailEndTitle => 'Fim do rastro';

  @override
  String get themeAutomatic => 'Automático';

  @override
  String get themeSectionMotion => 'Movimento';

  @override
  String get themeKeyPressAnimation => 'Animação ao pressionar tecla';

  @override
  String get themeReduceMotion =>
      '«Remover animações» está ativado nas configurações do sistema, então as teclas não são animadas.';

  @override
  String get themeMotionOff => 'Desativado';

  @override
  String get themeMotionSubtle => 'Sutil';

  @override
  String get themeMotionStandard => 'Padrão';

  @override
  String get themeMotionBouncy => 'Animado';

  @override
  String get themeSchemeTonalSpot => 'Ponto tonal';

  @override
  String get themeSchemeVibrant => 'Vibrante';

  @override
  String get themeSchemeExpressive => 'Expressivo';

  @override
  String get themeSchemeFidelity => 'Fidelidade';

  @override
  String get themeSchemeContent => 'Conteúdo';

  @override
  String get themeSchemeMonochrome => 'Monocromático';

  @override
  String get themeSchemeNeutral => 'Neutro';

  @override
  String get themeSchemeRainbow => 'Arco-íris';

  @override
  String get themeSchemeFruitSalad => 'Salada de frutas';

  @override
  String themeCustomColourHex(String hex) {
    return 'Cor personalizada #$hex';
  }

  @override
  String get themeCustomColour => 'Cor personalizada';

  @override
  String themeSwatchLabel(String hex, String label) {
    return 'Cor $label, #$hex';
  }

  @override
  String themeUseSchemeColour(String label) {
    return 'Usar a cor do esquema para $label';
  }

  @override
  String get themeFromScheme => 'Do esquema';

  @override
  String get themeOverridden => 'Definido';

  @override
  String themeStopLabel(String n) {
    return 'Parada $n';
  }

  @override
  String themePickStopTitle(String n) {
    return 'Parada $n';
  }

  @override
  String get themeAddStop => 'Adicionar parada';

  @override
  String get themeRemoveStop => 'Remover parada';

  @override
  String get themeAngle => 'Ângulo';

  @override
  String get themeUseSchemeTooltipLabel => 'Usar a cor do esquema';

  @override
  String get themeCropTitle => 'Recortar foto';

  @override
  String get themeUsePhoto => 'Usar foto';

  @override
  String get themeCropSaveFailed => 'Não foi possível salvar a foto.';

  @override
  String get themeCropSemantics =>
      'Recorte de foto. Arraste para mover a foto e belisque ou use o controle de zoom para ampliar.';

  @override
  String get themeCropZoom => 'Zoom';

  @override
  String get themeCropBlur => 'Desfoque';

  @override
  String get themeCropBlurOff => 'Desativado';

  @override
  String get themeCropNote =>
      'O desfoque é salvo na imagem. O escurecimento é definido no editor e aplicado ao vivo.';

  @override
  String get themeHexLabel => 'Hex';

  @override
  String get themeHexError => 'Use seis dígitos hexadecimais, como F5B700';

  @override
  String get themeHue => 'Matiz';

  @override
  String get themeSaturation => 'Saturação';

  @override
  String get themeBrightness => 'Brilho';

  @override
  String get themePickShadeHint => 'Escolha um tom e toque em Usar.';

  @override
  String get themePickColourUse => 'Usar';

  @override
  String get themeCopySuffix => 'cópia';

  @override
  String themeCopyName(String name) {
    return 'Cópia de $name';
  }

  @override
  String themeDeleteTitle(String name) {
    return 'Excluir \"$name\"?';
  }

  @override
  String get themeDeleteSelectedBody =>
      'Este tema está selecionado. O BooBoard Dynamic será usado no lugar. Não é possível desfazer.';

  @override
  String get themeDeleteBody => 'Não é possível desfazer.';

  @override
  String get themeDeleteFailed => 'Não foi possível excluir o tema.';

  @override
  String get themeRenameFailed => 'Não foi possível renomear o tema.';

  @override
  String get themeDuplicateFailed => 'Não foi possível copiar o tema.';

  @override
  String get themeSettingFailed => 'Não foi possível salvar a configuração.';

  @override
  String get themeSystemColoursUnavailable =>
      'As cores do sistema não estão disponíveis.';

  @override
  String get themeBooBoardDynamicFollows =>
      'O BooBoard Dynamic segue seu papel de parede';

  @override
  String get themeBooBoardDynamicBody =>
      'Suas cores são atualizadas quando o papel de parede muda';

  @override
  String get themeSectionPresets => 'Predefinições';

  @override
  String get themeSectionMyThemes => 'Meus temas';

  @override
  String get themeSectionTry => 'Teste digitando';

  @override
  String get themeAppearance => 'Aparência';

  @override
  String get themesTitle => 'Temas';

  @override
  String privacyThemesSize(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arquivos de tema',
      one: '1 arquivo de tema',
    );
    return '$_temp0 · $size';
  }

  @override
  String get backupUnlockToSeeCount =>
      'Desbloqueie o celular para ver a contagem';

  @override
  String get shortcutHelp =>
      'Um atalho transforma uma abreviação em um texto mais longo. Exemplos:\nomw → on my way\naddr → your address';

  @override
  String privacyStoredLearned(String language) {
    return 'Palavras aprendidas ($language)';
  }

  @override
  String get settingsComingLater => 'Disponível em uma atualização futura';

  @override
  String get backupExplainer =>
      'Um backup é um único arquivo, criptografado com uma frase-senha que você escolhe. Só essa frase o abre. Se você esquecer a frase-senha, ninguém consegue recuperar o backup, nem mesmo o BooBoard.';

  @override
  String privacyCategoryLine(String detail, String title) {
    return '$title: $detail';
  }

  @override
  String get shortcutShortFormHint => 'omw';

  @override
  String get shortcutExpansionHint => 'a caminho';

  @override
  String get durationMinutes15 => '15 minutos';

  @override
  String get durationHour => '1 hora';

  @override
  String get durationDay => '1 dia';

  @override
  String get durationWeek => '1 semana';

  @override
  String get onboardingCloseSetup => 'Fechar configuração';

  @override
  String get packsCouldNotRead => 'O BooBoard não conseguiu ler seus pacotes';

  @override
  String packsDeleteTooltip(String name) {
    return 'Excluir $name';
  }

  @override
  String get privacyNothingStored => 'Nada guardado ainda';

  @override
  String privacyRemoveAppTooltip(String app) {
    return 'Remover $app da lista';
  }

  @override
  String get chineseTitle => 'Chinês';

  @override
  String get chineseTraditional => 'Caracteres tradicionais';

  @override
  String get chineseTraditionalBody =>
      'Mostra os candidatos em caracteres tradicionais (padrão de Taiwan).';

  @override
  String get chineseFuzzy => 'Pinyin aproximado';

  @override
  String get chineseFuzzyBody =>
      'Aceita também z e zh, c e ch, s e sh, n e l, an e ang, en e eng, in e ing.';

  @override
  String get cjkDictionary => 'Dicionário';

  @override
  String get chineseClearPhrases => 'Apagar frases aprendidas';

  @override
  String get chineseClearPhrasesBody =>
      'Esquece as palavras que você escolheu. O dicionário permanece.';

  @override
  String get chineseFooter =>
      'O chinês é digitado neste telefone. As frases aprendidas são criptografadas e nunca saem dele.';

  @override
  String get chineseClearTitle => 'Apagar as frases aprendidas?';

  @override
  String get chineseClearBody =>
      'As palavras escolhidas para o chinês serão removidas. Isso não pode ser desfeito.';

  @override
  String get cjkClear => 'Apagar';

  @override
  String get chinesePhrasesCleared => 'Frases aprendidas apagadas';

  @override
  String get chineseLooking => 'Procurando o dicionário';

  @override
  String get chineseDictName => 'Dicionário de chinês';

  @override
  String get chinesePackMissing =>
      'Não instalado. A digitação em chinês precisa dele; instale em Pacotes de modelos.';

  @override
  String chinesePackInstalled(String license) {
    return 'Instalado. $license';
  }

  @override
  String get japaneseTitle => 'Japonês';

  @override
  String get japaneseLayout => 'Layout';

  @override
  String get japaneseLayout12 => '12 teclas (deslizar)';

  @override
  String get japaneseLayoutRomaji => 'Romaji (QWERTY)';

  @override
  String get japaneseTyping => 'Digitação';

  @override
  String get japaneseFlickOnly => 'Somente deslizar';

  @override
  String get japaneseFlickOnlyBody =>
      'Sem toques múltiplos: tocar あ duas vezes digita ああ, não い';

  @override
  String get japaneseHalfWidth => 'Espaço de largura normal';

  @override
  String get japaneseHalfWidthBody =>
      'O espaço digita um espaço normal quando nada está sendo digitado. Desativado, digita um espaço de largura total.';

  @override
  String get japaneseDictPack => 'Pacote de dicionário';

  @override
  String get japaneseChecking => 'Verificando...';

  @override
  String japaneseInstalled(String name) {
    return '$name está instalado. A conversão para kanji está ativada.';
  }

  @override
  String get japaneseNotInstalled =>
      'Não instalado. O kana ainda é digitado; o kanji precisa do pacote.';

  @override
  String get japaneseClearWords => 'Apagar palavras aprendidas';

  @override
  String get japaneseClearWordsBody =>
      'Esquece as palavras japonesas que você escolheu. Armazenadas criptografadas neste telefone.';

  @override
  String get japaneseClearTitle => 'Apagar as palavras japonesas aprendidas?';

  @override
  String get japaneseClearBody =>
      'Todas as palavras japonesas escolhidas serão apagadas. Isso não pode ser desfeito.';

  @override
  String get privacyStoredChinesePhrases => 'Frases em chinês';

  @override
  String get privacyStoredJapaneseWords => 'Palavras em japonês';
}
