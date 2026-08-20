import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pulguinha/models/models.dart';
import 'package:pulguinha/providers/app_state.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/utils/date_helper.dart';
import 'package:pulguinha/widgets/pulguinha_widgets.dart';

class AdminAnalyticsSection extends StatelessWidget {
  const AdminAnalyticsSection({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final presHoje = state.presencasHoje().length;
    final presSemana = state.presencasNaSemana().length;
    final taxa = state.taxaPresenca();
    final anivMes = state.aniversariantesDoMes();
    final novos = state.novosAlunosMes();
    final receita = state.receitaMensalEstimada;
    final ranking = state.rankingSemana();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(icon: '📊', title: 'Analytics'),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _kpi('✅', '$presHoje', 'Presenças Hoje', AppColors.neon),
            _kpi('📈', '$presSemana', 'Esta Semana', AppColors.blue),
            _kpi('🎯', '${taxa.toStringAsFixed(0)}%', 'Freq. Média', AppColors.yellow),
            _kpi('🎂', '$anivMes', 'Aniv. do Mês', AppColors.red),
            _kpi('🆕', '$novos', 'Novos Alunos', AppColors.neon),
            _kpi('💰', 'R\$ ${receita.toStringAsFixed(0)}', 'Receita Est.', AppColors.yellow),
          ],
        ),
        const SizedBox(height: 20),
        if (ranking.isNotEmpty) ...[
          const SectionTitle(icon: '🏆', title: 'Ranking da Semana'),
          ...ranking.asMap().entries.map((e) {
            final medal = ['🥇', '🥈', '🥉'][e.key];
            final (aluno, count) = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: PulguinhaCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Text(medal, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    PulguinhaAvatar(initials: aluno.avatar, size: AvatarSize.sm, fotoBase64: aluno.foto),
                    const SizedBox(width: 10),
                    Expanded(child: Text(aluno.nome, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.white, fontSize: 13))),
                    Text('$count treinos', style: const TextStyle(color: AppColors.neon, fontWeight: FontWeight.w900, fontSize: 12)),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
        ],
        _lineChart(),
        const SizedBox(height: 16),
        _barChart(),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 520;
            if (stacked) {
              return Column(
                children: [
                  _piePlanos(),
                  const SizedBox(height: 12),
                  _statusChart(),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _piePlanos()),
                const SizedBox(width: 10),
                Expanded(child: _statusChart()),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        _aniversariantesSection(),
      ],
    );
  }

  Widget _kpi(String icon, String val, String label, Color color) {
    return SizedBox(
      width: 110,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            Text(val, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _lineChart() {
    final data = state.presencasPorDia(7);
    final spots = data.entries.toList().asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.value.toDouble())).toList();
    final maxVal = data.values.fold<int>(0, (a, b) => a > b ? a : b);
    final maxY = (maxVal + 1).toDouble().clamp(3.0, 20.0);

    return PulguinhaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Presenças — 7 dias', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.white, fontSize: 13)),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 1, getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.border, strokeWidth: 1)),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10, color: AppColors.gray, fontWeight: FontWeight.w600)))),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                    final idx = v.toInt();
                    if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                    final iso = data.keys.elementAt(idx);
                    return Text(iso.substring(8), style: const TextStyle(fontSize: 10, color: AppColors.gray, fontWeight: FontWeight.w600));
                  })),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.neon,
                    barWidth: 3,
                    dotData: FlDotData(show: true, getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(radius: 4, color: AppColors.neon, strokeWidth: 0)),
                    belowBarData: BarAreaData(show: true, color: AppColors.neon.withValues(alpha: 0.1)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _barChart() {
    final data = state.presencasPorHorario();
    final entries = data.entries.toList();
    final maxVal = entries.fold<int>(0, (a, e) => a > e.value ? a : e.value);
    final maxY = (maxVal + 1).toDouble().clamp(3.0, 20.0);

    return PulguinhaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Presenças por horário (7d)', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.white, fontSize: 13)),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.border)),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                    final id = v.toInt();
                    final h = state.horarios.where((x) => x.id == id).firstOrNull;
                    return Padding(padding: const EdgeInsets.only(top: 6), child: Text(h?.hora ?? '', style: const TextStyle(fontSize: 9, color: AppColors.gray, fontWeight: FontWeight.w600)));
                  })),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24, getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10, color: AppColors.gray, fontWeight: FontWeight.w600)))),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [BarChartRodData(toY: e.value.toDouble(), color: AppColors.blue, width: 14, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _piePlanos() {
    final dist = state.distribuicaoPlanos();
    if (dist.isEmpty) return const SizedBox.shrink();
    final colors = [AppColors.neon, AppColors.blue, AppColors.yellow, AppColors.red];
    final sections = dist.entries.toList().asMap().entries.map((e) {
      final total = dist.values.fold<int>(0, (a, b) => a + b);
      final color = colors[e.key % colors.length];
      return PieChartSectionData(
        value: e.value.value.toDouble(),
        title: '${(e.value.value / total * 100).toStringAsFixed(0)}%',
        color: color,
        radius: 40,
        titleStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _pieLabelColor(color)),
      );
    }).toList();

    return PulguinhaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Planos', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.white, fontSize: 13, decoration: TextDecoration.none)),
          const SizedBox(height: 8),
          SizedBox(height: 110, child: PieChart(PieChartData(sections: sections, centerSpaceRadius: 22, sectionsSpace: 2))),
          const SizedBox(height: 8),
          ...dist.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('${e.key}: ${e.value}', style: const TextStyle(fontSize: 12, color: AppColors.white, fontWeight: FontWeight.w700, decoration: TextDecoration.none)),
              )),
        ],
      ),
    );
  }

  Color _pieLabelColor(Color sliceColor) {
    final luminance = sliceColor.computeLuminance();
    return luminance > 0.5 ? const Color(0xFF111111) : AppColors.white;
  }

  Widget _statusChart() {
    final mensalistasAtivos = state.alunos.where((a) => a.pagaMensalidade && a.status == 'Ativo').length;
    final inad = state.alunos.where((a) => a.pagaMensalidade && a.status == 'Inadimplente').length;
    final parceiros = state.alunosParceirosAtivos.length;
    final total = mensalistasAtivos + inad + parceiros;
    if (total == 0) return const SizedBox.shrink();

    return PulguinhaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mensalistas x Sem mensalidade',
            style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.white, fontSize: 13, decoration: TextDecoration.none),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 110,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: mensalistasAtivos.toDouble(),
                    color: AppColors.neon,
                    title: mensalistasAtivos > 0 ? '${(mensalistasAtivos / total * 100).toStringAsFixed(0)}%' : '',
                    radius: 42,
                    titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF111111)),
                  ),
                  if (inad > 0)
                    PieChartSectionData(
                      value: inad.toDouble(),
                      color: AppColors.red,
                      title: '${(inad / total * 100).toStringAsFixed(0)}%',
                      radius: 38,
                      titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.white),
                    ),
                  if (parceiros > 0)
                    PieChartSectionData(
                      value: parceiros.toDouble(),
                      color: AppColors.blue,
                      title: '${(parceiros / total * 100).toStringAsFixed(0)}%',
                      radius: 38,
                      titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.white),
                    ),
                ],
                centerSpaceRadius: 22,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('✅ $mensalistasAtivos mensalistas ativos', style: const TextStyle(fontSize: 12, color: AppColors.neon, fontWeight: FontWeight.w700, decoration: TextDecoration.none)),
          Text('⚠️ $inad inadimplentes', style: const TextStyle(fontSize: 12, color: AppColors.red, fontWeight: FontWeight.w700, decoration: TextDecoration.none)),
          Text('🎫 $parceiros sem mensalidade', style: const TextStyle(fontSize: 12, color: AppColors.blue, fontWeight: FontWeight.w700, decoration: TextDecoration.none)),
        ],
      ),
    );
  }

  Widget _aniversariantesSection() {
    final hoje = state.aniversariantesHoje();
    final proximos = state.aniversariantesProximos7Dias();

    if (hoje.isEmpty && proximos.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(icon: '🎂', title: 'Aniversariantes'),
        ...hoje.map((a) => _anivCard(a, 'Hoje! 🎉')),
        ...proximos.map((a) {
          final dias = DateHelper.diasAteAniversario(a.dataNascimento!);
          return _anivCard(a, 'Em $dias dias · ${DateHelper.formatarAniversario(a.dataNascimento!)}');
        }),
      ],
    );
  }

  Widget _anivCard(Aluno a, String sub) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PulguinhaCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Text('🎂', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            PulguinhaAvatar(initials: a.avatar, fotoBase64: a.foto),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.nome, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.white, fontSize: 13)),
                  Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.yellow)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
