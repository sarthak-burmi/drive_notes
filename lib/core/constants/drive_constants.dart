class DriveConstants {
  static const String folderName = 'DriveNotes';
  static const String folderMimeType = 'application/vnd.google-apps.folder';
  static const String textFileMimeType = 'text/plain';
  static const String defaultNote = 'New Note';
  static const String fileExtension = '.txt';

  // Drive API endpoints
  static const String filesEndpoint =
      'https://www.googleapis.com/drive/v3/files';
  static const String uploadEndpoint =
      'https://www.googleapis.com/upload/drive/v3/files';

  // Query parameters
  static const String folderQuery =
      "mimeType='application/vnd.google-apps.folder' and name='DriveNotes' and trashed=false";
  static const String filesQuery =
      "mimeType='text/plain' and '%s' in parents and trashed=false";

  // Field parameters
  static const String folderFields = 'id,name';
  static const String fileFields = 'id,name,modifiedTime,createdTime';
}
