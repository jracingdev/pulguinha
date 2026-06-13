class TrainingTip {
  const TrainingTip({
    required this.id,
    required this.icon,
    required this.titulo,
    required this.texto,
    required this.categoria,
  });

  final String id;
  final String icon;
  final String titulo;
  final String texto;
  final String categoria;
}

class TrainingTipsData {
  static const metaCoposAgua = 8;
  static const mlPorCopo = 250;
  static const metaMlAgua = metaCoposAgua * mlPorCopo;

  static const tips = <TrainingTip>[
    TrainingTip(
      id: 'progressao',
      icon: '📈',
      titulo: 'Progressão de carga',
      categoria: 'Força',
      texto:
          'No funcional, aumente a dificuldade aos poucos: mais repetições, menos descanso ou peso extra. '
          'O Pulguinha diz: evoluir 5% por semana já é vitória!',
    ),
    TrainingTip(
      id: 'consistencia',
      icon: '🔥',
      titulo: 'Consistência vence intensidade',
      categoria: 'Hábito',
      texto:
          'Treinar 3x por semana com regularidade rende mais que um treino monstruoso e sumir por 2 semanas. '
          'Marque na agenda e trate como compromisso consigo mesmo.',
    ),
    TrainingTip(
      id: 'descanso',
      icon: '😴',
      titulo: 'Descanso é treino também',
      categoria: 'Recuperação',
      texto:
          'Músculos crescem na recuperação. Durma bem, respeite dias off e ouça o corpo quando sentir dor aguda — '
          'não confunda com desconforto do esforço.',
    ),
    TrainingTip(
      id: 'nutricao',
      icon: '🥗',
      titulo: 'Nutrição pós-treino',
      categoria: 'Nutrição',
      texto:
          'Após o funcional, combine proteína + carboidrato nas 2h seguintes. '
          'Um lanche simples (iogurte + fruta, ovo + pão integral) acelera a recuperação.',
    ),
    TrainingTip(
      id: 'hidratacao',
      icon: '💧',
      titulo: 'Hidratação durante o treino',
      categoria: 'Saúde',
      texto:
          'Beba água antes, durante e depois do treino. No funcional você transpira muito — '
          'desidratação reduz força e foco. Meta: ~2L por dia!',
    ),
    TrainingTip(
      id: 'smart',
      icon: '🎯',
      titulo: 'Metas SMART',
      categoria: 'Mentalidade',
      texto:
          'Defina metas Específicas, Mensuráveis, Atingíveis, Relevantes e com Tempo. '
          'Ex.: "Fazer 10 burpees seguidos até o fim do mês" em vez de "ficar mais forte".',
    ),
    TrainingTip(
      id: 'aquecimento',
      icon: '🏃',
      titulo: 'Aquecimento dinâmico',
      categoria: 'Técnica',
      texto:
          '5–10 min de mobilidade e ativação antes do WOD evitam lesões. '
          'Polichinelos, agachamento livre e rotações de ombro preparam o corpo pro trabalho pesado.',
    ),
    TrainingTip(
      id: 'tecnica',
      icon: '✅',
      titulo: 'Técnica antes de velocidade',
      categoria: 'Técnica',
      texto:
          'Executar bem vale mais que fazer rápido e errado. '
          'Grave-se ou peça feedback ao professor — forma correta multiplica resultados e protege articulações.',
    ),
    TrainingTip(
      id: 'variar',
      icon: '🔄',
      titulo: 'Varie estímulos',
      categoria: 'Programação',
      texto:
          'Alterne força, resistência e potência. O funcional brilha na variedade — '
          'sempre o mesmo treino estagna. Confie no planejamento da aula!',
    ),
    TrainingTip(
      id: 'mindset',
      icon: '🧠',
      titulo: 'Mentalidade de crescimento',
      categoria: 'Mentalidade',
      texto:
          'Comparar-se com os outros no box é armadilha. Compare com o você de ontem. '
          'Cada rep a mais, cada segundo a menos — isso é evolução real.',
    ),
    TrainingTip(
      id: 'mobilidade',
      icon: '🧘',
      titulo: 'Mobilidade nos dias off',
      categoria: 'Recuperação',
      texto:
          'Alongamento, foam roller ou yoga leve nos dias sem treino mantêm amplitude de movimento. '
          'Corpo móvel = movimentos mais eficientes no funcional.',
    ),
    TrainingTip(
      id: 'registro',
      icon: '📝',
      titulo: 'Registre seu progresso',
      categoria: 'Hábito',
      texto:
          'Anote cargas, tempos e sensações. Em 3 meses você verá padrões claros de evolução. '
          'O app já registra presença — use isso como motivação extra!',
    ),
  ];

  static TrainingTip dicaDoDia([DateTime? date]) {
    final d = date ?? DateTime.now();
    final index = (d.year * 366 + d.month * 31 + d.day) % tips.length;
    return tips[index];
  }
}
