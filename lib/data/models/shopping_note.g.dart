// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_note.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ShoppingNoteAdapter extends TypeAdapter<ShoppingNote> {
  @override
  final int typeId = 2;

  @override
  ShoppingNote read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ShoppingNote(
      id: fields[0] as String?,
      storeName: fields[1] as String,
      storeEmoji: fields[2] as String,
      date: fields[3] as DateTime,
      address: fields[4] as String,
      items: (fields[5] as List?)?.cast<ShoppingItem>(),
      photoUrl: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ShoppingNote obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.storeName)
      ..writeByte(2)
      ..write(obj.storeEmoji)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.address)
      ..writeByte(5)
      ..write(obj.items)
      ..writeByte(6)
      ..write(obj.photoUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShoppingNoteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
