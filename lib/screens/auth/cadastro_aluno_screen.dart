import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pulguinha/data/mock_data.dart';
import 'package:pulguinha/models/models.dart';
import 'package:pulguinha/providers/app_state.dart';
import 'package:pulguinha/screens/shared/legal_screen.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/utils/date_helper.dart';
import 'package:pulguinha/services/viacep_service.dart';
import 'package:pulguinha/utils/photo_picker_helper.dart';
import 'package:pulguinha/widgets/date_field.dart';
import 'package:pulguinha/widgets/mock_mode_banner.dart';
import 'package:pulguinha/widgets/pulguinha_widgets.dart';

class CadastroAlunoScreen extends StatefulWidget {
  const CadastroAlunoScreen({super.key});

  @override
  State<CadastroAlunoScreen> createState() => _CadastroAlunoScreenState();
}

class _CadastroAlunoScreenState extends State<CadastroAlunoScreen> {
  final nomeCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final telCtrl = TextEditingController();
  final cepCtrl = TextEditingController();
  final logradouroCtrl = TextEditingController();
  final numeroCtrl = TextEditingController();
  final complementoCtrl = TextEditingController();
  final bairroCtrl = TextEditingController();
  final cidadeCtrl = TextEditingController();
  final ufCtrl = TextEditingController();
  final senhaCtrl = TextEditingController();
  final confirmSenhaCtrl = TextEditingController();
  final nascCtrl = TextEditingController();
  final restrCtrl = TextEditingController();
  final objCtrl = TextEditingController();
  final emergCtrl = TextEditingController();
  final emergTelCtrl = TextEditingController();
  final alunoDesdeCtrl = TextEditingController();
  final codigoIndicacaoCtrl = TextEditingController();

  String? fotoBase64;
  var nivel = 'Iniciante';
  var aceitoTermos = false;
  var loading = false;
  String? erro;
  bool sucesso = false;

  var cepLoading = false;
  String? cepErro;

  @override
  void dispose() {
    nomeCtrl.dispose();
    emailCtrl.dispose();
    telCtrl.dispose();
    cepCtrl.dispose();
    logradouroCtrl.dispose();
    numeroCtrl.dispose();
    complementoCtrl.dispose();
    bairroCtrl.dispose();
    cidadeCtrl.dispose();
    ufCtrl.dispose();
    senhaCtrl.dispose();
    confirmSenhaCtrl.dispose();
    nascCtrl.dispose();
    restrCtrl.dispose();
    objCtrl.dispose();
    emergCtrl.dispose();
    emergTelCtrl.dispose();
    alunoDesdeCtrl.dispose();
    codigoIndicacaoCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    alunoDesdeCtrl.text = DateHelper.formatarData(MockData.today);
  }

  Future<void> _cadastrar() async {
    setState(() {
      erro = null;
      loading = true;
    });

    if (nomeCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) {
      setState(() {
        erro = 'Preencha nome e e-mail.';
        loading = false;
      });
      return;
    }
    if (senhaCtrl.text.length < 4) {
      setState(() {
        erro = 'Senha deve ter pelo menos 4 caracteres.';
        loading = false;
      });
      return;
    }
    if (senhaCtrl.text != confirmSenhaCtrl.text) {
      setState(() {
        erro = 'As senhas não coincidem.';
        loading = false;
      });
      return;
    }
    if (!aceitoTermos) {
      setState(() {
        erro = 'Aceite os Termos e a Política de Privacidade.';
        loading = false;
      });
      return;
    }

    final state = context.read<AppState>();
    final codigoInd = codigoIndicacaoCtrl.text.trim();
    if (codigoInd.isNotEmpty) {
      final errCodigo = state.validarCodigoIndicacao(codigoInd);
      if (errCodigo != null) {
        setState(() {
          erro = errCodigo;
          loading = false;
        });
        return;
      }
    }

    final avatar = nomeCtrl.text.split(' ').map((n) => n[0]).take(2).join().toUpperCase();
    final aluno = Aluno(
      id: DateTime.now().millisecondsSinceEpoch,
      nome: nomeCtrl.text.trim(),
      email: emailCtrl.text.trim().toLowerCase(),
      senha: senhaCtrl.text,
      telefone: telCtrl.text.trim(),
      cep: cepCtrl.text.trim(),
      logradouro: logradouroCtrl.text.trim(),
      numero: numeroCtrl.text.trim(),
      complemento: complementoCtrl.text.trim(),
      bairro: bairroCtrl.text.trim(),
      cidade: cidadeCtrl.text.trim(),
      uf: ufCtrl.text.trim(),
      plano: 'Mensal',
      vencimento: MockData.vencimentoPendente,
      status: 'Pendente',
      avatar: avatar,
      alunoDesde: alunoDesdeCtrl.text.trim().isEmpty ? MockData.today : DateHelper.paraIso(alunoDesdeCtrl.text.trim()),
      dataCadastro: MockData.today,
      dataNascimento: nascCtrl.text.trim().isEmpty ? null : DateHelper.paraIso(nascCtrl.text.trim()),
      anamnese: Anamnese(
        restricoesMedicas: restrCtrl.text.trim(),
        objetivoTreino: objCtrl.text.trim(),
        nivelExperiencia: nivel,
        contatoEmergencia: emergCtrl.text.trim(),
        telefoneEmergencia: emergTelCtrl.text.trim(),
      ),
      foto: fotoBase64,
    );

    final msg = await state.cadastrarAlunoPublico(aluno, codigoIndicacao: codigoInd);
    if (!mounted) return;
    setState(() {
      loading = false;
      if (msg != null) {
        erro = msg;
      } else {
        sucesso = true;
      }
    });
  }

  Future<void> _buscarCep() async {
    setState(() {
      cepErro = null;
      cepLoading = true;
    });

    final res = await ViaCepService.instance.buscar(cepCtrl.text.trim());
    if (!mounted) return;

    setState(() => cepLoading = false);

    if (res == null || res.erro) {
      setState(() => cepErro = 'CEP inválido ou não encontrado.');
      return;
    }

    setState(() {
      logradouroCtrl.text = res.logradouro;
      bairroCtrl.text = res.bairro;
      cidadeCtrl.text = res.cidade;
      ufCtrl.text = res.uf;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (sucesso) return _buildSucesso();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Criar conta'),
        backgroundColor: AppColors.card,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            const Center(child: PulguinhaLogo(size: 100, borderRadius: 20)),
            const SizedBox(height: 8),
            const Text(
              'Cadastre-se no Funcional do Pulguinha',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.white),
            ),
            const SizedBox(height: 4),
            const Text(
              'Seu cadastro será analisado pelo professor antes da liberação.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.gray),
            ),
            const SizedBox(height: 24),
            const MockModeBanner(),
            FieldLabel(
              label: 'Foto',
              child: Column(
                children: [
                  if (fotoBase64 != null && fotoBase64!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PulguinhaAvatar(initials: 'AL', size: AvatarSize.lg, fotoBase64: fotoBase64),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: GhostButton(
                          label: '📷 Adicionar foto',
                          onPressed: () async {
                            final b64 = await pickPhotoBase64(context);
                            if (b64 != null) setState(() => fotoBase64 = b64);
                          },
                        ),
                      ),
                      if (fotoBase64 != null) ...[
                        const SizedBox(width: 8),
                        GhostButton(label: 'Remover', onPressed: () => setState(() => fotoBase64 = null)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            FieldLabel(label: 'Nome completo *', child: TextField(controller: nomeCtrl)),
            FieldLabel(label: 'E-mail *', child: TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress)),
            FieldLabel(
              label: 'Código de indicação (opcional)',
              child: TextField(
                controller: codigoIndicacaoCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  hintText: 'Ex: MAR1234',
                  helperText: 'Ganhe 5% na 1ª mensalidade se foi indicado por um aluno.',
                ),
              ),
            ),
            FieldLabel(label: 'Telefone', child: TextField(controller: telCtrl, keyboardType: TextInputType.phone)),
            const SizedBox(height: 10),
            const SectionTitle(icon: '📍', title: 'Endereço'),
            FieldLabel(
              label: 'CEP',
              child: TextField(
                controller: cepCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: '00000-000',
                  suffixIcon: cepLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : (cepCtrl.text.trim().length == 8 ? const Icon(Icons.search, color: AppColors.neon) : null),
                ),
                onChanged: (v) {
                  setState(() => cepErro = null);
                  final digits = v.replaceAll(RegExp(r'\D'), '');
                  if (digits.length == 8 && !cepLoading) _buscarCep();
                },
              ),
            ),
            if (cepErro != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  '⚠️ $cepErro',
                  style: const TextStyle(color: AppColors.red, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            FieldLabel(label: 'Logradouro', child: TextField(controller: logradouroCtrl)),
            Row(
              children: [
                Expanded(
                  child: FieldLabel(
                    label: 'Número',
                    child: TextField(controller: numeroCtrl, keyboardType: TextInputType.number),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FieldLabel(label: 'Complemento', child: TextField(controller: complementoCtrl)),
                ),
              ],
            ),
            FieldLabel(label: 'Bairro', child: TextField(controller: bairroCtrl)),
            FieldLabel(label: 'Cidade', child: TextField(controller: cidadeCtrl)),
            FieldLabel(
              label: 'UF',
              child: TextField(
                controller: ufCtrl,
                textCapitalization: TextCapitalization.characters,
                maxLength: 2,
              ),
            ),
            FieldLabel(
              label: 'Aluno desde (opcional)',
              child: DateField(controller: alunoDesdeCtrl, lastDate: DateTime.now().add(const Duration(days: 365))),
            ),
            FieldLabel(
              label: 'Data de nascimento',
              child: DateField(controller: nascCtrl, lastDate: DateTime.now(), hintText: '13-06-1995'),
            ),
            FieldLabel(label: 'Senha *', child: TextField(controller: senhaCtrl, obscureText: true)),
            FieldLabel(label: 'Confirmar senha *', child: TextField(controller: confirmSenhaCtrl, obscureText: true)),
            const SectionTitle(icon: '🏥', title: 'Anamnese'),
            FieldLabel(label: 'Restrições / lesões', child: TextField(controller: restrCtrl, maxLines: 2)),
            FieldLabel(label: 'Objetivo do treino', child: TextField(controller: objCtrl)),
            FieldLabel(
              label: 'Nível',
              child: DropdownButtonFormField<String>(
                value: nivel,
                items: ['Iniciante', 'Intermediário', 'Avançado'].map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
                onChanged: (v) => setState(() => nivel = v ?? nivel),
              ),
            ),
            FieldLabel(label: 'Contato de emergência', child: TextField(controller: emergCtrl)),
            FieldLabel(label: 'Tel. emergência', child: TextField(controller: emergTelCtrl)),
            const SizedBox(height: 12),
            TermosAceiteWidget(aceito: aceitoTermos, onChanged: (v) => setState(() => aceitoTermos = v)),
            const SizedBox(height: 16),
            if (erro != null)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.12),
                  border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('⚠️ $erro', style: const TextStyle(color: AppColors.red, fontSize: 12)),
              ),
            NeonButton(
              label: loading ? 'Enviando...' : 'Enviar cadastro',
              fullWidth: true,
              enabled: !loading,
              onPressed: _cadastrar,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Já tenho conta — Fazer login', style: TextStyle(color: AppColors.neon)),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSucesso() {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.neon.withValues(alpha: 0.15),
                  border: Border.all(color: AppColors.neon, width: 2),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text('✅', style: TextStyle(fontSize: 36)),
              ),
              const SizedBox(height: 20),
              const Text('Cadastro enviado!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.neon)),
              const SizedBox(height: 12),
              const Text(
                'Seu cadastro foi enviado ao servidor e aguarda aprovação do professor.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.gray, height: 1.5),
              ),
              const SizedBox(height: 28),
              NeonButton(
                label: 'Voltar ao início',
                fullWidth: true,
                onPressed: () {
                  context.read<AppState>().logout();
                  Navigator.of(context).popUntil((r) => r.isFirst);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
