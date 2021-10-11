class APIPath {
  static String users() => '/users';

  static String user(String id) => '/users/$id';

  static String chats() => '/chats';

  static String chat(String id) => '/chats/$id';

  static String messages() => '/messages';

  static String message(String id) => '/messages/$id';
}
