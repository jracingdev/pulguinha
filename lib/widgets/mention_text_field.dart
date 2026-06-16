import 'package:flutter/material.dart';
import 'package:pulguinha/models/models.dart';
import 'package:pulguinha/theme/app_colors.dart';

/// Campo de texto com menção @aluno (autocomplete).
class MentionTextField extends StatefulWidget {
  const MentionTextField({
    super.key,
    required this.controller,
    required this.alunos,
    this.maxLines = 4,
    this.hintText,
    this.onMencoesChanged,
  });

  final TextEditingController controller;
  final List<Aluno> alunos;
  final int maxLines;
  final String? hintText;
  final ValueChanged<List<int>>? onMencoesChanged;

  @override
  State<MentionTextField> createState() => _MentionTextFieldState();
}

class _MentionTextFieldState extends State<MentionTextField> {
  final _focus = FocusNode();
  OverlayEntry? _overlay;
  final _layerLink = LayerLink();
  List<int> _mencoes = [];

  @override
  void dispose() {
    _removeOverlay();
    _focus.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  void _syncMencoes(String text) {
    final ids = <int>{};
    for (final a in widget.alunos.where((x) => x.status == 'Ativo')) {
      if (text.contains('@${a.nome}')) ids.add(a.id);
    }
    _mencoes = ids.toList();
    widget.onMencoesChanged?.call(_mencoes);
  }

  void _showSuggestions(String query) {
    _removeOverlay();
    final q = query.toLowerCase();
    final matches = widget.alunos
        .where((a) => a.status == 'Ativo' && a.nome.toLowerCase().contains(q))
        .take(6)
        .toList();
    if (matches.isEmpty) return;

    _overlay = OverlayEntry(
      builder: (ctx) => Positioned(
        width: 280,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 48),
          child: Material(
            color: AppColors.card2,
            elevation: 8,
            borderRadius: BorderRadius.circular(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: matches.map((a) {
                return ListTile(
                  dense: true,
                  title: Text(a.nome, style: const TextStyle(fontSize: 13, color: AppColors.white)),
                  onTap: () {
                    final text = widget.controller.text;
                    final at = text.lastIndexOf('@');
                    if (at >= 0) {
                      widget.controller.text = '${text.substring(0, at)}@${a.nome} ';
                      widget.controller.selection = TextSelection.collapsed(offset: widget.controller.text.length);
                    }
                    _syncMencoes(widget.controller.text);
                    _removeOverlay();
                    setState(() {});
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlay!);
  }

  void _onChanged(String value) {
    _syncMencoes(value);
    final at = value.lastIndexOf('@');
    if (at >= 0 && (at == value.length - 1 || !value.substring(at).contains(' '))) {
      final q = value.substring(at + 1);
      _showSuggestions(q);
    } else {
      _removeOverlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: widget.controller,
        focusNode: _focus,
        maxLines: widget.maxLines,
        onChanged: _onChanged,
        decoration: InputDecoration(
          hintText: widget.hintText ?? 'Digite @ para marcar um aluno',
        ),
      ),
    );
  }
}

/// Destaca @menções no texto.
class MentionText extends StatelessWidget {
  const MentionText({super.key, required this.text, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final base = style ?? const TextStyle(fontSize: 13, color: AppColors.white, height: 1.4);
    final parts = text.split(RegExp(r'(@[^\s@]+)'));
    return RichText(
      text: TextSpan(
        style: base,
        children: parts.map((p) {
          if (p.startsWith('@')) {
            return TextSpan(text: p, style: base.copyWith(color: AppColors.neon, fontWeight: FontWeight.w800));
          }
          return TextSpan(text: p);
        }).toList(),
      ),
    );
  }
}
