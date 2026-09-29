import 'package:freezed_annotation/freezed_annotation.dart';

part 'envelope.freezed.dart';
part 'envelope.g.dart';

enum SecretType {
  @JsonValue('mnemonic')
  mnemonic,
  @JsonValue('privateKey')
  privateKey,
}

/// Serializes with a flat `"alg"` discriminator, matching CLAUDE.md's
/// envelope format exactly (`{"alg": "argon2id", "m": ..., "t": ..., "p": ...}`).
@Freezed(unionKey: 'alg')
sealed class KdfParams with _$KdfParams {
  @FreezedUnionValue('argon2id')
  const factory KdfParams.argon2id({
    required int m,
    required int t,
    required int p,
  }) = Argon2idParams;

  @FreezedUnionValue('pbkdf2HmacSha256')
  const factory KdfParams.pbkdf2HmacSha256({
    required int iterations,
  }) = Pbkdf2Params;

  factory KdfParams.fromJson(Map<String, Object?> json) =>
      _$KdfParamsFromJson(json);
}

/// The PIN-layer envelope, exactly as specified in CLAUDE.md, before the
/// hardware wrap is applied. Serialized to JSON, then wrapped by
/// [VaultKeystore] before being written to secure storage — this class
/// itself is never persisted unwrapped.
@freezed
sealed class Envelope with _$Envelope {
  const factory Envelope({
    @Default(1) int v,
    required String walletId,
    required SecretType type,
    required KdfParams kdf,
    // base64
    required String salt,
    // base64
    required String nonce,
    // base64 (ciphertext + 16-byte GCM tag)
    required String ct,
  }) = _Envelope;

  factory Envelope.fromJson(Map<String, Object?> json) =>
      _$EnvelopeFromJson(json);
}
