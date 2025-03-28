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
static int update_cb(const char *refname, const git_oid *a, const git_oid *b, void *data)
{
	char a_str[GIT_OID_HEXSZ+1], b_str[GIT_OID_HEXSZ+1];
	(void)data;

	git_oid_fmt(b_str, b);
	b_str[GIT_OID_HEXSZ] = '\0';

	if (git_oid_is_zero(a)) {
		printf("[new]     %.20s %s\n", b_str, refname);
	} else {
		git_oid_fmt(a_str, a);
		a_str[GIT_OID_HEXSZ] = '\0';
		printf("[updated] %.10s..%.10s %s\n", a_str, b_str, refname);
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

/** Entry point for this command */
int lg2_pull(git_repository *repo, int argc, char **argv)
{
	git_remote *remote = NULL;
	const git_indexer_progress *stats;
	git_fetch_options fetch_opts = GIT_FETCH_OPTIONS_INIT;

    char *origin = NULL;
	char *argv_merge[2];
    bool remote_name_needs_to_be_freed = false;

    if (argc < 2) {
        origin = (char *)git_get_current_branch_upstream(repo);
        if (!origin) {
            origin = "origin";
        } else {
            remote_name_needs_to_be_freed = true;
        }
        printf("No remote given. Using the tracked remote: %s\n", origin);
    } else if (argc == 2) {
		origin = argv[1];
	} else if (argc > 2) {
		fprintf(stderr, "usage: %s pull [remote]\n", argv[-1]);
		return EXIT_FAILURE;
	}

	/* Figure out whether it's a named remote or a URL */
	printf("Fetching %s for repo %p\n", origin, repo);
	if (git_remote_lookup(&remote, repo, origin) < 0)
		if (git_remote_create_anonymous(&remote, repo, argv[1]) < 0)
			goto on_error;

	/* Set up the callbacks (only update_tips for now) */
	fetch_opts.callbacks.update_tips = &update_cb;
	fetch_opts.callbacks.sideband_progress = &progress_cb;
	fetch_opts.callbacks.transfer_progress = transfer_progress_cb;

	fetch_opts.callbacks.credentials = cred_acquire_cb;
	fetch_opts.callbacks.certificate_check = certificate_confirm_cb;
	fetch_opts.callbacks.payload = repo; // send repo to cb to get username/password or identityFile

	/**
	 * Perform the fetch with the configured refspecs from the
	 * config. Update the reflog for the updated references with
	 * "pull".
	 */
	if (git_remote_fetch(remote, NULL, &fetch_opts, "pull") < 0)
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

	/** Now we merge with current directory */
	argv_merge[0] = "merge";
	argv_merge[1] = "FETCH_HEAD";
	// New code: get the merge error to report
	int result = lg2_merge(repo, 2, argv_merge);

	/* Done */

	git_remote_free(remote);
    if (remote_name_needs_to_be_freed) {
        free(origin);
    }
    
	return result;

 on_error:
	git_remote_free(remote);
    if (remote_name_needs_to_be_freed) {
        free(origin);
    }
	return -1;
}
