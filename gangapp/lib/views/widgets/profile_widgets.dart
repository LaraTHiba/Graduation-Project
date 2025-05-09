import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfileWidgets {
  static Widget buildTextField(
    String label,
    TextEditingController controller,
    bool isEditing,
    Color primaryColor,
    Color updatedFieldColor,
    Map<String, bool> editedFields,
    bool wasEdited, {
    int maxLines = 1,
    IconData? icon,
    Function()? onTap,
    bool readOnly = false,
  }) {
    bool wasFieldEdited = false;
    String fieldKey = '';

    if (label == 'Full Name') {
      fieldKey = 'full_name';
      wasFieldEdited = editedFields['full_name'] ?? false;
    } else if (label == 'Bio') {
      fieldKey = 'bio';
      wasFieldEdited = editedFields['bio'] ?? false;
    } else if (label == 'Location') {
      fieldKey = 'location';
      wasFieldEdited = editedFields['location'] ?? false;
    } else if (label == 'Date of Birth') {
      fieldKey = 'date_of_birth';
      wasFieldEdited = editedFields['date_of_birth'] ?? false;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.mukta(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          SizedBox(height: 8),
          isEditing
              ? TextFormField(
                  controller: controller,
                  maxLines: maxLines,
                  readOnly: readOnly,
                  onTap: onTap,
                  style: TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    prefixIcon:
                        icon != null ? Icon(icon, color: primaryColor) : null,
                    filled: false,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  validator: label == 'Full Name'
                      ? (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        }
                      : null,
                )
              : Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: wasFieldEdited && wasEdited
                        ? updatedFieldColor
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (icon != null) ...[
                        Icon(icon,
                            color: wasFieldEdited && wasEdited
                                ? primaryColor
                                : Colors.grey.shade600),
                        SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Text(
                          controller.text.isNotEmpty
                              ? controller.text
                              : 'Not specified',
                          style: TextStyle(
                            fontSize: 16,
                            color: wasFieldEdited && wasEdited
                                ? primaryColor
                                : Colors.black87,
                          ),
                        ),
                      ),
                      if (wasFieldEdited && wasEdited)
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Updated',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  static Widget buildEditableField(
    String label,
    TextEditingController controller,
    IconData icon,
    bool isEditing,
    Color primaryColor, {
    int maxLines = 1,
    bool readOnly = false,
    Function()? onTap,
    String? Function(String?)? validator,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
        SizedBox(height: 4),
        Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: isEditing ? Colors.grey[50] : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isEditing
                    ? primaryColor.withOpacity(0.3)
                    : Colors.grey[300]!,
              ),
            ),
            child: Row(
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Icon(icon, color: Colors.grey[400], size: 20),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: isEditing
                      ? TextFormField(
                          controller: controller,
                          maxLines: maxLines,
                          readOnly: readOnly,
                          onTap: onTap,
                          onChanged: onChanged,
                          validator: validator,
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey[800]),
                          decoration: InputDecoration(
                            prefixIcon: null,
                            filled: false,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: primaryColor, width: 2),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 12,
                            ),
                          ),
                        )
                      : Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                          child: Text(
                            controller.text.isNotEmpty
                                ? controller.text
                                : 'Not specified',
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey[400]),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget buildProfileIcon(
    bool isLoading,
    String? profilePictureUrl,
    double size,
  ) {
    if (isLoading) {
      return SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      );
    }

    if (profilePictureUrl != null && profilePictureUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          profilePictureUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.person_rounded, size: size, color: Colors.white);
          },
        ),
      );
    }

    return Icon(Icons.person_rounded, size: size, color: Colors.white);
  }

  static Widget buildProfileHeader(
    String? profilePictureUrl,
    String fullName,
    String username,
    Color primaryColor,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: profilePictureUrl != null && profilePictureUrl.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      profilePictureUrl,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.person_rounded,
                            size: 50, color: primaryColor);
                      },
                    ),
                  )
                : Icon(Icons.person_rounded, size: 50, color: primaryColor),
          ),
          SizedBox(height: 16),
          Text(
            fullName,
            style: GoogleFonts.mukta(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '@$username',
            style: GoogleFonts.mukta(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildBackgroundImage(
    File? backgroundImageFile,
    Uint8List? backgroundImageWeb,
    String? backgroundImageUrl,
    bool isEditing,
    Color primaryColor,
    Function() onImagePick,
  ) {
    return Container(
      height: 200,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (backgroundImageFile != null)
            Image.file(
              backgroundImageFile,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            )
          else if (backgroundImageWeb != null)
            Image.memory(
              backgroundImageWeb,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            )
          else if (backgroundImageUrl != null && backgroundImageUrl.isNotEmpty)
            Image.network(
              backgroundImageUrl,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: primaryColor);
              },
            )
          else
            Container(color: primaryColor),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
                stops: [0.4, 1.0],
              ),
            ),
          ),
          if (isEditing)
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton.small(
                onPressed: onImagePick,
                backgroundColor: primaryColor,
                child: Icon(Icons.camera_alt, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
