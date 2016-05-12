function __git_recent_branches()
{
    local current_branch branch_limit
    local -a branches branches_without_current unique_branches
    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    branches=($(git reflog 2>/dev/null | \grep -Eio "moving from ([^[:space:]]+)" | \awk '{ print $3 }' | \grep -Eiv "[0-9a-f]{40}" | \tr '\n' ' '))
    branches_without_current=("${(@)branches:#$current_branch}")
    unique_branches=("${(u)branches_without_current}")
    branch_limit=11
    echo $unique_branches
    #[1,${branch_limit:-10}]
}

_git-rb() {
    local -a branches desc
    local branch
    branches=
    for branch in ($(__git_recent_branches))
    do
        desc+=("${branch}:$(git log -1 --pretty=%s ${branch} -- 2>/dev/null)")
    done
    _describe "recent branches" desc -V recent
}
compdef _git-rb git-rb
