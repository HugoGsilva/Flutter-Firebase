import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class AvatarUsuario extends StatelessWidget {
  const AvatarUsuario({
    super.key,
    required this.nome,
    this.fotoUrl,
    this.radius = 24,
  });

  final String nome;
  final String? fotoUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final url = fotoUrl?.trim() ?? '';
    final diametro = radius * 2;
    final fallback = _IniciaisAvatar(nome: nome, radius: radius);

    if (url.isEmpty) {
      return fallback;
    }

    if (url.startsWith('data:')) {
      final bytes = _decodificarDataUrl(url);
      if (bytes == null || bytes.isEmpty) {
        return fallback;
      }
      return SizedBox(
        width: diametro,
        height: diametro,
        child: ClipOval(
          child: DecoratedBox(
            decoration: BoxDecoration(color: colorScheme.primaryContainer),
            child: Image.memory(
              bytes,
              width: diametro,
              height: diametro,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => fallback,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: diametro,
      height: diametro,
      child: ClipOval(
        child: DecoratedBox(
          decoration: BoxDecoration(color: colorScheme.primaryContainer),
          child: Image.network(
            url,
            width: diametro,
            height: diametro,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Stack(
                alignment: Alignment.center,
                children: [
                  fallback,
                  SizedBox(
                    width: radius * 0.7,
                    height: radius * 0.7,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              );
            },
            errorBuilder: (context, error, stackTrace) => fallback,
          ),
        ),
      ),
    );
  }

  static Uint8List? _decodificarDataUrl(String dataUrl) {
    final idx = dataUrl.indexOf('base64,');
    if (idx == -1) return null;
    try {
      return base64Decode(dataUrl.substring(idx + 7).trim());
    } catch (_) {
      return null;
    }
  }
}

class _IniciaisAvatar extends StatelessWidget {
  const _IniciaisAvatar({required this.nome, required this.radius});

  final String nome;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iniciais = _extrairIniciais(nome);

    return CircleAvatar(
      radius: radius,
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
      child: Text(
        iniciais,
        style: TextStyle(fontSize: radius * 0.72, fontWeight: FontWeight.bold),
      ),
    );
  }

  static String _extrairIniciais(String nome) {
    final partes = nome
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
  }
}
