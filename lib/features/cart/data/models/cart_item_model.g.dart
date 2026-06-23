// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_item_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CartItemModelAdapter extends TypeAdapter<CartItemModel> {
  @override
  final int typeId = 0;

  @override
  CartItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CartItemModel(
      productId: fields[0] as String,
      shopId: fields[1] as String,
      shopName: fields[2] as String,
      productName: fields[3] as String,
      imageUrl: fields[4] as String?,
      unitPrice: fields[5] as double,
      quantity: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, CartItemModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.productId)
      ..writeByte(1)
      ..write(obj.shopId)
      ..writeByte(2)
      ..write(obj.shopName)
      ..writeByte(3)
      ..write(obj.productName)
      ..writeByte(4)
      ..write(obj.imageUrl)
      ..writeByte(5)
      ..write(obj.unitPrice)
      ..writeByte(6)
      ..write(obj.quantity);
  }

###
  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItemModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
