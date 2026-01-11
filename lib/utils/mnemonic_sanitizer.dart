String sanitizeMnemonic(String mnemonic) {
  if (mnemonic == null) {
    return null;
  }

  return mnemonic.replaceAll(RegExp(r'\s+'), ' ').trim();
}

