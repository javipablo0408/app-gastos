import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:app_contabilidad/core/providers/providers.dart';
import 'package:app_contabilidad/presentation/viewmodels/categories_viewmodel.dart';
import 'package:app_contabilidad/data/services/search_service.dart';
import 'package:app_contabilidad/core/router/app_router.dart';

/// Estado de búsqueda
class SearchState {
  final SearchResult? result;
  final bool isSearching;
  final String? error;
  final List<String> searchHistory;

  SearchState({
    this.result,
    this.isSearching = false,
    this.error,
    this.searchHistory = const [],
  });

  SearchState copyWith({
    SearchResult? result,
    bool? isSearching,
    String? error,
    List<String>? searchHistory,
  }) {
    return SearchState(
      result: result ?? this.result,
      isSearching: isSearching ?? this.isSearching,
      error: error ?? this.error,
      searchHistory: searchHistory ?? this.searchHistory,
    );
  }
}

/// ViewModel de búsqueda
class SearchViewModel extends StateNotifier<SearchState> {
  final SearchService _searchService;

  SearchViewModel(this._searchService) : super(SearchState());

  /// Realiza una búsqueda
  Future<void> search(SearchCriteria criteria) async {
    state = state.copyWith(isSearching: true, error: null);

    final result = await _searchService.search(criteria);

    result.fold(
      (failure) {
        state = state.copyWith(
          isSearching: false,
          error: failure.toString(),
        );
      },
      (searchResult) {
        state = state.copyWith(
          result: searchResult,
          isSearching: false,
        );
      },
    );
  }

  /// Búsqueda rápida por texto
  Future<void> quickSearch(String query) async {
    if (query.isEmpty) {
      state = state.copyWith(result: null);
      return;
    }

    await search(SearchCriteria(query: query));
  }
}

/// Provider del ViewModel de búsqueda
final searchViewModelProvider =
    StateNotifierProvider<SearchViewModel, SearchState>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  final searchService = SearchService(databaseService);
  return SearchViewModel(searchService);
});

/// Página de búsqueda avanzada
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _searchController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedCategoryId;
  double? _minAmount;
  double? _maxAmount;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchViewModelProvider);
    final searchViewModel = ref.read(searchViewModelProvider.notifier);
    final categoriesState = ref.watch(categoriesViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Búsqueda Avanzada'),
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar en descripciones...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          searchViewModel.quickSearch('');
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                searchViewModel.quickSearch(value);
              },
            ),
          ),

          // Filtros
          ExpansionTile(
            title: const Text('Filtros Avanzados'),
            children: [
              // Fechas
              ListTile(
                title: const Text('Fecha inicio'),
                subtitle: Text(
                  _startDate != null
                      ? DateFormat('dd/MM/yyyy').format(_startDate!)
                      : 'Seleccionar',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _startDate = date);
                    _performSearch(searchViewModel);
                  }
                },
              ),
              ListTile(
                title: const Text('Fecha fin'),
                subtitle: Text(
                  _endDate != null
                      ? DateFormat('dd/MM/yyyy').format(_endDate!)
                      : 'Seleccionar',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _endDate ?? DateTime.now(),
                    firstDate: _startDate ?? DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _endDate = date);
                    _performSearch(searchViewModel);
                  }
                },
              ),

              // Categoría
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todas')),
                  ...categoriesState.categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat.id,
                      child: Text(cat.name),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() => _selectedCategoryId = value);
                  _performSearch(searchViewModel);
                },
              ),

              // Montos
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Monto mínimo',
                          prefixText: '\$ ',
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        onChanged: (value) {
                          _minAmount = double.tryParse(value);
                          _performSearch(searchViewModel);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Monto máximo',
                          prefixText: '\$ ',
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        onChanged: (value) {
                          _maxAmount = double.tryParse(value);
                          _performSearch(searchViewModel);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Resultados
          Expanded(
            child: searchState.isSearching
                ? const Center(child: CircularProgressIndicator())
                : searchState.error != null
                    ? Center(child: Text('Error: ${searchState.error}'))
                    : searchState.result == null
                        ? const Center(
                            child: Text('Ingresa un término de búsqueda'),
                          )
                        : searchState.result!.totalCount == 0
                            ? const Center(
                                child: Text('No se encontraron resultados'),
                              )
                            : _buildResults(context, searchState.result!),
          ),
        ],
      ),
    );
  }

  void _performSearch(SearchViewModel viewModel) {
    viewModel.search(SearchCriteria(
      query: _searchController.text.isEmpty ? null : _searchController.text,
      startDate: _startDate,
      endDate: _endDate,
      categoryId: _selectedCategoryId,
      minAmount: _minAmount,
      maxAmount: _maxAmount,
    ));
  }

  Widget _buildResults(BuildContext context, SearchResult result) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (result.expenses.isNotEmpty) ...[
          const Text(
            'Gastos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...result.expenses.map((expense) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.arrow_downward, color: Colors.red),
                title: Text(expense.description),
                subtitle: Text(
                  '${expense.category?.name ?? 'Sin categoría'} • ${dateFormat.format(expense.date)}',
                ),
                trailing: Text(
                  currencyFormat.format(expense.amount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                onTap: () => context.push('/expenses/${expense.id}'),
              ),
            );
          }),
          const SizedBox(height: 16),
        ],
        if (result.incomes.isNotEmpty) ...[
          const Text(
            'Ingresos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...result.incomes.map((income) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.arrow_upward, color: Colors.green),
                title: Text(income.description),
                subtitle: Text(
                  '${income.category?.name ?? 'Sin categoría'} • ${dateFormat.format(income.date)}',
                ),
                trailing: Text(
                  currencyFormat.format(income.amount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                onTap: () => context.push('/incomes/${income.id}'),
              ),
            );
          }),
        ],
      ],
    );
  }
}

