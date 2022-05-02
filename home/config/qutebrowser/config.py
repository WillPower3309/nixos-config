# Load autoconfig.yml?
config.load_autoconfig(False)

# Command aliases
c.aliases = {'q': 'quit', 'w': 'session-save', 'wq': 'quit --save'}

# Setting dark mode
config.set('colors.webpage.preferred_color_scheme', 'dark')

# Which cookies to accept. With QtWebEngine, this setting also controls
# other features with tracking capabilities similar to those of cookies;
# including IndexedDB, DOM storage, filesystem API, service workers, and
# AppCache. Note that with QtWebKit, only `all` and `never` are
# supported as per-domain values. Setting `no-3rdparty` or `no-
# unknown-3rdparty` per-domain on QtWebKit will have the same effect as
# `all`.
# Valid values:
#   - all: Accept all cookies.
#   - no-3rdparty: Accept cookies from the same origin only. This is known to break some sites, such as GMail.
#   - no-unknown-3rdparty: Accept cookies from the same origin only, unless a cookie is already set for the domain. On QtWebEngine, this is the same as no-3rdparty.
#   - never: Don't accept cookies at all.
config.set('content.cookies.accept', 'all', 'chrome-devtools://*')
config.set('content.cookies.accept', 'all', 'devtools://*')

# User agent to send.  The following placeholders are defined:  *
# `{os_info}`: Something like "X11; Linux x86_64". * `{webkit_version}`:
# The underlying WebKit version (set to a fixed value   with
# QtWebEngine). * `{qt_key}`: "Qt" for QtWebKit, "QtWebEngine" for
# QtWebEngine. * `{qt_version}`: The underlying Qt version. *
# `{upstream_browser_key}`: "Version" for QtWebKit, "Chrome" for
# QtWebEngine. * `{upstream_browser_version}`: The corresponding
# Safari/Chrome version. * `{qutebrowser_version}`: The currently
# running qutebrowser version.  The default value is equal to the
# unchanged user agent of QtWebKit/QtWebEngine.  Note that the value
# read from JavaScript is always the global value. With QtWebEngine
# between 5.12 and 5.14 (inclusive), changing the value exposed to
# JavaScript requires a restart.
config.set('content.headers.user_agent', 'Mozilla/5.0 ({os_info}) AppleWebKit/{webkit_version} (KHTML, like Gecko) {upstream_browser_key}/{upstream_browser_version} Safari/{webkit_version}', 'https://web.whatsapp.com/')
config.set('content.headers.user_agent', 'Mozilla/5.0 ({os_info}; rv:71.0) Gecko/20100101 Firefox/71.0', 'https://accounts.google.com/*')
config.set('content.headers.user_agent', 'Mozilla/5.0 ({os_info}) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99 Safari/537.36', 'https://*.slack.com/*')
config.set('content.headers.user_agent', 'Mozilla/5.0 ({os_info}; rv:71.0) Gecko/20100101 Firefox/71.0', 'https://docs.google.com/*')
config.set('content.headers.user_agent', 'Mozilla/5.0 ({os_info}; rv:71.0) Gecko/20100101 Firefox/71.0', 'https://drive.google.com/*')

# Load images automatically in web pages.
config.set('content.images', True, 'chrome-devtools://*')
config.set('content.images', True, 'devtools://*')
config.set('content.javascript.enabled', True, 'chrome-devtools://*')
config.set('content.javascript.enabled', True, 'devtools://*')
config.set('content.javascript.enabled', True, 'chrome://*/*')
config.set('content.javascript.enabled', True, 'qute://*/*')

# Allow websites to show notifications.
# Valid values:
#   - true
#   - false
#   - ask
config.set('content.notifications.enabled', True, 'https://www.reddit.com')
config.set('content.notifications.enabled', True, 'https://www.youtube.com')

# Directory to save downloads to. If unset, a sensible OS-specific
# default is used.
#c.downloads.location.directory = ''

# When to show the tab bar.
# Valid values:
#   - always: Always show the tab bar.
#   - never: Always hide the tab bar.
#   - multiple: Hide the tab bar if only one tab is open.
#   - switching: Show the tab bar when switching tabs.
c.tabs.show = 'multiple'

# Setting default page for when opening new tabs or new windows with
# commands like :open -t and :open -w .
c.url.default_page = 'https://searx.bar/search'

# Search engines which can be used via the address bar.  Maps a search
# engine name (such as `DEFAULT`, or `ddg`) to a URL with a `{}`
# placeholder. The placeholder will be replaced by the search term, use
# `{{` and `}}` for literal `{`/`}` braces.  The following further
# placeholds are defined to configure how special characters in the
# search terms are replaced by safe characters (called 'quoting'):  *
# `{}` and `{semiquoted}` quote everything except slashes; this is the
# most   sensible choice for almost all search engines (for the search
# term   `slash/and&amp` this placeholder expands to `slash/and%26amp`).
# * `{quoted}` quotes all characters (for `slash/and&amp` this
# placeholder   expands to `slash%2Fand%26amp`). * `{unquoted}` quotes
# nothing (for `slash/and&amp` this placeholder   expands to
# `slash/and&amp`).  The search engine named `DEFAULT` is used when
# `url.auto_search` is turned on and something else than a URL was
# entered to be opened. Other search engines can be used by prepending
# the search engine name to the search term, e.g. `:open google
# qutebrowser`.
c.url.searchengines = {'DEFAULT': 'https://searx.bar/?preferences=eJx1Vk2P2zYQ_TXVRXCAbQ49-RCkKBqgwAZdJ1dhRI7lqSiOMqTs1f76DvVlypscLJgjcubxzeOjDERsWAjDsUGPAq5w4JsBGjyiP3z-VDg24NKggCGy4a53GPEYIkjsdVpBnT6rXvh1PJ5kwKLDeGF7_Pr8cioCnDEgiLkcn4p4wQ6PHAxIIRgGF0PFvvJ4qyLUx7_ABSwsU6Uv2V1Rjgw6_MDSFNOqQ4ijYnHckGGL14MFaQuwV_AGbbUUWvJQgNppFH1DXvcXWQR9fKuqbghkfvv9sx8BqupMDoOObtRSzdyGqlqo0CAK38jmEUFrKeaRHzfwuwD5K1niQTPpH-SUfcaWUJfpUVUUE4K-W_5xjx5IsB9qRwYisdflwRDq1vR95HbkyOHCLfg7aDtY9HltO5g2_RrebSOOHXunPORRrdUpQVmVmZENdKJEu6NA0nMJ_Bg47tIEfPPQ5RGQV7rmeVfSJq2kRE8fP_7xmlXqSVSJNYz37hjhEATPeZ4rdcjZssQpXbGk8HMOyrlgVvis7LaSBSw1jZZgQ-BKpYMgbWlVd57WcR0ifpCwtGzd1MJNRwkxn2MJBizqMEdek2_KGXeGv6FGRQphJ58L1ALpsdTpbY07Mod6bLBbYTQUHdTLIDXIQoQ8X8PcOCx7B2MJfR_u6iGfd3uEC3O563fATrVNpgzmwg4khzHJ_j3BAXuCWe0PSrry-MDoFEUJFMedLu9i2BI86P9X8VU8YJrAw308g32nZZ0jZgfp6TUXiyCWqaU3ECytHk-jLjIuXN8NZeUzHWI9wpxRrJkpGcEKZARv8TWvaIaUxuwYmNTyjtp7wW37aeIDo8k6QHbpLJBTA0hvsrXWNqXFM3la3Oa-YPaBFbM6LSl9eiQyMD2ixCEpc0t4FvItgclm1XE-X9ucjv9DbPfexOx21RudEfWkrwrP_PSxv1uhG7uzQAeuv0CuUmPMIV7zXU94Fg3M-9ySeFA17oxsKbN2czoi-YRu7LBTSZRRwAensrWPAu-Tp_zqPE77yTxPr4YapVk2frbC6fZZy69srtMnmexEvcvNV8Kd28wv37lQq5YIIew6maikWtaLKv1XUZVpF-HBbcnEN97fLCtv97ZjVI5lr_FYq0ljfLgBk30FjLvbb0O49b9vy45EeDLJQlfu7vrVmh9sfUuzEjr4oFSFy6qB-1dD7wZNFY5f_HRAUMEIu4T7O3UHRy1WF44tjmErvi55mc1Pz5qZv65G_TJxah26-O_T6euLft_cRHOmcSo-L9TRSUAJkerbv__oHO0fikaflZjqkzGoyP98_pKtfkF3rhQhSzd_MRRqh6gQ_gdlBrZj&q={}'}

# Text color of the completion widget. May be a single color to use for
# all columns or a list of three colors, one for each column.
c.colors.completion.fg = ['#9cc4ff', 'white', 'white']
# Background color of the completion widget for odd rows.
c.colors.completion.odd.bg = '#1c1f24'
# Background color of the completion widget for even rows.
c.colors.completion.even.bg = '#232429'
# Foreground color of completion widget category headers.
c.colors.completion.category.fg = '#e1acff'
# Background color of the completion widget category headers.
c.colors.completion.category.bg = 'qlineargradient(x1:0, y1:0, x2:0, y2:1, stop:0 #000000, stop:1 #232429)'
# Top border color of the completion widget category headers.
c.colors.completion.category.border.top = '#3f4147'
# Bottom border color of the completion widget category headers.
c.colors.completion.category.border.bottom = '#3f4147'
# Foreground color of the selected completion item.
c.colors.completion.item.selected.fg = '#282c34'
# Background color of the selected completion item.
c.colors.completion.item.selected.bg = '#ecbe7b'
# Foreground color of the matched text in the selected completion item.
c.colors.completion.item.selected.match.fg = '#c678dd'
# Foreground color of the matched text in the completion.
c.colors.completion.match.fg = '#c678dd'
# Color of the scrollbar handle in the completion view.
c.colors.completion.scrollbar.fg = 'white'
# Background color for the download bar.
c.colors.downloads.bar.bg = '#282c34'
# Background color for downloads with errors.
c.colors.downloads.error.bg = '#ff6c6b'
# Font color for hints.
c.colors.hints.fg = '#282c34'
# Font color for the matched part of hints.
c.colors.hints.match.fg = '#98be65'
# Background color of an info message.
c.colors.messages.info.bg = '#282c34'
# Background color of the statusbar.
c.colors.statusbar.normal.bg = '#282c34'
# Foreground color of the statusbar in insert mode.
c.colors.statusbar.insert.fg = 'white'
# Background color of the statusbar in insert mode.
c.colors.statusbar.insert.bg = '#497920'
# Background color of the statusbar in passthrough mode.
c.colors.statusbar.passthrough.bg = '#34426f'
# Background color of the statusbar in command mode.
c.colors.statusbar.command.bg = '#282c34'
# Foreground color of the URL in the statusbar when there's a warning.
c.colors.statusbar.url.warn.fg = 'yellow'
# Background color of the tab bar.
c.colors.tabs.bar.bg = '#1c1f34'
# Background color of unselected odd tabs.
c.colors.tabs.odd.bg = '#282c34'
# Background color of unselected even tabs.
c.colors.tabs.even.bg = '#282c34'
# Background color of selected odd tabs.
c.colors.tabs.selected.odd.bg = '#282c34'
# Background color of selected even tabs.
c.colors.tabs.selected.even.bg = '#282c34'
# Background color of pinned unselected odd tabs.
c.colors.tabs.pinned.odd.bg = 'seagreen'
# Background color of pinned unselected even tabs.
c.colors.tabs.pinned.even.bg = 'darkseagreen'
# Background color of pinned selected odd tabs.
c.colors.tabs.pinned.selected.odd.bg = '#282c34'
# Background color of pinned selected even tabs.
c.colors.tabs.pinned.selected.even.bg = '#282c34'

# Default font families to use. Whenever "default_family" is used in a
# font setting, it's replaced with the fonts listed here. If set to an
# empty value, a system-specific monospace default is used.
c.fonts.default_family = '"Roboto Mono"'

# Default font size to use. Whenever "default_size" is used in a font
# setting, it's replaced with the size listed here. Valid values are
# either a float value with a "pt" suffix, or an integer value with a
# "px" suffix.
c.fonts.default_size = '11pt'

# Font used in the completion widget.
c.fonts.completion.entry = '11pt "Roboto Mono"'
# Font used for the debugging console.
c.fonts.debug_console = '11pt "Roboto Mono"'
# Font used for prompts.
c.fonts.prompts = 'default_size sans-serif'
# Font used in the statusbar.
c.fonts.statusbar = '11pt "Roboto Mono"'

# Bindings for normal mode
config.bind('M', 'hint links spawn mpv {hint-url}')
config.bind('Z', 'hint links spawn st -e youtube-dl {hint-url}')
config.bind('t', 'set-cmd-text -s :open -t')
config.bind('xb', 'config-cycle statusbar.show always never')
config.bind('xt', 'config-cycle tabs.show always never')
config.bind('xx', 'config-cycle statusbar.show always never;; config-cycle tabs.show always never')
