import 'package:smart_market_list/data/models/shopping_item.dart';

class PresetItem {
  final String name;
  final String category;
  final String imageUrl;
  final String defaultQuantity;

  const PresetItem({
    required this.name,
    required this.category,
    required this.imageUrl,
    this.defaultQuantity = '1 un',
  });
}

class PresetItems {
  static const List<PresetItem> all = [
    // Hortifruti
    PresetItem(name: 'Tomate', category: 'hortifruti', imageUrl: 'https://images.unsplash.com/photo-1621332606136-7e66f02dade1?w=400', defaultQuantity: '1 kg'),
    PresetItem(name: 'Alface', category: 'hortifruti', imageUrl: 'https://images.unsplash.com/photo-1657411658279-e32af8636eb1?w=400'),
    PresetItem(name: 'Banana', category: 'hortifruti', imageUrl: 'https://images.unsplash.com/photo-1603833665858-e61d17a86224?w=400', defaultQuantity: '1 dz'),
    PresetItem(name: 'Batata', category: 'hortifruti', imageUrl: 'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=400', defaultQuantity: '1 kg'),
    PresetItem(name: 'Cebola', category: 'hortifruti', imageUrl: 'https://images.unsplash.com/photo-1620574387735-3624d75b2dbc?w=400', defaultQuantity: '1 kg'),
    PresetItem(name: 'Cenoura', category: 'hortifruti', imageUrl: 'https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?w=400', defaultQuantity: '500g'),
    PresetItem(name: 'Maçã', category: 'hortifruti', imageUrl: 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=400', defaultQuantity: '1 kg'),
    PresetItem(name: 'Laranja', category: 'hortifruti', imageUrl: 'https://images.unsplash.com/photo-1611080626919-7cf5a9dbab5b?w=400', defaultQuantity: '1 kg'),

    // Padaria
    PresetItem(name: 'Pão Francês', category: 'padaria', imageUrl: 'https://images.unsplash.com/photo-1598373182133-52452f7691ef?w=400', defaultQuantity: '5 un'),
    PresetItem(name: 'Pão de Forma', category: 'padaria', imageUrl: 'https://images.unsplash.com/photo-1728670212431-ac192413f4b1?w=400'),
    PresetItem(name: 'Bolo', category: 'padaria', imageUrl: 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=400'),
    PresetItem(name: 'Croissant', category: 'padaria', imageUrl: 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=400'),

    // Laticínios
    PresetItem(name: 'Leite Integral', category: 'laticinios', imageUrl: 'https://images.unsplash.com/photo-1576186726115-4d51596775d1?w=400', defaultQuantity: '1 L'),
    PresetItem(name: 'Queijo Minas', category: 'laticinios', imageUrl: 'https://images.unsplash.com/photo-1707226585034-14e6d746ed95?w=400', defaultQuantity: '500g'),
    PresetItem(name: 'Iogurte', category: 'laticinios', imageUrl: 'https://images.unsplash.com/photo-1563379926898-05f4575a45d8?w=400'),
    PresetItem(name: 'Manteiga', category: 'laticinios', imageUrl: 'https://images.unsplash.com/photo-1589985270826-4b7bb135bc9d?w=400', defaultQuantity: '200g'),
    PresetItem(name: 'Requeijão', category: 'laticinios', imageUrl: 'https://images.unsplash.com/photo-1628193479337-420755651a77?w=400'),

    // Outros
    PresetItem(name: 'Arroz', category: 'outros', imageUrl: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=400', defaultQuantity: '5 kg'),
    PresetItem(name: 'Feijão', category: 'outros', imageUrl: 'https://images.unsplash.com/photo-1589992373834-9eb4fc4d8fbe?w=400', defaultQuantity: '1 kg'),
    PresetItem(name: 'Macarrão', category: 'outros', imageUrl: 'https://images.unsplash.com/photo-1612929633738-8fe44f7ec841?w=400', defaultQuantity: '500g'),
    PresetItem(name: 'Óleo', category: 'outros', imageUrl: 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=400', defaultQuantity: '900ml'),
    PresetItem(name: 'Açúcar', category: 'outros', imageUrl: 'https://images.unsplash.com/photo-1612155692269-c352f4853603?w=400', defaultQuantity: '1 kg'),
    PresetItem(name: 'Sal', category: 'outros', imageUrl: 'https://images.unsplash.com/photo-1518110925412-13547f384650?w=400', defaultQuantity: '1 kg'),
    PresetItem(name: 'Café', category: 'outros', imageUrl: 'https://images.unsplash.com/photo-1559056199-641a0ac8b55e?w=400', defaultQuantity: '500g'),
    PresetItem(name: 'Sabão em Pó', category: 'outros', imageUrl: 'https://images.unsplash.com/photo-1585837575652-267c041d77d4?w=400', defaultQuantity: '1 kg'),
    PresetItem(name: 'Detergente', category: 'outros', imageUrl: 'https://images.unsplash.com/photo-1535581652167-3d6b98c4657e?w=400', defaultQuantity: '500ml'),
    PresetItem(name: 'Papel Higiênico', category: 'outros', imageUrl: 'https://images.unsplash.com/photo-1584556812952-905ffd0c611f?w=400', defaultQuantity: '12 un'),
  ];
}
