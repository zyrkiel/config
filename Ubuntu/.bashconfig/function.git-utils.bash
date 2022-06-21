#!/bin/bash

function custom_git_ps1()
{
    local GIT_PS1_RESET_COLOR=$(echo -e "\e[0m")
    local GIT_PS1_LIGHT_RED=$(echo -e "\e[1;31m")
    local GIT_PS1_LIGHT_GREEN=$(echo -e "\e[1;32m")
    local GIT_PS1_LIGHT_YELLOW=$(echo -e "\e[1;33m")
    local GIT_PS1_LIGHT_BLUE=$(echo -e "\e[1;34m")
    local GIT_PS1_PURPLE=$(echo -e "\e[0;35m")
    local GIT_PS1_LIGHT_CYAN=$(echo -e "\e[1;36m")

    ##################
    ###  FUNCTIONS ###
    ##################
    function __git_ps1_get_unix_git_dir()
    {
        # Get git root dir and format it to unix path (c:/ => /c/) if needed
        git rev-parse --git-dir 2>/dev/null | sed "s#^\([A-Za-z]\):#/\1#"
    }

    function __git_ps1_warn_if_old_fetch()
    {
        local warn_date_min_days=2
        # Get git root dir and format it to unix path (c:/ => /c/)
        local git_root_dir=$(__git_ps1_get_unix_git_dir)

        local git_fetch_file="${git_root_dir}/FETCH_HEAD"
        if [ ! -f "${git_fetch_file}" ]; then
            return
        fi

        local git_last_fetch_date=$(stat -c %Y "${git_fetch_file}")
        local current_date=$(date +%s)
        local git_last_fetch_elapsed_time=$((($current_date - $git_last_fetch_date) / (60 * 60 * 24)))

        if [ $git_last_fetch_elapsed_time -ge $warn_date_min_days ]; then
            echo " ${GIT_PS1_LIGHT_RED}"'!'"${git_last_fetch_elapsed_time}days${GIT_PS1_RESET_COLOR}"
        fi
    }

    function __git_ps1_deduce_origin_branch_or_commit()
    {
        local git_local_branch=$1

        # Count commit only available on this branch (starts with ! using git show-branch -g)
        local exclusif_commit_count=$(git show-branch -g --sha1-name $git_local_branch | grep '!' | tail -n1 | sed -n "s/.*@{\([0-9]*\)}].*/\1/p")

        local origin_commit="HEAD"
        if [ "${exclusif_commit_count}" != "" ]; then
            # HEAD~<commit_count> might be undefined (during a conflict for exemple)
            local exclusif_commit_count_str="HEAD~${exclusif_commit_count}"
            local exclusif_commit_count_ref=$(git rev-parse ${exclusif_commit_count_str} 2>/dev/null)
            if [ "${exclusif_commit_count_ref}" != "${exclusif_commit_count_str}" ]; then
                origin_commit="${exclusif_commit_count_ref}"
            fi
        fi

        # If we find nothing, return fork-point sha1
        local forkpoint_result="${origin_commit}"

        local branch_name
        local branch_count=0
        for branch_name in $(git branch -r --contains ${origin_commit} | grep -v HEAD | cut -d ' ' -f 3); do
            ((branch_count++))
            # Look for release branch 1st (You can modify, add patterns here)
            if [ "$branch_name" == "origin/release/"* ]; then
                forkpoint_result="$branch_name"
                break
            fi

            # Then look for master
            if [ "$branch_name" == "origin/master" ]; then
                forkpoint_result="$branch_name"
                continue
            fi

            # Then look for dev
            if [ "$branch_name" == "origin/dev" ]; then
                forkpoint_result="$branch_name"
                continue
            fi

            # Then look for current origin
            if [ "$branch_name" == "origin/${git_local_branch}" ]; then
                forkpoint_result="$branch_name"
            fi
        done
        
        # If no branch matched and there is only one available, select it
        if [ $branch_count -eq 1 ]; then
            forkpoint_result="$branch_name"
        fi
        
        # No fork-point found, return current branch on origin if exists
        if [ "${forkpoint_result}" == "${origin_commit}" ]; then
            local own_origin_branch_origin_commit=$(git branch --all | grep origin/${git_local_branch})

            if [ "${own_origin_branch_origin_commit}" != "" ]; then
                forkpoint_result="origin/${git_local_branch}"
            fi
        fi
        
        echo "${forkpoint_result}"
    }

    function __git_ps1_get_repository_info()
    {
        local git_local_branch=$1

        # Try to simply use git branch to extract upstream branch
        local origin_branch=$(git rev-parse --abbrev-ref --symbolic-full-name @{upstream} 2>/dev/null)
        local is_upstream_branch=1

        # If rev-parse returned empty string or @{upstream} (happens on newly created repos)
        if [ "$origin_branch" == "" ] || [ "$origin_branch" == "@{upstream}" ]; then
            # No upstream branch found, try to deduce origin branch (if multiple, get fork-point commit)
            origin_branch=$(__git_ps1_deduce_origin_branch_or_commit ${git_local_branch})
            is_upstream_branch=0
        fi

        local upstream_branch_prefix=""
        if [ $is_upstream_branch -eq 0 ]; then
            upstream_branch_prefix="${GIT_PS1_LIGHT_RED}no-up:${GIT_PS1_RESET_COLOR}"
        fi

        local commit_diff_count=$(git rev-list --left-right --count ${origin_branch}...HEAD)
        local behind_commit_count=$(echo -e "$commit_diff_count" | cut -f 1)
        local ahead_commit_count=$(echo -e "$commit_diff_count" | cut -f 2)

        if [ "$ahead_commit_count" != "0" ]; then
            commit_diff_str="${GIT_PS1_LIGHT_GREEN}+${ahead_commit_count}${GIT_PS1_RESET_COLOR}"
        fi

        if [ "$behind_commit_count" != "0" ]; then
            if [ "$commit_diff_str" != "" ]; then
                commit_diff_str="${commit_diff_str}|"
            fi
            commit_diff_str="${commit_diff_str}${GIT_PS1_LIGHT_RED}-${behind_commit_count}${GIT_PS1_RESET_COLOR}"
        fi

        if [ "${commit_diff_str}" != "" ]; then
            commit_diff_str=":${commit_diff_str}"
        fi

        commit_diff_str=" [${upstream_branch_prefix}${GIT_PS1_LIGHT_YELLOW}${origin_branch}${GIT_PS1_RESET_COLOR}${commit_diff_str}]"

        local operation_status=$(git diff-index HEAD | cut -d ' ' -f 5)

        local modified=$(echo -e "$operation_status" | grep '^[^DA]')
        if [ "$modified" != "" ]; then
            # Added operations
           operation_indicator="${GIT_PS1_LIGHT_CYAN}*${GIT_PS1_RESET_COLOR}"
        fi

        local deleted=$(echo -e "$operation_status" | grep '^D')
        if [ "$deleted" != "" ]; then
            # Deleted operations
            operation_indicator="${operation_indicator}${GIT_PS1_LIGHT_RED}-${GIT_PS1_RESET_COLOR}"
        fi

        local added=$(echo -e "$operation_status" | grep '^A')
        if [ "$added" != "" ]; then
            # Added operations
           operation_indicator="${operation_indicator}${GIT_PS1_LIGHT_GREEN}+${GIT_PS1_RESET_COLOR}"
        fi
    }

    function __git_ps1_get_current_operation()
    {
        local git_root_dir=$(__git_ps1_get_unix_git_dir)

        local git_current_operation_status=""

        if [ -e "${git_root_dir}/CHERRY_PICK_HEAD" ]; then
            git_current_operation_status="cherry-pick"
        elif [ -e "${git_root_dir}/MERGE_HEAD" ]; then
            git_current_operation_status="merge"
        elif [ -e "${git_root_dir}/rebase" ] || [ -e "${git_root_dir}/rebase-apply/rebasing" ] || [ -e "${git_root_dir}/rebase-merge" ]; then
            git_current_operation_status="rebase"
        elif [ -e "${git_root_dir}/rebase-apply" ]; then
            git_current_operation_status="am"
        elif [ -e "${git_root_dir}/BISECT_LOG" ]; then
            git_current_operation_status="bisect"
        fi

        if [ "${git_current_operation_status}" != "" ]; then
            git_current_operation_status=" ${GIT_PS1_LIGHT_RED}>"'!'"${git_current_operation_status}"'!'"<${GIT_PS1_RESET_COLOR}"
        fi

        echo "${git_current_operation_status}"
    }

    ##################
    ###    MAIN    ###
    ##################
    git rev-parse --git-dir &> /dev/null
    if [ $? -ne 0 ]; then
        # Not a git repo
        return
    fi

    git rev-parse --abbrev-ref HEAD &> /dev/null
    if [ $? -ne 0 ]; then
        # Empty git repo
        echo "(${GIT_PS1_LIGHT_YELLOW}Initial commit${GIT_PS1_RESET_COLOR})"
       return
    fi

    local git_local_branch=$(git rev-parse --abbrev-ref HEAD)

    local commit_diff_str=""
    local operation_indicator=""

    # Get operation in progress if any
    local git_is_bare_repository=$(git rev-parse --is-bare-repository)
    if [ "$git_is_bare_repository" == "true" ]; then
        operation_indicator="[${GIT_PS1_LIGHT_RED}bare repository${GIT_PS1_RESET_COLOR}]"
    else
        __git_ps1_get_repository_info $git_local_branch
    fi

    # Format local branch display
    if [ "$git_local_branch" == "HEAD" ]; then
        local rev_short_number=$(git rev-parse --short HEAD)
        git_local_branch="${GIT_PS1_LIGHT_RED}${rev_short_number}${GIT_PS1_RESET_COLOR}"
    else
        git_local_branch="${GIT_PS1_LIGHT_CYAN}${git_local_branch}${GIT_PS1_RESET_COLOR}"
    fi

    # Get current git operation if any
    local current_git_operation=$(__git_ps1_get_current_operation)
    local warn_if_old_fetch_status=$(__git_ps1_warn_if_old_fetch)
    echo "(${git_local_branch}${operation_indicator}${commit_diff_str})${current_git_operation}${warn_if_old_fetch_status}"

    # Unset inner functions
    unset -f __git_ps1_get_unix_git_dir
    unset -f __git_ps1_warn_if_old_fetch
    unset -f __git_ps1_deduce_origin_branch_or_commit
    unset -f __git_ps1_get_repository_info
    unset -f __git_ps1_get_current_operation
}
