import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pulguinha/models/models.dart';
import 'package:pulguinha/providers/app_state.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/utils/date_helper.dart';
import 'package:pulguinha/widgets/pulguinha_widgets.dart';

class AlunoTurmaScreen extends StatefulWidget {
  const AlunoTurmaScreen({super.key, required this.usuario});

  final Usuario usuario;

  @override
  State<AlunoTurmaScreen> createState() => _AlunoTurmaScreenState();
}

class _AlunoTurmaScreenState extends State<AlunoTurmaScreen> {
  final _postCtrl = TextEditingController();

  @override
  void dispose() {
    _postCtrl.dispose();
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
                    Text('Turma ${turma.hora}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.white)),
                    Text(turma.dias, style: const TextStyle(fontSize: 12, color: AppColors.gray)),
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
              TextField(
                controller: _postCtrl,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Compartilhe algo com sua turma...'),
              ),
              const SizedBox(height: 10),
              NeonButton(
                label: 'Publicar',
                onPressed: () {
                  state.publicarPostTurma(
                    alunoId: aluno.id,
                    nomeAluno: aluno.nome,
                    horarioId: aluno.horarioId!,
                    texto: _postCtrl.text,
                  );
                  _postCtrl.clear();
                },
              ),
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
              PulguinhaAvatar(initials: post.nomeAluno.split(' ').map((n) => n[0]).take(2).join(), size: AvatarSize.sm),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.nomeAluno, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.white)),
                    Text(DateHelper.formatarDataHora(post.dataHora), style: const TextStyle(fontSize: 10, color: AppColors.gray)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(post.texto, style: const TextStyle(fontSize: 13, color: AppColors.white, height: 1.4)),
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
              decoration: BoxDecoration(
                color: AppColors.card2,
                borderRadius: BorderRadius.circular(10),
              ),
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
