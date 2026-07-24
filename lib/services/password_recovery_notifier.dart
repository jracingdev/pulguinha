import 'dart:async';

import 'package:flutter/foundation.dart';

/// Guarda o estado do fluxo de recuperação de senha do Supabase Auth.
///
/// O evento `PASSWORD_RECOVERY` pode chegar antes da árvore de widgets montar
/// (deep link que abre o app), por isso o estado fica retido aqui até a tela de
/// nova senha ser exibida.
class PasswordRecoveryNotifier extends ChangeNotifier {
  PasswordRecoveryNotifier._();

  static final PasswordRecoveryNotifier instance = PasswordRecoveryNotifier._();

  static const _limiteValidacao = Duration(seconds: 12);

  bool _ativo = false;
  bool _comSessao = false;
  bool _validando = false;
  Timer? _timeout;

  /// Verdadeiro quando o app deve mostrar a tela de definição de nova senha.
  bool get ativo => _ativo;

  /// Verdadeiro quando o Supabase já validou o link e abriu a sessão de recovery.
  bool get comSessao => _comSessao;

  /// Link detectado na URL, aguardando o Supabase validar o token.
  bool get validando => _validando;

  /// Chamado ao receber `AuthChangeEvent.passwordRecovery`.
  void ativarComSessao() {
    _timeout?.cancel();
    if (_ativo && _comSessao) return;
    _ativo = true;
    _comSessao = true;
    _validando = false;
    notifyListeners();
  }

  /// Detecta o retorno do link na URL de entrada (web) antes de o Supabase
  /// consumir e limpar o fragment. Sem sessão ainda — o evento confirma depois.
  void capturarLinkWeb() {
    if (!kIsWeb || _ativo) return;
    if (!_urlIndicaRecovery(Uri.base)) return;
    _ativo = true;
    _validando = true;
    notifyListeners();
    _timeout = Timer(_limiteValidacao, () {
      if (!_ativo || _comSessao) return;
      _validando = false;
      notifyListeners();
    });
  }

  void encerrar() {
    _timeout?.cancel();
    if (!_ativo && !_comSessao && !_validando) return;
    _ativo = false;
    _comSessao = false;
    _validando = false;
    notifyListeners();
  }

  @visibleForTesting
  void reset() => encerrar();

  static bool _urlIndicaRecovery(Uri uri) {
    if (uri.fragment.contains('type=recovery')) return true;
    if (uri.queryParameters['type'] == 'recovery') return true;
    // Marcador da página-ponte `web/reset-password/index.html`.
    if (uri.queryParameters['recovery'] == '1') return true;
    // Fluxo PKCE: o Supabase devolve apenas `?code=` no caminho de recovery.
    return uri.queryParameters.containsKey('code') && uri.path.contains('reset-password');
  }
}
