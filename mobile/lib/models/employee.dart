import 'office.dart';

class Employee {
  final int id;
  final int officeId;
  final String nik;
  final String? phone;
  final Office? office;
  final String? photoUrl;

  Employee({
    required this.id,
    required this.officeId,
    required this.nik,
    this.phone,
    this.office,
    this.photoUrl,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'],
      officeId: json['office_id'],
      nik: json['nik'],
      phone: json['phone'],
      office: json['office'] != null ? Office.fromJson(json['office']) : null,
      photoUrl: json['photo_url'], // Assuming backend returns photo_url attribute
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'office_id': officeId,
      'nik': nik,
      'phone': phone,
      'office': office?.toJson(),
      'photo_url': photoUrl,
    };
  }
}
