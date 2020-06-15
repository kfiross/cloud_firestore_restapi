///
/// Op to connect Query fields
///
enum FilterOp {
  NotSpecified,
  AND,
  OR, // Not implemented
}

///
/// Logincal between a field and its value
///
enum FieldOp {
  OPERATOR_UNSPECIFIED,
  LESS_THAN,
  LESS_THAN_OR_EQUAL,
  GREATER_THAN,
  GREATER_THAN_OR_EQUAL,
  EQUAL,
  ARRAY_CONTAINS,
  IN,
  ARRAY_CONTAINS_ANY,
}

///
/// Defines a query argument
///
class Query {
  final String field;
  final FieldOp op;
  final dynamic value;
  final FilterOp connector; // not implemented
  Query({
    this.field,
    this.op = FieldOp.EQUAL,
    this.value,
    this.connector = FilterOp.NotSpecified,
  });
}
