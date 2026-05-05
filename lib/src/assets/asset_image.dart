class Asset<T> {
  const Asset({T? data, required this.path, this.package}) : _data = data;

  final T? _data;
  final String path;
  final String? package;

  T get data => _data!;
  set data(T data) => _data;
}
