class VehicleMaster {
  final int? id;
  final String vehicleModel;
  final String customerPartNo;
  final String partNo;
  final String dateOfMfg;
  final String fixedQrCode;
  final String companyLogo;

  VehicleMaster({
    this.id,
    required this.vehicleModel,
    required this.customerPartNo,
    required this.partNo,
    required this.dateOfMfg,
    required this.fixedQrCode,
    this.companyLogo = 'none',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicle_model': vehicleModel,
      'customer_part_no': customerPartNo,
      'part_no': partNo,
      'date_of_mfg': dateOfMfg,
      'fixed_qr_code': fixedQrCode,
      'company_logo': companyLogo,
    };
  }

  factory VehicleMaster.fromMap(Map<String, dynamic> map) {
    return VehicleMaster(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id']?.toString() ?? ''),
      vehicleModel: map['vehicle_model']?.toString() ?? '',
      customerPartNo: map['customer_part_no']?.toString() ?? '',
      partNo: map['part_no']?.toString() ?? '',
      dateOfMfg: map['date_of_mfg']?.toString() ?? '',
      fixedQrCode: map['fixed_qr_code']?.toString() ?? '',
      companyLogo: map['company_logo']?.toString() ?? 'none',
    );
  }
}

class PrintHistoryRecord {
  final int? id;
  final String vehicleModel;
  final String customerPartNo;
  final String partNo;
  final String dateOfMfg;
  final String serialNo;
  final String fullQrData;
  final String printedAt;
  final String companyLogo;

  PrintHistoryRecord({
    this.id,
    required this.vehicleModel,
    required this.customerPartNo,
    required this.partNo,
    required this.dateOfMfg,
    required this.serialNo,
    required this.fullQrData,
    required this.printedAt,
    this.companyLogo = 'none',
  });

  factory PrintHistoryRecord.fromMap(Map<String, dynamic> map) {
    return PrintHistoryRecord(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id']?.toString() ?? ''),
      vehicleModel: map['vehicle_model']?.toString() ?? '',
      customerPartNo: map['customer_part_no']?.toString() ?? '',
      partNo: map['part_no']?.toString() ?? '',
      dateOfMfg: map['date_of_mfg']?.toString() ?? '',
      serialNo: map['serial_no']?.toString() ?? '',
      fullQrData: map['full_qr_data']?.toString() ?? '',
      printedAt: map['printed_at']?.toString() ?? '',
      companyLogo: map['company_logo']?.toString() ?? 'none',
    );
  }
}