import 'dart:typed_data';

import '../../../core/result/app_exception.dart';
import '../../../core/result/result.dart';
import '../../models/usuario_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/preference_repository.dart';

class AtualizarFotoPerfilUseCase {
  const AtualizarFotoPerfilUseCase(this._repository, this._preferences);

  static const int tamanhoMaximoBytes = 600 * 1024;
  static const Set<String> mimeTypesPermitidos = {
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
    'image/gif',
    'image/heif',
    'image/heic',
    'image/avif',
  };

  final AuthRepository _repository;
  final PreferenceRepository _preferences;

  Future<Result<UsuarioModel>> call({
    required Uint8List bytes,
    required String nomeArquivo,
    required String mimeType,
  }) async {
    if (_repository.usuarioAtual == null) {
      return const Failure(AppException('Você precisa estar autenticado.'));
    }
    if (bytes.isEmpty) {
      return const Failure(FormatException('A imagem selecionada está vazia.'));
    }
    if (bytes.length > tamanhoMaximoBytes) {
      return const Failure(
        FormatException('A foto escolhida deve ter no máximo 600 KB.'),
      );
    }

    final mimeNormalizado = mimeType.trim().toLowerCase();
    if (!mimeTypesPermitidos.contains(mimeNormalizado)) {
      return const Failure(
        FormatException(
          'Formato inválido. Escolha uma imagem PNG, JPEG ou WebP.',
        ),
      );
    }

    try {
      final atualizado = await _repository.atualizarFotoPerfil(
        bytes: bytes,
        nomeArquivo: nomeArquivo,
        mimeType: mimeNormalizado,
      );
      await _preferences.salvarUsuarioEmCache(atualizado);
      return Success(atualizado);
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
