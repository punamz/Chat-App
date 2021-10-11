String getChatId(String firstUserId, String secondUserId) {
  return firstUserId.compareTo(secondUserId) > 0
      ? '$firstUserId->$secondUserId'
      : '$secondUserId->$firstUserId';
}
