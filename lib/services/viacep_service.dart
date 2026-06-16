import 'dart:convert';

import 'package:http/http.dart' as http;

class EnderecoViaCep {
  const EnderecoViaCep({
    this.logradouro = '',
    this.bairro = '',
    this.cidade = '',
    this.uf = '',
    this.erro = false,
  });

  final String logradouro;
  final String bairro;
  final String cidade;
  final String uf;
  final bool erro;
}

class ViaCepService {
  ViaCepService._();
  static final instance = ViaCepService._();

  static String limparCep(String cep) => cep.replaceAll(RegExp(r'\D'), '');

  Future<EnderecoViaCep?> buscar(String cep) async {
    final digits = limparCep(cep);
    if (digits.length != 8) return null;

    try {
      final res = await http
          .get(Uri.parse('https://viacep.com.br/ws/$digits/json/'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;

      final map = jsonDecode(res.body) as Map<String, dynamic>;
      if (map['erro'] == true) {
        return const EnderecoViaCep(erro: true);
      }

      return EnderecoViaCep(
        logradouro: map['logradouro'] as String? ?? '',
        bairro: map['bairro'] as String? ?? '',
        cidade: map['localidade'] as String? ?? '',
        uf: map['uf'] as String? ?? '',
      );
    } catch (_) {
      return null;
    }
  }
}
