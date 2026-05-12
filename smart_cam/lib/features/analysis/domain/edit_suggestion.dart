class EditSuggestion {
  final List<String> filterSuggestions;
  final Map<String, dynamic> editParams;

  const EditSuggestion({
    required this.filterSuggestions,
    required this.editParams,
  });

  factory EditSuggestion.fromJson(Map<String, dynamic> json) {
    return EditSuggestion(
      filterSuggestions: List<String>.from(json['filter_suggestions'] ?? []),
      editParams: Map<String, dynamic>.from(json['edit_params'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filter_suggestions': filterSuggestions,
      'edit_params': editParams,
    };
  }
}
