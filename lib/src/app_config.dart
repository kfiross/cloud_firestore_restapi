class AppConfig{
  final String projectId;
  final String webKey;
  final String baseUrl;
  String _idToken;

  AppConfig(this.projectId, this.webKey, this.baseUrl);

  String get idToken => _idToken;

  setToken(token){
    _idToken = token;
  }
}