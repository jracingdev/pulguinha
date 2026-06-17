import 'package:flutter/material.dart';
import 'package:pulguinha/config/partner_config.dart';
import 'package:pulguinha/models/partner_access.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/widgets/pulguinha_widgets.dart';

class PartnerLoginPanel extends StatefulWidget {
  const PartnerLoginPanel({
    super.key,
    required this.loading,
    required this.onLogin,
  });

  final bool loading;
  final Future<void> Function(PartnerProvider provider, String identifier, TotalpassIdentifierType type) onLogin;

  @override
  State<PartnerLoginPanel> createState() => _PartnerLoginPanelState();
}

class _PartnerLoginPanelState extends State<PartnerLoginPanel> {
  PartnerProvider _provider = PartnerProvider.wellhub;
  TotalpassIdentifierType _tpType = TotalpassIdentifierType.cpf;
  final _identifierCtrl = TextEditingController();

  @override
  void dispose() {
    _identifierCtrl.dispose();
    super.dispose();
  }

  String get _hint {
    if (_provider == PartnerProvider.wellhub) {
      return 'ID GymPass (13 dígitos)';
    }
    switch (_tpType) {
      case TotalpassIdentifierType.cpf:
        return 'CPF cadastrado no TotalPass';
      case TotalpassIdentifierType.code:
        return 'Código do beneficiário';
      case TotalpassIdentifierType.token:
        return 'Token diário do app TotalPass';
    }
  }

  bool get _providerConfigured => PartnerConfig.canAttemptBeneficioLogin(_provider);

  Future<void> _submit() async {
    await widget.onLogin(_provider, _identifierCtrl.text.trim(), _tpType);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: Divider(color: AppColors.border.withValues(alpha: 0.6))),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text('ou entre com benefício (opcional)', style: TextStyle(fontSize: 11, color: AppColors.gray, fontWeight: FontWeight.w600)),
            ),
            Expanded(child: Divider(color: AppColors.border.withValues(alpha: 0.6))),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.card,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              _providerChip(PartnerProvider.wellhub, 'GymPass'),
              _providerChip(PartnerProvider.totalpass, 'TotalPass'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (!_providerConfigured)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.yellow.withValues(alpha: 0.08),
              border: Border.all(color: AppColors.yellow.withValues(alpha: 0.25)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Integração ${_provider.label} pendente — configure em Admin → GymPass & TotalPass. Login por e-mail continua normal.',
              style: const TextStyle(fontSize: 11, color: AppColors.yellow, height: 1.35),
            ),
          )
        else
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.neon.withValues(alpha: 0.06),
              border: Border.all(color: AppColors.neon.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Check-in no app ${_provider.label} é obrigatório para a academia receber o repasse. '
              'O Pulguinha confirma esse check-in pela API oficial.',
              style: TextStyle(fontSize: 11, color: AppColors.neon.withValues(alpha: 0.9), height: 1.35),
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.card2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            _provider == PartnerProvider.wellhub
                ? '1. Faça check-in no app GymPass nesta academia (obrigatório para repasse)\n'
                    '2. Informe seu ID GymPass — validamos o check-in na API oficial'
                : '1. Faça check-in no app TotalPass nesta academia (obrigatório para repasse)\n'
                    '2. Informe seu CPF cadastrado — confirmamos o check-in na API (track_usages)',
            style: const TextStyle(fontSize: 11, color: AppColors.gray, height: 1.45),
          ),
        ),
        if (_provider == PartnerProvider.totalpass) ...[
          const SizedBox(height: 10),
          DropdownButtonFormField<TotalpassIdentifierType>(
            value: _tpType,
            dropdownColor: AppColors.card,
            decoration: const InputDecoration(labelText: 'Tipo de identificação'),
            items: const [
              DropdownMenuItem(value: TotalpassIdentifierType.cpf, child: Text('CPF (recomendado — vincula sua conta)')),
              DropdownMenuItem(value: TotalpassIdentifierType.token, child: Text('Token diário (só teste/admin)')),
              DropdownMenuItem(value: TotalpassIdentifierType.code, child: Text('Código beneficiário')),
            ],
            onChanged: widget.loading
                ? null
                : (v) => setState(() {
                      if (v != null) _tpType = v;
                    }),
          ),
        ],
        const SizedBox(height: 10),
        FieldLabel(
          label: _provider == PartnerProvider.wellhub ? 'ID GymPass' : 'Identificador TotalPass',
          child: TextField(
            controller: _identifierCtrl,
            enabled: !widget.loading,
            keyboardType: _provider == PartnerProvider.wellhub || _tpType == TotalpassIdentifierType.cpf
                ? TextInputType.number
                : TextInputType.text,
            textCapitalization: TextCapitalization.characters,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(hintText: _hint),
          ),
        ),
        const SizedBox(height: 10),
        GhostButton(
          label: widget.loading
              ? '⏳ Confirmando check-in...'
              : 'Confirmar check-in ${_provider.label} e entrar',
          fullWidth: true,
          borderColor: AppColors.neon.withValues(alpha: 0.35),
          textColor: AppColors.neon,
          onPressed: widget.loading ? null : _submit,
        ),
      ],
    );
  }

  Widget _providerChip(PartnerProvider provider, String label) {
    final selected = _provider == provider;
    return Expanded(
      child: GestureDetector(
        onTap: widget.loading ? null : () => setState(() => _provider = provider),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.neon.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? AppColors.neon.withValues(alpha: 0.4) : Colors.transparent),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: selected ? AppColors.neon : AppColors.gray,
            ),
          ),
        ),
      ),
    );
  }
}
