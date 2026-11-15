/// DTO for updating user profile
class UpdateProfileRequest {
  final String? fullName;
  final String? phoneNumber;
  final String? avatarUrl;

  const UpdateProfileRequest({
    this.fullName,
    this.phoneNumber,
    this.avatarUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      if (fullName != null) 'full_name': fullName!.trim(),
      if (phoneNumber != null) 'phone_number': phoneNumber!.trim(),
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    };
  }
}
