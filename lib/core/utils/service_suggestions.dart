const _serviceUrls = <String, String>{
  'google': 'google.com',
  'gmail': 'mail.google.com',
  'youtube': 'youtube.com',
  'facebook': 'facebook.com',
  'instagram': 'instagram.com',
  'twitter': 'twitter.com',
  'x': 'x.com',
  'tiktok': 'tiktok.com',
  'snapchat': 'snapchat.com',
  'linkedin': 'linkedin.com',
  'reddit': 'reddit.com',
  'pinterest': 'pinterest.com',
  'whatsapp': 'web.whatsapp.com',
  'telegram': 'web.telegram.org',
  'discord': 'discord.com',
  'slack': 'slack.com',
  'netflix': 'netflix.com',
  'spotify': 'spotify.com',
  'apple': 'apple.com',
  'icloud': 'icloud.com',
  'amazon': 'amazon.com',
  'ebay': 'ebay.com',
  'paypal': 'paypal.com',
  'stripe': 'stripe.com',
  'shopify': 'shopify.com',
  'etsy': 'etsy.com',
  'github': 'github.com',
  'gitlab': 'gitlab.com',
  'bitbucket': 'bitbucket.org',
  'heroku': 'heroku.com',
  'vercel': 'vercel.com',
  'netlify': 'netlify.com',
  'digitalocean': 'digitalocean.com',
  'aws': 'aws.amazon.com',
  'microsoft': 'microsoft.com',
  'outlook': 'outlook.com',
  'office365': 'office.com',
  'dropbox': 'dropbox.com',
  'notion': 'notion.so',
  'airtable': 'airtable.com',
  'figma': 'figma.com',
  'canva': 'canva.com',
  'adobe': 'adobe.com',
  'zoom': 'zoom.us',
  'teams': 'teams.microsoft.com',
  'trello': 'trello.com',
  'jira': 'atlassian.net',
  'confluence': 'atlassian.net',
  'chase': 'chase.com',
  'wellsfargo': 'wellsfargo.com',
  'bankofamerica': 'bankofamerica.com',
  'coinbase': 'coinbase.com',
  'binance': 'binance.com',
  'robinhood': 'robinhood.com',
  'steam': 'store.steampowered.com',
  'epic': 'epicgames.com',
  'playstation': 'playstation.com',
  'xbox': 'xbox.com',
  'nintendo': 'nintendo.com',
  'hulu': 'hulu.com',
  'disney': 'disneyplus.com',
  'hbo': 'hbomax.com',
  'twitch': 'twitch.tv',
  'wordpress': 'wordpress.com',
  'medium': 'medium.com',
  'substack': 'substack.com',
};

/// Returns a suggested URL for the given service name, or null if unknown.
String? suggestServiceUrl(String serviceName) {
  final key = serviceName.trim().toLowerCase().replaceAll(' ', '');
  if (key.isEmpty) return null;
  if (_serviceUrls.containsKey(key)) return 'https://${_serviceUrls[key]!}';
  for (final entry in _serviceUrls.entries) {
    if (entry.key.startsWith(key) || key.startsWith(entry.key)) {
      return 'https://${entry.value}';
    }
  }
  if (!key.contains('.') && key.length >= 3) {
    return 'https://$key.com';
  }
  return null;
}
