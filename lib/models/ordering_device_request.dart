import 'package:flutter/foundation.dart';

class OrderingDeviceRequest {
  final int requestType;
  final SavedCartItem? savedCartItems;
  final dynamic
      predefinedTicket; // Using dynamic for now since MerchantPreDefTickets is not defined

  OrderingDeviceRequest({
    required this.requestType,
    this.savedCartItems,
    this.predefinedTicket,
  });

  Map<String, dynamic> toJson() {
    return {
      'RequestType': requestType,
      'savedCartItems': savedCartItems?.toJson(),
      'predifinedTicket': predefinedTicket,
    };
  }
}

class SavedCartItem {
  final String? guidId;
  final String name;
  final String comments;
  final List<dynamic> cartItems;
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
    this.guidId,
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
      'GuidId': guidId,
      'Name': name,
      'Comments': comments,
      'cartitem': cartItems,
      'SavedDate': savedDate,
      'SavedBy': savedBy,
      'SavedByUserId': savedByUserId,
      'TodaysOrderNo': todaysOrderNo,
      'IsDeleted': isDeleted,
      'DeletedBy': deletedBy,
      'OpenTicketStatusId': openTicketStatusId,
      'IsSynced': isSynced,
      'IsBillPrinted': isBillPrinted,
      'Total': total,
      'IsOSPrinted': isOSPrinted,
      'IsMerged': isMerged,
      'MergedChildTables': mergedChildTables,
      'TextDuration': textDuration,
      'CartOrderNo': cartOrderNo,
    };
  }
}
