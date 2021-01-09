
match 'sys/git_mirror/fetch', to: 'git_mirror#fetch', via: [:get, :post]
match 'sys/git_mirror/gitlab', to: 'git_mirror#gitlab', via: [:post]
match 'sys/git_mirror/github', to: 'git_mirror#github', via: [:post]
match 'sys/git_mirror/gitea', to: 'git_mirror#gitea', via: [:post]
