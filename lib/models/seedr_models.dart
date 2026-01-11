class SeedrFolderResponse {
  final int spaceMax;
  final int spaceUsed;
  final int folderId;
  final String fullname;
  final String name;
  final int? parent;
  final List<SeedrFolder> folders;
  final List<SeedrFile> files;
  final List<SeedrTorrent> torrents;

  SeedrFolderResponse({
    required this.spaceMax,
    required this.spaceUsed,
    required this.folderId,
    required this.fullname,
    required this.name,
    this.parent,
    required this.folders,
    required this.files,
    required this.torrents,
  });

  factory SeedrFolderResponse.fromJson(Map<String, dynamic> json) {
    return SeedrFolderResponse(
      spaceMax: json['space_max'] ?? 0,
      spaceUsed: json['space_used'] ?? 0,
      folderId: json['folder_id'] ?? 0,
      fullname: json['fullname'] ?? '',
      name: json['name'] ?? '',
      parent: json['parent'] == -1 ? null : json['parent'],
      folders: (json['folders'] as List? ?? [])
          .map((i) => SeedrFolder.fromJson(i))
          .toList(),
      files: (json['files'] as List? ?? [])
          .map((i) => SeedrFile.fromJson(i))
          .toList(),
      torrents: (json['torrents'] as List? ?? [])
          .map((i) => SeedrTorrent.fromJson(i))
          .toList(),
    );
  }
}

class SeedrTorrent {
  final int id;
  final String name;
  final String folder;
  final int size;
  final String hash;
  final String progress;
  final String lastUpdate;

  SeedrTorrent({
    required this.id,
    required this.name,
    required this.folder,
    required this.size,
    required this.hash,
    required this.progress,
    required this.lastUpdate,
  });

  factory SeedrTorrent.fromJson(Map<String, dynamic> json) {
    return SeedrTorrent(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      folder: json['folder'] ?? '',
      size: json['size'] ?? 0,
      hash: json['hash'] ?? '',
      progress: json['progress']?.toString() ?? '0',
      lastUpdate: json['last_update'] ?? '',
    );
  }
}

class SeedrFolder {
  final int id;
  final String name;
  final String fullname;
  final int size;
  final String lastUpdate;

  SeedrFolder({
    required this.id,
    required this.name,
    required this.fullname,
    required this.size,
    required this.lastUpdate,
  });

  factory SeedrFolder.fromJson(Map<String, dynamic> json) {
    return SeedrFolder(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      fullname: json['fullname'] ?? '',
      size: json['size'] ?? 0,
      lastUpdate: json['last_update'] ?? '',
    );
  }
}

class SeedrFile {
  final String name;
  final int size;
  final String hash;
  final int folderId;
  final int folderFileId;
  final int fileId;
  final String lastUpdate;
  final bool playVideo;
  final String videoProgress;

  SeedrFile({
    required this.name,
    required this.size,
    required this.hash,
    required this.folderId,
    required this.folderFileId,
    required this.fileId,
    required this.lastUpdate,
    required this.playVideo,
    required this.videoProgress,
  });

  factory SeedrFile.fromJson(Map<String, dynamic> json) {
    return SeedrFile(
      name: json['name'] ?? '',
      size: json['size'] ?? 0,
      hash: json['hash'] ?? '',
      folderId: json['folder_id'] ?? 0,
      folderFileId: json['folder_file_id'] ?? 0,
      fileId: json['file_id'] ?? 0,
      lastUpdate: json['last_update'] ?? '',
      playVideo: json['play_video'] ?? false,
      videoProgress: json['video_progress'] ?? '0.00',
    );
  }
}

class SeedrFileDetails {
  final String url;
  final String name;
  final bool result;

  SeedrFileDetails({
    required this.url,
    required this.name,
    required this.result,
  });

  factory SeedrFileDetails.fromJson(Map<String, dynamic> json) {
    return SeedrFileDetails(
      url: json['url'] ?? '',
      name: json['name'] ?? '',
      result: json['result'] ?? false,
    );
  }
}

class SeedrArchiveResponse {
  final bool result;
  final int archiveId;
  final String archiveUrl;

  SeedrArchiveResponse({
    required this.result,
    required this.archiveId,
    required this.archiveUrl,
  });

  factory SeedrArchiveResponse.fromJson(Map<String, dynamic> json) {
    return SeedrArchiveResponse(
      result: json['result'] ?? false,
      archiveId: json['archive_id'] ?? 0,
      archiveUrl: json['archive_url'] ?? '',
    );
  }
}
