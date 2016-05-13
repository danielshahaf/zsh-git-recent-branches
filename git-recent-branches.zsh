# This function returns in $reply recently-checked-out refs' names, in order
# from most to least recent.
function __git_recent_branches__names()
{
    local -a reflog
    local reflog_subject
    local new_head
    local -A seen
    reply=()

    reflog=(${(ps:\0:)"$(_call_program reflog git reflog -z --grep-reflog='\^checkout:\ moving\ from\ ' --pretty='%gs' 2>/dev/null)"})
    for reflog_subject in $reflog; do
      new_head=${${=reflog_subject}[4]}

      if (( ${+seen[$new_head]} )); then
        continue
      fi
      seen[$new_head]="" # value is ignored

      if [[ $new_head =~ '^[0-9a-f]{40}$' ]]; then
        continue
      fi

      # All checks passed.  Add it.
      reply+=( $new_head )
    done
}

__git_recent_branches2() {
    local -a branches descriptions
    local branch description
    local -i current
    integer branch_limit
    local -a reply

    zstyle -s ":completion:${curcontext}:recent-branches" 'limit' branch_limit || branch_limit=100
    current=0
    __git_recent_branches__names \
    ; for branch in $reply
    do
        # ### We'd want to convert all $reply to $descriptions in one shot, with this:
        # ###     array=("${(ps:\0:)"$(_call_program descriptions git --no-pager log --no-walk=unsorted -z --pretty=%s ${(q)reply} --)"}")
        # ### , but git croaks if any of the positional arguments is a ref name that has been deleted.
        # ### Hence, we resort to fetching the descriptions one-by-one.  Let's hope the user is well-stocked on cutlery.
        description="$(_call_program description git --no-pager log --no-walk=unsorted --pretty=%s ${(q)branch} --)"
        # If the ref has been deleted, $description would be empty.
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
compdef __git_recent_branches2 git-rb

# If you define an alias in ~/.gitconfig for    rb = checkout  then you can test
# using  git rb BRANCH<enter> and it should checkout the appropriate branch
