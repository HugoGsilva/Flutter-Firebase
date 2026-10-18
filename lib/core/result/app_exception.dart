class AppException implements Exception {
  const AppException(this.mensagem);

  final String mensagem;

  @override
  String toString() => mensagem;
}

String mensagemDoErro(Exception erro) {
  if (erro is AppException) return erro.mensagem;
  if (erro is FormatException) return erro.message;
  final texto = erro.toString();
  return texto.startsWith('Exception: ') ? texto.substring(11) : texto;
}
