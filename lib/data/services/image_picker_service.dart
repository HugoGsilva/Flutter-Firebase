import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

class FotoSelecionada {
  const FotoSelecionada({
    required this.bytes,
    required this.nomeArquivo,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String nomeArquivo;
  final String mimeType;
}

abstract interface class ImagePickerService {
  Future<FotoSelecionada?> selecionarDaGaleria();
  Future<FotoSelecionada?> capturarDaCamera();
}

class ImagePickerServiceImpl implements ImagePickerService {
  ImagePickerServiceImpl({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<FotoSelecionada?> selecionarDaGaleria() {
    return _selecionar(ImageSource.gallery);
  }

  @override
  Future<FotoSelecionada?> capturarDaCamera() {
    return _selecionar(ImageSource.camera);
  }

  Future<FotoSelecionada?> _selecionar(ImageSource source) async {
    final arquivo = await _picker.pickImage(
      source: source,
      maxWidth: 320,
      maxHeight: 320,
      imageQuality: 70,
    );
    if (arquivo == null) return null;

    final bytes = await arquivo.readAsBytes();
    final nome = arquivo.name.trim().isNotEmpty ? arquivo.name : 'avatar.jpg';
    return FotoSelecionada(
      bytes: bytes,
      nomeArquivo: nome,
      mimeType: _inferirMimeType(arquivo.mimeType, nome),
    );
  }

  static String _inferirMimeType(String? informado, String nomeArquivo) {
    if (informado != null && informado.startsWith('image/')) {
      return informado;
    }
    final lower = nomeArquivo.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.heic') || lower.endsWith('.heif')) return 'image/heif';
    return 'image/jpeg';
  }
}
