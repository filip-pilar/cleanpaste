// THE RULES. This file is data only: every tracking parameter clipclean removes is
// listed here and nowhere else. See AGENTS.md for how to add one.
//
// All names are matched case-insensitively, so write them in lowercase.
//
//   globalParams     exact names stripped on every site
//   globalPrefixes   name prefixes stripped on every site
//   referrerParams   generic names stripped only when the value is in referrerValues
//   siteRules        names stripped only on the listed sites
//
// Host patterns for siteRules:
//   .domain("x.com")     x.com and any subdomain
//   .brand("amazon")     any subdomain and any country suffix (www.amazon.co.uk)
//   .brandRoot("google") bare or www host only (www.google.de, not docs.google.com)

/// Stripped on every site.
let globalParams: Set<String> = [
    // Ad click IDs
    "fbclid", "gclid", "gclsrc", "dclid", "gbraid", "wbraid", "gad_source", "gad_campaignid",
    "msclkid", "yclid", "ysclid", "twclid", "ttclid", "li_fat_id", "sccid", "rdt_cid", "epik",
    "irclickid", "irgwc", "cjevent", "cjdata", "awc", "zanpid", "rb_clickid", "wickedid",
    "s_kwcid", "ef_id", "unicorn_click_id",
    // Email and marketing platforms
    "mc_cid", "mc_eid", "mc_tc", "_hsenc", "_hsmi", "__hssc", "__hstc", "__hsfp", "hsctatracking",
    "mkt_tok", "vero_id", "vero_conv", "oly_anon_id", "oly_enc_id", "ml_subscriber",
    "ml_subscriber_hash", "ck_subscriber_id", "_kx", "__s", "_bhlid", "sms_click", "sms_source",
    "sms_uph",
    // Analytics and attribution
    "_ga", "_gl", "s_cid", "_openstat", "srsltid", "_branch_match_id", "_branch_referrer",
    "wt_mc", "wt_zmc", "ns_mchannel", "ns_source", "ns_campaign", "ns_linkname", "ns_fee",
    // Social share IDs
    "igshid", "igsh", "mibextid", "ref_src", "ref_url", "__twitter_impression",
    "guccounter", "guce_referrer", "guce_referrer_sig",
]

/// Generic parameters that are stripped only when their value names a referrer, such as
/// "?ref=chatgpt.com" or "?source=perplexity". With any other value they are kept.
let referrerParams: Set<String> = ["ref", "source", "src", "referrer", "via", "from"]
let referrerValues: Set<String> = [
    "chatgpt.com", "chatgpt", "openai", "openai.com", "perplexity", "perplexity.ai",
    "claude.ai", "claude", "copilot", "copilot.microsoft.com", "gemini", "gemini.google.com",
    "bard", "you.com", "phind", "poe", "grok", "deepseek", "meta.ai", "duckduckgo", "ddg",
    "google", "bing", "twitter", "facebook", "linkedin", "reddit", "newsletter", "email",
    "producthunt", "hackernews",
]

/// Any parameter starting with one of these is stripped on every site.
let globalPrefixes: [String] = ["utm_", "pk_", "mtm_", "piwik_", "hsa_", "stm_"]

/// Parameters that are only safe to strip on particular sites.
let siteRules: [SiteRule] = [
    SiteRule(hosts: [.domain("youtube.com"), .domain("youtu.be")],
             params: ["si", "pp", "feature"]),
    SiteRule(hosts: [.domain("spotify.com")],
             params: ["si", "nd"]),
    SiteRule(hosts: [.domain("x.com"), .domain("twitter.com")],
             params: ["s", "t", "a", "cxt"]),
    SiteRule(hosts: [.domain("instagram.com"), .domain("threads.net"), .domain("threads.com")],
             params: ["xmt"]),
    SiteRule(hosts: [.domain("facebook.com")],
             params: ["__tn__", "__cft__[0]", "__xts__[0]", "rdid", "share_url", "fref", "hc_ref",
                      "refsrc", "sfnsn", "wtsid", "paipv", "eav"]),
    SiteRule(hosts: [.domain("tiktok.com")],
             params: ["_t", "_r", "_d", "is_from_webapp", "is_copy_url", "sender_device",
                      "share_app_id", "share_link_id", "share_item_id", "social_sharing", "tt_from",
                      "u_code", "preview_pb", "sec_user_id", "checksum", "web_id"]),
    SiteRule(hosts: [.domain("linkedin.com")],
             params: ["trk", "trackingid", "refid", "lipi", "licu", "rcm", "trkinfo", "trkemail",
                      "midtoken", "midsig"]),
    SiteRule(hosts: [.domain("reddit.com")],
             params: ["share_id", "rdt", "ref", "ref_source", "ref_campaign", "correlation_id"]),
    SiteRule(hosts: [.brand("amazon")],
             params: ["ref", "ref_", "qid", "sr", "sprefix", "crid", "dib", "dib_tag", "_encoding",
                      "content-id", "tag", "ascsubtag", "linkcode", "linkid", "camp",
                      "creative", "creativeasin"],
             prefixes: ["pf_rd_", "pd_rd_"],
             stripRefSegments: true),
    SiteRule(hosts: [.domain("imdb.com")],
             params: ["ref_"], prefixes: ["pf_rd_"], stripRefSegments: true),
    SiteRule(hosts: [.brandRoot("google")],
             params: ["ved", "ei", "sei", "sca_esv", "sca_upv", "sxsrf", "gs_lcp", "gs_lp",
                      "gs_lcrp", "gs_l", "sclient", "uact", "iflsig", "biw", "bih", "dpr", "ictx",
                      "sa", "usg", "oq", "aqs", "sourceid", "rlz", "source", "client", "fbs",
                      "sstk", "cshid", "zx", "no_sw_cr", "aep", "ntc", "mstk", "csuir", "pccc",
                      "rct", "opi", "gs_ssp", "entry", "g_ep"],
             unwrapRedirect: (path: "/url", params: ["url", "q"])),
    SiteRule(hosts: [.domain("bing.com")],
             params: ["form", "cvid", "pq", "qs", "sc", "sk", "sp", "ghsh", "ghacc", "ghpl", "ghc",
                      "lq", "fpig"]),
    SiteRule(hosts: [.brand("ebay")],
             params: ["_trkparms", "_trksid", "_from", "hash", "amdata", "mkevt", "mkcid", "mkrid",
                      "campid", "toolid", "customid"]),
    SiteRule(hosts: [.brand("aliexpress"), .brand("alibaba"), .brand("taobao"), .brand("tmall")],
             params: ["spm", "scm", "pvid", "algo_pvid", "algo_exp_id", "aff_fcid", "aff_fsk",
                      "aff_platform", "aff_trace_key", "terminal_id", "afsmartredirect", "pdp_npi",
                      "pdp_ext_f", "curpagelogid", "search_p4p_id", "ws_ab_test", "btsid"]),
    SiteRule(hosts: [.domain("bilibili.com")],
             params: ["spm_id_from", "vd_source", "from_source", "from_spmid", "share_source",
                      "share_medium", "share_plat", "share_session_id", "share_tag", "share_times",
                      "unique_k", "bbid", "plat_id", "buvid", "is_story_h5"]),
    SiteRule(hosts: [.domain("etsy.com")],
             params: ["click_key", "click_sum", "ref", "frs", "sts", "organic_search_click", "pro",
                      "sr_prefetch", "plkey", "content_source", "logging_key"],
             prefixes: ["ga_"]),
    SiteRule(hosts: [.domain("walmart.com")],
             params: ["athbdg", "athcpid", "athpgid", "athcgid", "athznid", "athieid", "athstid",
                      "athguid", "athancid", "athena"]),
    SiteRule(hosts: [.domain("music.apple.com"), .domain("podcasts.apple.com"),
                     .domain("apps.apple.com"), .domain("books.apple.com"), .domain("tv.apple.com")],
             params: ["itsct", "itscg", "at", "ct", "pt", "uo"]),
    SiteRule(hosts: [.domain("nytimes.com")],
             params: ["smid", "smtyp", "emc", "partner", "impression_id"]),
    SiteRule(hosts: [.domain("medium.com")],
             params: ["source"]),
    SiteRule(hosts: [.domain("substack.com")],
             params: ["r", "showwelcomeonshare", "triedredirect"]),
    SiteRule(hosts: [.domain("twitch.tv")],
             params: ["tt_medium", "tt_content", "tt_email_id"]),
    SiteRule(hosts: [.domain("vimeo.com")],
             params: ["share"]),
]
