function __git_recent_branches()
{
    # TODO: Suggest to use 'git reflog -z --pretty=%gs%z%s' to get just the interesting parts
    # TODO: Suggest to filter for "checkout:" leader to avoid false positive matches (when %s contains "moving from")
    local current_branch branch_limit
    local -a branches branches_without_current unique_branches
    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    # TODO: Why backslashes?  aliaes aren't evaluated by 'autoload -U'
    # TODO: «grep -o» is in freebsd/linux but isn't in POSIX; okay here but might not be for zsh upstream
    branches=($(git reflog 2>/dev/null | \grep -Eio "moving from ([^[:space:]]+)" | \awk '{ print $3 }' | \grep -Eiv "[0-9a-f]{40}" | \tr '\n' ' '))
    branches_without_current=("${(@)branches:#$current_branch}")
    unique_branches=(${(u)branches_without_current})
    # TODO: Is $unique_branches both echo-safe and $()-safe?  If not: most robust would be to use $reply return array
    echo $unique_branches
}

_git-rb() {
    local -a branches descriptions
    local branch description
    local -i current
    integer branch_limit

    zstyle -s ":completion:${curcontext}:recent-branches" 'limit' branch_limit || branch_limit=100
    current=0
    for branch in $(__git_recent_branches)
    do
        description=$(git log -1 --pretty=%s ${branch} -- 2>/dev/null)
        # TODO: why this check?  Is it belt-and-suspenders?  I not, can $description be empty?
        if [[ -n "$description" ]]; then
          branches+=$branch
          descriptions+="${branch}:${description/:/\:}"
          (( current++ ))
          if (( $current == $branch_limit )); then
            break
          fi
        fi
    done

    _describe -V -t recent-branches "recent branches" descriptions branches
}
compdef _git-rb git-rb

# If you define an alias in ~/.gitconfig for    rb = checkout  then you can test
# using  git rb BRANCH<enter> and it should checkout the appropriate branch
