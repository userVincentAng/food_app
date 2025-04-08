class OrderingDeviceRequest {
  final int requestType;
  final String methodName;
  final SavedCartItem savedCartItems;
  final dynamic
      predefinedTicket; // Using dynamic for now since MerchantPreDefTickets is not defined

  OrderingDeviceRequest({
    required this.requestType,
    required this.methodName,
    required this.savedCartItems,
    this.predefinedTicket,
  });

  Map<String, dynamic> toJson() {
    return {
      'requestType': requestType,
      'methodName': methodName,
      'savedCartItems': savedCartItems.toJson(),
      'predifinedTicket': predefinedTicket,
    };
  }
}

class SavedCartItem {
  final String guidId;
  final String name;
  final String comments;
  final List<Map<String, dynamic>> cartItems;
  final String savedDate;
  final String savedBy;
  final String savedByUserId;
  final String todaysOrderNo;
  final bool isDeleted;
  final String? deletedBy;
  final int openTicketStatusId;
  final bool isSynced;
  final bool isBillPrinted;
  final double total;
  final bool isOSPrinted;
  final bool isMerged;
  final List<dynamic>? mergedChildTables;
  final String? textDuration;
  final String? cartOrderNo;

  SavedCartItem({
    required this.guidId,
    required this.name,
    required this.comments,
    required this.cartItems,
    required this.savedDate,
    required this.savedBy,
    required this.savedByUserId,
    required this.todaysOrderNo,
    this.isDeleted = false,
    this.deletedBy,
    required this.openTicketStatusId,
    this.isSynced = false,
    this.isBillPrinted = false,
    required this.total,
    this.isOSPrinted = false,
    this.isMerged = false,
    this.mergedChildTables,
    this.textDuration,
    this.cartOrderNo,
  });

  Map<String, dynamic> toJson() {
    return {
      'guidId': guidId,
      'name': name,
      'comments': comments,
      'cartItems': cartItems,
      'savedDate': savedDate,
      'savedBy': savedBy,
      'savedByUserId': savedByUserId,
      'todaysOrderNo': todaysOrderNo,
      'isDeleted': isDeleted,
      'deletedBy': deletedBy,
      'openTicketStatusId': openTicketStatusId,
      'isSynced': isSynced,
      'isBillPrinted': isBillPrinted,
      'total': total,
      'isOSPrinted': isOSPrinted,
      'isMerged': isMerged,
      'mergedChildTables': mergedChildTables,
      'textDuration': textDuration,
      'cartOrderNo': cartOrderNo,
    };
  }
}
