import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pulguinha/models/models.dart';
import 'package:pulguinha/providers/app_state.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/utils/date_helper.dart';
import 'package:pulguinha/widgets/pulguinha_widgets.dart';

/// Moderação do mural — só conteúdo público da turma (sem dados privados dos alunos).
class AdminTurmaMuralScreen extends StatefulWidget {
  const AdminTurmaMuralScreen({super.key});

  @override
  State<AdminTurmaMuralScreen> createState() => _AdminTurmaMuralScreenState();
}

class _AdminTurmaMuralScreenState extends State<AdminTurmaMuralScreen> {
  int? _horarioId;
  final _postCtrl = TextEditingController();

  @override
  void dispose() {
    _postCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final horarios = state.horarios;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        title: const Text('Mural das turmas', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
          PulguinhaCard(
            borderColor: AppColors.blue.withValues(alpha: 0.3),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🔒 Privacidade', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.white)),
                SizedBox(height: 6),
                Text(
                  'Você vê apenas posts públicos do mural. Dados financeiros, anamnese, perfil e mensagens privadas dos alunos não são exibidos.',
                  style: TextStyle(fontSize: 11, color: AppColors.gray, height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: state.adminParticipaMural,
            onChanged: state.setAdminParticipaMural,
            title: const Text('Participar como professor', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.white)),
            subtitle: const Text('Permite publicar no mural (opcional)', style: TextStyle(fontSize: 11, color: AppColors.gray)),
            activeColor: AppColors.neon,
            tileColor: AppColors.card2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.border)),
          ),
          const SizedBox(height: 16),
          const SectionTitle(icon: '🕐', title: 'Selecione a turma'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: horarios.map((h) {
              final sel = _horarioId == h.id;
              return ChoiceChip(
                label: Text('${h.hora} · ${h.dias}'),
                selected: sel,
                onSelected: (_) => setState(() => _horarioId = h.id),
                selectedColor: AppColors.neon.withValues(alpha: 0.2),
                labelStyle: TextStyle(color: sel ? AppColors.neon : AppColors.gray, fontWeight: FontWeight.w700, fontSize: 11),
              );
            }).toList(),
          ),
          if (_horarioId != null) ...[
            const SizedBox(height: 12),
            Text(
              '${state.contagemAlunosTurma(_horarioId!)} alunos ativos nesta turma',
              style: const TextStyle(fontSize: 11, color: AppColors.grayDim),
            ),
            if (state.adminParticipaMural) ...[
              const SizedBox(height: 16),
              const SectionTitle(icon: '✍️', title: 'Publicar como professor'),
              const SizedBox(height: 8),
              TextField(
                controller: _postCtrl,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Mensagem para a turma...'),
              ),
              const SizedBox(height: 8),
              NeonButton(
                label: 'Publicar no mural',
                fullWidth: true,
                onPressed: () {
                  if (_postCtrl.text.trim().isEmpty) return;
                  state.publicarPostTurmaAdmin(
                    nomeAdmin: state.usuario?.nome ?? 'Professor',
                    horarioId: _horarioId!,
                    texto: _postCtrl.text,
                  );
                  _postCtrl.clear();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Publicado no mural!'), behavior: SnackBarBehavior.floating),
                  );
                },
              ),
            ],
            const SizedBox(height: 20),
            SectionTitle(icon: '📋', title: 'Posts (${state.postsDaTurma(_horarioId!, incluirOcultos: true).length})'),
            const SizedBox(height: 8),
            ...state.postsDaTurma(_horarioId!, incluirOcultos: true).map((p) => _postModeracao(context, state, p)),
          ],
        ],
        ),
      ),
    );
  }

  Widget _postModeracao(BuildContext context, AppState state, PostTurma post) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PulguinhaCard(
        borderColor: post.oculto ? AppColors.red.withValues(alpha: 0.3) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    post.isAdminPost ? '👨‍🏫 ${post.nomeAluno}' : post.nomeAluno.split(' ').first,
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: post.isAdminPost ? AppColors.yellow : AppColors.white),
                  ),
                ),
                if (post.fixado) const Text('📌', style: TextStyle(fontSize: 12)),
                if (post.oculto) const PulguinhaBadge(label: 'Oculto', variant: BadgeVariant.red),
              ],
            ),
            Text(DateHelper.formatarDataHora(post.dataHora), style: const TextStyle(fontSize: 10, color: AppColors.grayDim)),
            const SizedBox(height: 6),
            Text(post.texto.isNotEmpty ? post.texto : '(${post.tipo.name})', style: const TextStyle(fontSize: 12, color: AppColors.gray, height: 1.4)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              children: [
                _acao('Fixar', () => state.moderarPostTurma(post.id, fixado: !post.fixado)),
                _acao(post.oculto ? 'Exibir' : 'Ocultar', () => state.moderarPostTurma(post.id, oculto: !post.oculto)),
                _acao('Excluir', () {
                  state.removerPostTurma(post.id);
                }, danger: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _acao(String label, VoidCallback onTap, {bool danger = false}) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: danger ? AppColors.red : AppColors.neon,
        side: BorderSide(color: (danger ? AppColors.red : AppColors.neon).withValues(alpha: 0.3)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}
