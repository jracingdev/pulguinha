import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pulguinha/models/models.dart';
import 'package:pulguinha/providers/app_state.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/utils/date_helper.dart';
import 'package:pulguinha/widgets/pulguinha_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

class AlunoTurmaScreen extends StatefulWidget {
  const AlunoTurmaScreen({super.key, required this.usuario});

  final Usuario usuario;

  @override
  State<AlunoTurmaScreen> createState() => _AlunoTurmaScreenState();
}

class _AlunoTurmaScreenState extends State<AlunoTurmaScreen> {
  final _postCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  final _opcao1Ctrl = TextEditingController();
  final _opcao2Ctrl = TextEditingController();
  final _opcao3Ctrl = TextEditingController();

  TipoPostTurma _tipoPost = TipoPostTurma.texto;
  String? _figurinhaSelecionada;

  static const _figurinhas = ['💪', '🔥', '🏆', '👏', '😅', '🎯', '⚡', '🤝', '🥇', '🙌', '💚', '🚀'];

  @override
  void dispose() {
    _postCtrl.dispose();
    _linkCtrl.dispose();
    _opcao1Ctrl.dispose();
    _opcao2Ctrl.dispose();
    _opcao3Ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final aluno = state.alunoPorId(widget.usuario.id);
    if (aluno == null) {
      return const PulguinhaCard(
        child: Text('Aluno não encontrado.', style: TextStyle(color: AppColors.gray)),
      );
    }

    if (aluno.horarioId == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(icon: '👥', title: 'Minha Turma'),
          const PulguinhaCard(
            child: Column(
              children: [
                Text('Você ainda não foi atribuído a uma turma.', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.white)),
                SizedBox(height: 6),
                Text('Fale com a recepção para definir seu horário fixo.', style: TextStyle(fontSize: 12, color: AppColors.gray)),
              ],
            ),
          ),
        ],
      );
    }

    final turma = state.horarioPorId(aluno.horarioId)!;
    final colegas = state.colegasDeTurma(aluno.id);
    final posts = state.postsDaTurma(aluno.horarioId!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(icon: '👥', title: 'Minha Turma'),
        PulguinhaCard(
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.neon.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.neon.withValues(alpha: 0.3)),
                ),
                alignment: Alignment.center,
                child: Text(turma.hora, style: const TextStyle(color: AppColors.neon, fontWeight: FontWeight.w900, fontSize: 12)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Turma principal ${turma.hora}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.white)),
                    Text(turma.dias, style: const TextStyle(fontSize: 12, color: AppColors.gray)),
                    const Text(
                      'Para mural e colegas. Outros horários: use a Agenda.',
                      style: TextStyle(fontSize: 10, color: AppColors.grayDim, height: 1.3),
                    ),
                    Text('${colegas.length + 1} alunos na turma', style: const TextStyle(fontSize: 11, color: AppColors.neon, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SectionTitle(icon: '🧑‍🤝‍🧑', title: 'Colegas de Turma'),
        if (colegas.isEmpty)
          const PulguinhaCard(
            child: Text('Você é o único aluno ativo nesta turma por enquanto.', style: TextStyle(fontSize: 12, color: AppColors.gray)),
          )
        else
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: colegas.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _colegaChip(colegas[i]),
            ),
          ),
        const SizedBox(height: 20),
        const SectionTitle(icon: '💬', title: 'Mural da Turma'),
        PulguinhaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _tipoChip('Texto', TipoPostTurma.texto, '✍️'),
                  _tipoChip('Figurinha', TipoPostTurma.figurinha, '😀'),
                  _tipoChip('Enquete', TipoPostTurma.enquete, '📊'),
                  _tipoChip('Link', TipoPostTurma.link, '🔗'),
                ],
              ),
              const SizedBox(height: 12),
              ..._composeFields(),
              const SizedBox(height: 10),
              NeonButton(label: 'Publicar', onPressed: () => _publicar(state, aluno)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (posts.isEmpty)
          const PulguinhaCard(
            child: Text('Nenhuma publicação ainda. Seja o primeiro a postar!', style: TextStyle(fontSize: 12, color: AppColors.gray)),
          )
        else
          ...posts.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _postCard(context, state, aluno, p),
              )),
      ],
    );
  }

  Widget _tipoChip(String label, TipoPostTurma tipo, String icon) {
    final selected = _tipoPost == tipo;
    return FilterChip(
      label: Text('$icon $label', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: selected ? const Color(0xFF111111) : AppColors.gray)),
      selected: selected,
      onSelected: (_) => setState(() => _tipoPost = tipo),
      selectedColor: AppColors.neon,
      backgroundColor: AppColors.card2,
      checkmarkColor: const Color(0xFF111111),
      side: BorderSide(color: selected ? AppColors.neon : AppColors.border),
    );
  }

  List<Widget> _composeFields() {
    return switch (_tipoPost) {
      TipoPostTurma.texto => [
          TextField(controller: _postCtrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Compartilhe algo com sua turma...')),
        ],
      TipoPostTurma.figurinha => [
          TextField(controller: _postCtrl, decoration: const InputDecoration(hintText: 'Mensagem opcional...')),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _figurinhas.map((f) {
              final selected = _figurinhaSelecionada == f;
              return GestureDetector(
                onTap: () => setState(() => _figurinhaSelecionada = f),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.neon.withValues(alpha: 0.2) : AppColors.card2,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: selected ? AppColors.neon : AppColors.border, width: selected ? 2 : 1),
                  ),
                  child: Text(f, style: const TextStyle(fontSize: 24)),
                ),
              );
            }).toList(),
          ),
        ],
      TipoPostTurma.enquete => [
          TextField(controller: _postCtrl, decoration: const InputDecoration(hintText: 'Pergunta da enquete...')),
          const SizedBox(height: 8),
          TextField(controller: _opcao1Ctrl, decoration: const InputDecoration(hintText: 'Opção 1')),
          const SizedBox(height: 8),
          TextField(controller: _opcao2Ctrl, decoration: const InputDecoration(hintText: 'Opção 2')),
          const SizedBox(height: 8),
          TextField(controller: _opcao3Ctrl, decoration: const InputDecoration(hintText: 'Opção 3 (opcional)')),
        ],
      TipoPostTurma.link => [
          TextField(controller: _postCtrl, decoration: const InputDecoration(hintText: 'Título ou descrição do link...')),
          const SizedBox(height: 8),
          TextField(controller: _linkCtrl, keyboardType: TextInputType.url, decoration: const InputDecoration(hintText: 'https://...')),
        ],
    };
  }

  void _publicar(AppState state, Aluno aluno) {
    state.publicarPostTurma(
      alunoId: aluno.id,
      nomeAluno: aluno.nome,
      horarioId: aluno.horarioId!,
      texto: _postCtrl.text,
      tipo: _tipoPost,
      figurinha: _figurinhaSelecionada,
      linkUrl: _linkCtrl.text,
      enqueteOpcoes: [_opcao1Ctrl.text, _opcao2Ctrl.text, _opcao3Ctrl.text],
    );
    _postCtrl.clear();
    _linkCtrl.clear();
    _opcao1Ctrl.clear();
    _opcao2Ctrl.clear();
    _opcao3Ctrl.clear();
    setState(() {
      _figurinhaSelecionada = null;
      _tipoPost = TipoPostTurma.texto;
    });
  }

  Widget _colegaChip(Aluno colega) {
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.card2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PulguinhaAvatar(initials: colega.avatar, size: AvatarSize.sm, fotoBase64: colega.foto),
          const SizedBox(height: 6),
          Text(
            colega.nome.split(' ').first,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.white),
          ),
        ],
      ),
    );
  }

  Widget _postCard(BuildContext context, AppState state, Aluno aluno, PostTurma post) {
    final reagiu = post.reagiuPor(aluno.id);
    return PulguinhaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PulguinhaAvatar(initials: post.isAdminPost ? 'PR' : post.nomeAluno.split(' ').map((n) => n[0]).take(2).join(), size: AvatarSize.sm),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            post.isAdminPost ? 'Professor · ${post.nomeAluno}' : post.nomeAluno,
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: post.isAdminPost ? AppColors.yellow : AppColors.white),
                          ),
                        ),
                        if (post.fixado) ...[const SizedBox(width: 4), const Text('📌', style: TextStyle(fontSize: 10))],
                      ],
                    ),
                    Text(DateHelper.formatarDataHora(post.dataHora), style: const TextStyle(fontSize: 10, color: AppColors.gray)),
                  ],
                ),
              ),
              PulguinhaBadge(label: _tipoLabel(post.tipo), variant: BadgeVariant.gray),
            ],
          ),
          const SizedBox(height: 10),
          _postContent(post, aluno, state),
          const SizedBox(height: 10),
          Row(
            children: [
              InkWell(
                onTap: () => state.toggleReacaoPost(post.id, aluno.id),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      Text(reagiu ? '💪' : '👍', style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      Text(
                        post.totalReacoes > 0 ? '${post.totalReacoes}' : 'Curtir',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: reagiu ? AppColors.neon : AppColors.gray),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: () => _abrirComentario(context, state, aluno, post),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    post.comentarios.isEmpty ? 'Comentar' : '${post.comentarios.length} comentário(s)',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray),
                  ),
                ),
              ),
            ],
          ),
          if (post.comentarios.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.card2, borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: post.comentarios.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 11, color: AppColors.gray, height: 1.3),
                          children: [
                            TextSpan(text: '${c.nomeAluno.split(' ').first}: ', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.white)),
                            TextSpan(text: c.texto),
                          ],
                        ),
                      ),
                    )).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _tipoLabel(TipoPostTurma tipo) {
    return switch (tipo) {
      TipoPostTurma.figurinha => 'Figurinha',
      TipoPostTurma.enquete => 'Enquete',
      TipoPostTurma.link => 'Link',
      TipoPostTurma.texto => 'Texto',
    };
  }

  Widget _postContent(PostTurma post, Aluno aluno, AppState state) {
    return switch (post.tipo) {
      TipoPostTurma.figurinha => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(post.figurinha ?? '😀', style: const TextStyle(fontSize: 56)),
            if (post.texto.isNotEmpty) Text(post.texto, style: const TextStyle(fontSize: 13, color: AppColors.white, height: 1.4)),
          ],
        ),
      TipoPostTurma.link => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.texto.isNotEmpty) Text(post.texto, style: const TextStyle(fontSize: 13, color: AppColors.white, height: 1.4)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final url = post.linkUrl;
                if (url == null) return;
                final uri = Uri.tryParse(url);
                if (uri != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.blue.withValues(alpha: 0.3)),
                ),
                child: Text(post.linkUrl ?? '', style: const TextStyle(fontSize: 12, color: AppColors.blue, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      TipoPostTurma.enquete => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(post.texto, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.white)),
            const SizedBox(height: 10),
            ...post.enqueteOpcoes.asMap().entries.map((e) {
              final idx = e.key;
              final opcao = e.value;
              final votos = post.enqueteVotos.values.where((v) => v == idx).length;
              final totalVotos = post.enqueteVotos.length;
              final pct = totalVotos > 0 ? votos / totalVotos : 0.0;
              final meuVoto = post.votoDoAluno(aluno.id) == idx;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => state.votarEnquete(postId: post.id, alunoId: aluno.id, opcaoIndex: idx),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: meuVoto ? AppColors.neon.withValues(alpha: 0.12) : AppColors.card2,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: meuVoto ? AppColors.neon : AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(opcao, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: meuVoto ? AppColors.neon : AppColors.white))),
                            Text('$votos voto(s)', style: const TextStyle(fontSize: 10, color: AppColors.gray)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(value: pct, minHeight: 4, backgroundColor: AppColors.card, color: AppColors.neon),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      TipoPostTurma.texto => Text(post.texto, style: const TextStyle(fontSize: 13, color: AppColors.white, height: 1.4)),
    };
  }

  Future<void> _abrirComentario(BuildContext context, AppState state, Aluno aluno, PostTurma post) async {
    final ctrl = TextEditingController();
    await showPulguinhaModal(
      context: context,
      title: 'Comentar',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: ctrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Escreva um comentário...')),
          const SizedBox(height: 12),
          NeonButton(
            label: 'Enviar',
            fullWidth: true,
            onPressed: () {
              state.comentarPostTurma(postId: post.id, alunoId: aluno.id, nomeAluno: aluno.nome, texto: ctrl.text);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
    ctrl.dispose();
  }
}
