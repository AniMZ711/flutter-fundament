/// One-way mapping from a data-layer [Input] (e.g. a JSON model) to a
/// domain-layer [Output] (e.g. an entity). Implemented per model as a
/// standalone, DI-registered class rather than as a method on the model,
/// so mapping logic stays independently unit-testable and mockable.
abstract class Mapper<Input, Output> {
  /// Maps [input] to its [Output] representation.
  Output map(Input input);
}
