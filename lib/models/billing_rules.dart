/// Detalhamento do preço após regras de cobrança e indicação.
class PrecoComRegras {
  const PrecoComRegras({
    required this.precoOriginal,
    required this.precoFinal,
    this.descontoAntecipado = 0,
    this.descontoIndicado = 0,
    this.creditoIndicador = 0,
  });

  final double precoOriginal;
  final double precoFinal;
  final double descontoAntecipado;
  /// Desconto % para quem foi indicado (primeira compra de plano).
  final double descontoIndicado;
  /// Crédito de indicação do comprador aplicado nesta compra.
  final double creditoIndicador;

  double get descontoTotal => precoOriginal - precoFinal;
}

/// Regras de cobrança configuráveis pelo admin.
class RegraCobranca {
  const RegraCobranca({
    required this.id,
    required this.nome,
    required this.tipo,
    this.valorPercent = 0,
    this.valorFixo = 0,
    this.ativo = true,
    this.descricao = '',
  });

  final String id;
  final String nome;
  /// desconto_antecipado | indique_ganhe | personalizada
  final String tipo;
  final double valorPercent;
  final double valorFixo;
  final bool ativo;
  final String descricao;

  RegraCobranca copyWith({
    String? id,
    String? nome,
    String? tipo,
    double? valorPercent,
    double? valorFixo,
    bool? ativo,
    String? descricao,
  }) {
    return RegraCobranca(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      tipo: tipo ?? this.tipo,
      valorPercent: valorPercent ?? this.valorPercent,
      valorFixo: valorFixo ?? this.valorFixo,
      ativo: ativo ?? this.ativo,
      descricao: descricao ?? this.descricao,
    );
  }

  factory RegraCobranca.fromJson(Map<String, dynamic> json) => RegraCobranca(
        id: json['id'] as String,
        nome: json['nome'] as String,
        tipo: json['tipo'] as String? ?? 'personalizada',
        valorPercent: (json['valor_percent'] as num?)?.toDouble() ?? 0,
        valorFixo: (json['valor_fixo'] as num?)?.toDouble() ?? 0,
        ativo: json['ativo'] as bool? ?? true,
        descricao: json['descricao'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'tipo': tipo,
        'valor_percent': valorPercent,
        'valor_fixo': valorFixo,
        'ativo': ativo,
        'descricao': descricao,
      };

  static List<RegraCobranca> padrao() => [
        const RegraCobranca(
          id: 'desconto_antecipado',
          nome: 'Desconto antes do vencimento',
          tipo: 'desconto_antecipado',
          valorPercent: 10,
          ativo: true,
          descricao: '10% de desconto pagando antes do vencimento',
        ),
        const RegraCobranca(
          id: 'indique_ganhe',
          nome: 'Indique e ganhe',
          tipo: 'indique_ganhe',
          valorPercent: 5,
          valorFixo: 30,
          ativo: true,
          descricao: 'Indicado: 5% na 1ª compra. Indicador: R\$ 30 de crédito ao converter.',
        ),
      ];
}
