extension MapExt on Map {
  T? get<T>(dynamic key, {T Function(Map map)? converter}) {
    switch(T) {
      case int:
        return (dynamicToInt(this[key]) as T?);
      case double:
        return (dynamicToDouble(this[key]) as T?);
      case String:
        return (dynamicToString(this[key]) as T?);
      case Map:
        return this[key] is Map ? this[key] : null;
      default:
        final value = this[key];
        if(value is Map && converter != null) {
          return converter(value);
        }
        return value is T ? value: null;
    }
  }

  List<T> getList<T>(dynamic key, [T? Function(Map map)? converter]){
    final results = <T>[];

    final list = this[key];
    if (list is List) {
      for (final obj in list) {
        T? value;
        switch(T) {
          case int:
            value = dynamicToInt(obj) as T?;
            break;
          case double:
            value = dynamicToDouble(obj) as T?;
            break;
          case String:
            value = dynamicToString(obj) as T?;
            break;
          case bool:
            value = dynamicToBool(obj) as T;
            break;
          default:
            if(obj is Map && converter != null) {
              value = converter(obj);
            }
            break;
        }

        if(value != null) {
          results.add(value);
        }
      }
    }

    return results;
  }
}

int? dynamicToInt(dynamic value) {
  if (value is int) {
    return value;
  } else if (value is double) {
    return value.toInt();
  } else if (value is String) {
    return int.tryParse(value);
  } else {
    return null;
  }
}

double? dynamicToDouble(dynamic value) {
  if (value is double) {
    return value;
  } else if (value is int) {
    return value.toDouble();
  } else if (value is String) {
    return double.tryParse(value);
  } else {
    return null;
  }
}

String? dynamicToString(dynamic value) {
  if (value is String) {
    return value;
  } else {
    return value?.toString();
  }
}

bool dynamicToBool(dynamic value) {
  if (value is bool) {
    return value;
  } else {
    return false;
  }
}