param(
  [string]$CookieFile = (Join-Path $PSScriptRoot "..\x-cookie.txt"),
  [string]$ScreenName = "agrippa_muse",
  [int]$Count = 40
)

$ErrorActionPreference = "Stop"
$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$mediaDir = Join-Path $root "assets\x-media"
New-Item -ItemType Directory -Force -Path $mediaDir | Out-Null

if (-not (Test-Path $CookieFile)) {
  throw "Cookie file not found: $CookieFile"
}

function Get-CookieValue([string]$name) {
  $line = Select-String -Path $CookieFile -Pattern "`t$name`t" | Select-Object -First 1
  if (-not $line) { return $null }
  return $line.Line.Split("`t")[-1]
}

$ct0 = Get-CookieValue "ct0"
if (-not $ct0) { throw "Missing ct0 in cookie file." }

$verifyCode = curl.exe -s -o "$env:TEMP\x-verify.json" -w "%{http_code}" -b $CookieFile `
  -H "x-csrf-token: $ct0" `
  -H "authorization: Bearer AAAAAAAAAAAAAAAAAAAAANRILgAAAAAAnNwIzUejRCOuH5E6I8xnZz4puTs%3D1Zv7ttfk8LF81IUq15cAXjuA5PwYzCMAlBE97DOXPvAj3PwXunAZ41g%3D%3D" `
  "https://api.x.com/1.1/account/verify_credentials.json"

if ($verifyCode -ne "200") {
  throw "X cookie is invalid or expired (verify returned $verifyCode). Export a fresh Netscape cookie file from x.com while logged in."
}

$userVars = [uri]::EscapeDataString((@{ screen_name = $ScreenName } | ConvertTo-Json -Compress))
$userFeatures = [uri]::EscapeDataString('{"hidden_profile_subscriptions_enabled":true,"profile_label_improvements_pcf_label_in_post_enabled":true,"rweb_tipjar_consumption_enabled":true,"responsive_web_graphql_exclude_directive_enabled":true,"verified_phone_label_enabled":false,"subscriptions_verification_info_is_identity_verified_enabled":true,"subscriptions_verification_info_verified_since_enabled":true,"highlights_tweets_tab_ui_enabled":true,"responsive_web_twitter_article_notes_tab_enabled":true,"subscriptions_feature_can_gift_premium":true,"creator_subscriptions_tweet_preview_api_enabled":true,"responsive_web_graphql_skip_user_profile_image_extensions_enabled":false,"responsive_web_graphql_timeline_navigation_enabled":true}')
$userUrl = "https://x.com/i/api/graphql/-0XdXL-mrqLtgTirPLEtFA/UserByScreenName?variables=$userVars&features=$userFeatures"

$userJson = curl.exe -s -b $CookieFile -H "x-csrf-token: $ct0" -H "authorization: Bearer AAAAAAAAAAAAAAAAAAAAANRILgAAAAAAnNwIzUejRCOuH5E6I8xnZz4puTs%3D1Zv7ttfk8LF81IUq15cAXjuA5PwYzCMAlBE97DOXPvAj3PwXunAZ41g%3D%3D" -H "x-twitter-active-user: yes" -H "x-twitter-auth-type: OAuth2Session" -H "referer: https://x.com/$ScreenName" $userUrl | ConvertFrom-Json
$userId = $userJson.data.user.result.rest_id
if (-not $userId) { throw "Could not resolve user id for @$ScreenName." }

$tweetVars = [uri]::EscapeDataString((@{
  userId = $userId
  count = $Count
  includePromotedContent = $true
  withQuickPromoteEligibilityTweetFields = $true
  withVoice = $true
} | ConvertTo-Json -Compress))
$features = [uri]::EscapeDataString('{"rweb_tipjar_consumption_enabled":true,"responsive_web_graphql_exclude_directive_enabled":true,"verified_phone_label_enabled":false,"creator_subscriptions_tweet_preview_api_enabled":true,"responsive_web_graphql_timeline_navigation_enabled":true,"responsive_web_graphql_skip_user_profile_image_extensions_enabled":false,"communities_web_enable_tweet_community_results_fetch":true,"c9s_tweet_anatomy_moderator_badge_enabled":true,"articles_preview_enabled":true,"responsive_web_edit_tweet_api_enabled":true,"graphql_is_translatable_rweb_tweet_is_translatable_enabled":true,"view_counts_everywhere_api_enabled":true,"longform_notetweets_consumption_enabled":true,"responsive_web_twitter_article_tweet_consumption_enabled":true,"tweet_awards_web_tipping_enabled":false,"creator_subscriptions_quote_tweet_preview_enabled":false,"freedom_of_speech_not_reach_fetch_enabled":true,"standardized_n_pics_mrs_enabled":true,"tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled":true,"rweb_video_timestamps_enabled":true,"longform_notetweets_rich_text_read_enabled":true,"longform_notetweets_inline_media_enabled":true,"responsive_web_enhance_cards_enabled":false}')
$tweetsUrl = "https://x.com/i/api/graphql/Vhap_MeNwMYMlSwDhN_uaA/UserTweets?variables=$tweetVars&features=$features"
$tweetsRaw = curl.exe -s -b $CookieFile -H "x-csrf-token: $ct0" -H "authorization: Bearer AAAAAAAAAAAAAAAAAAAAANRILgAAAAAAnNwIzUejRCOuH5E6I8xnZz4puTs%3D1Zv7ttfk8LF81IUq15cAXjuA5PwYzCMAlBE97DOXPvAj3PwXunAZ41g%3D%3D" -H "x-twitter-active-user: yes" -H "x-twitter-auth-type: OAuth2Session" -H "referer: https://x.com/$ScreenName" $tweetsUrl
$tweetsPath = Join-Path $root "assets\x-timeline.json"
Set-Content -Path $tweetsPath -Value $tweetsRaw -Encoding utf8

$matches = [regex]::Matches($tweetsRaw, 'https://pbs\.twimg\.com/media/[^"\\]+')
$videos = [regex]::Matches($tweetsRaw, 'https://video\.twimg\.com/[^"\\]+')
$index = 0
foreach ($m in $matches) {
  $index++
  $url = $m.Value -replace '\\u0026', '&'
  $ext = if ($url -match '\.(jpg|png|webp|gif)') { $Matches[1] } else { 'jpg' }
  $out = Join-Path $mediaDir ("post-{0:D2}.{1}" -f $index, $ext)
  curl.exe -s -L $url -o $out | Out-Null
}
$vIndex = 0
foreach ($m in $videos) {
  $vIndex++
  $url = $m.Value -replace '\\u0026', '&'
  if ($url -notmatch '\.mp4') { continue }
  $out = Join-Path $mediaDir ("clip-{0:D2}.mp4" -f $vIndex)
  curl.exe -s -L $url -o $out | Out-Null
}

Write-Host "Saved timeline JSON to assets/x-timeline.json"
Write-Host "Downloaded $($index) images and $($vIndex) videos to assets/x-media/"
