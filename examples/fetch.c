#include "common.h"

static int progress_cb(const char *str, int len, void *data)
{
	(void)data;
	printf("remote: %.*s", len, str);
	fflush(stdout); /* We don't have the \n to force the flush */
	return 0;
}

/**
 * This function gets called for each remote-tracking branch that gets
 * updated. The message we output depends on whether it's a new one or
 * an update.
 */
static int update_cb(const char *refname, const git_oid *a, const git_oid *b, git_refspec *spec, void *data)
{
	char a_str[GIT_OID_SHA1_HEXSIZE+1], b_str[GIT_OID_SHA1_HEXSIZE+1];
	git_buf remote_name;
	(void)data;
    
	if (spec && git_refspec_rtransform(&remote_name, spec, refname) < 0)
		return -1;

	git_oid_fmt(b_str, b);
	b_str[GIT_OID_SHA1_HEXSIZE] = '\0';

    if (!spec) {
        printf("[deleted] %.20s %s -> %s\n", b_str, remote_name.ptr, refname);
    } else if (git_oid_is_zero(a)) {
		printf("[new]     %.20s %s -> %s\n", b_str, remote_name.ptr, refname);
	} else {
		git_oid_fmt(a_str, a);
		a_str[GIT_OID_SHA1_HEXSIZE] = '\0';
		printf("[updated] %.10s..%.10s %s -> %s\n", a_str, b_str, remote_name.ptr, refname);
	}

	return 0;
}

/**
 * This gets called during the download and indexing. Here we show
 * processed and total objects in the pack and the amount of received
 * data. Most frontends will probably want to show a percentage and
 * the download rate.
 */
static int transfer_progress_cb(const git_indexer_progress *stats, void *payload)
{
	(void)payload;

	if (stats->received_objects == stats->total_objects) {
		printf("Resolving deltas %u/%u\r",
		       stats->indexed_deltas, stats->total_deltas);
	} else if (stats->total_objects > 0) {
		printf("Received %u/%u objects (%u) in %" PRIuZ " bytes\r",
		       stats->received_objects, stats->total_objects,
		       stats->indexed_objects, stats->received_bytes);
	}
	return 0;
}

static void print_usage(void) {
    fprintf(stderr, "usage: lg2 fetch [-p, --prune] <repo> [refspecs...]\n");
}

/** Entry point for this command */
int lg2_fetch(git_repository *repo, int argc, char **argv)
{
	git_remote *remote = NULL;
	const git_indexer_progress *stats;
	git_fetch_options fetch_opts = GIT_FETCH_OPTIONS_INIT;
    bool prune = false;
    bool tags = false;
    char *remote_name = NULL;
    git_strarray refspecs = { .count = 0, .strings = NULL };
    bool remote_name_needs_to_be_freed = false;
    
	if (argc < 2) {
        remote_name = (char *)git_get_current_branch_upstream(repo);
        if (!remote_name) {
            remote_name = "origin";
        } else
            remote_name_needs_to_be_freed = true;
    } else if (!strcmp(argv[2], "-h") || !strcmp(argv[2], "--help")) {
        print_usage();
        return EXIT_FAILURE;
    }
    
    if (!remote_name) {
        int j = 1;
        for (int i = 1; i < argc; i+=1) {
            if ((!strcmp(argv[i], "-p") || !strcmp(argv[i], "--prune")) && !prune) {
                prune = true;
                j += 1;
            } else if ((!strcmp(argv[i], "-t") || !strcmp(argv[i], "--tags")) && !tags) {
                tags = true;
                j += 1;
            } else if (!remote_name) {
                remote_name = argv[i];
                j += 1;
            } else {
                if (!refspecs.strings) {
                    char *new_refspec_names[argc-j];
                    refspecs.strings = new_refspec_names;
                }
                
                refspecs.strings[refspecs.count] = argv[i];
                
                j += 1;
                refspecs.count += 1;
            }
        }
    }
    
	/* Figure out whether it's a named remote or a URL */
	printf("Fetching %s for repo %p\n", remote_name, repo);
	if (git_remote_lookup(&remote, repo, remote_name) < 0)
		if (git_remote_create_anonymous(&remote, repo, remote_name) < 0)
			goto on_error;
    
    if (prune) {
        fetch_opts.prune = GIT_FETCH_PRUNE;
    } else {
        fetch_opts.prune = GIT_FETCH_NO_PRUNE;
    }
    if (tags) {
        fetch_opts.download_tags = GIT_REMOTE_DOWNLOAD_TAGS_ALL;
    } else {
        fetch_opts.download_tags = GIT_REMOTE_DOWNLOAD_TAGS_UNSPECIFIED;
    }
    
	/* Set up the callbacks (only update_tips for now) */
	fetch_opts.callbacks.update_refs = &update_cb;
	fetch_opts.callbacks.sideband_progress = &progress_cb;
	fetch_opts.callbacks.transfer_progress = transfer_progress_cb;

	fetch_opts.callbacks.certificate_check = certificate_confirm_cb;
	fetch_opts.callbacks.credentials = cred_acquire_cb;
	fetch_opts.callbacks.payload = repo; // Send repo to cb to get username/password or identityFile

	/**
	 * Perform the fetch with the configured refspecs from the
	 * config. Update the reflog for the updated references with
	 * "fetch".
	 */
    if (git_remote_fetch(remote, &refspecs, &fetch_opts, "fetch") < 0)
		goto on_error;

	/**
	 * If there are local objects (we got a thin pack), then tell
	 * the user how many objects we saved from having to cross the
	 * network.
	 */
	stats = git_remote_stats(remote);
	if (stats->local_objects > 0) {
		printf("\rReceived %u/%u objects in %" PRIuZ " bytes (used %u local objects)\n",
		       stats->indexed_objects, stats->total_objects, stats->received_bytes, stats->local_objects);
	} else{
		printf("\rReceived %u/%u objects in %" PRIuZ "bytes\n",
			stats->indexed_objects, stats->total_objects, stats->received_bytes);
	}

	git_remote_free(remote);
    if (remote_name_needs_to_be_freed) {
        free(remote_name);
    }
	return 0;

 on_error:
	git_remote_free(remote);
    if (remote_name_needs_to_be_freed) {
        free(remote_name);
    }
	return -1;
}
