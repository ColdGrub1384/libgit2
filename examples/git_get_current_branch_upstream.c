//
//  git_get_current_branch_upstream.c
//  lg2
//
//  Created by Emma on 16-02-25.
//  Copyright © 2025 Emma Labbé. All rights reserved.
//

#include <string.h>
#include <stdio.h>
#include "git2.h"

const char *git_get_current_branch_upstream(git_repository *repo) {
    git_branch_iterator *it = NULL;
    git_reference* current = NULL;
    const char *upstream_name = NULL;
    git_config *cfg = NULL;
    git_config_entry *entry = NULL;
    int error = 0;

    error = git_branch_iterator_new(&it, repo, GIT_BRANCH_ALL);

    while (error == 0) {
        git_branch_t branch_type;
        const char *name = NULL;

        error = git_branch_next(&current, &branch_type, it);
        if (error != 0) {
            if (error == GIT_ITEROVER) {
                error = 0;
                break;
            }

            fprintf(stderr, "Error while iterating over branches.\n");
            goto cleanup;
        }
        
        error = git_branch_name(&name, current);
        if (error != 0) {
            fprintf(stderr, "Error looking up branch name.\n");
            goto cleanup;
        }

        if (git_branch_is_head(current)) {
            char key[50] = "branch.";
            strcat(key, name);
            strcat(key, ".remote");
            git_repository_config(&cfg, repo);
            
            if ((error = git_config_get_entry(&entry, cfg, key)) < 0) {
                if (error != GIT_ENOTFOUND)
                    printf("Unable to get configuration: %s\n", git_error_last()->message);
                return NULL;
            }

            upstream_name = strdup(entry->value);
        }
    }

cleanup:
    git_branch_iterator_free(it);
    if (cfg) {
        git_config_free(cfg);
    }
    if (entry) {
        git_config_entry_free(entry);
    }
    return upstream_name;
}
