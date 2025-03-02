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

	if (git_refspec_rtransform(&remote_name, spec, refname) < 0)
		return -1;

	git_oid_fmt(b_str, b);
	b_str[GIT_OID_SHA1_HEXSIZE] = '\0';

	if (git_oid_is_zero(a)) {
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

/** Entry point for this command */
int lg2_fetch(git_repository *repo, int argc, char **argv)
{
	git_remote *remote = NULL;
	const git_indexer_progress *stats;
	git_fetch_options fetch_opts = GIT_FETCH_OPTIONS_INIT;

	if (argc < 2) {
		fprintf(stderr, "usage: %s fetch <repo>\n", argv[-1]);
		return EXIT_FAILURE;
	}

	/* Figure out whether it's a named remote or a URL */
	printf("Fetching %s for repo %p\n", argv[1], repo);
	if (git_remote_lookup(&remote, repo, argv[1]) < 0)
		if (git_remote_create_anonymous(&remote, repo, argv[1]) < 0)
			goto on_error;

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
	if (git_remote_fetch(remote, NULL, &fetch_opts, "fetch") < 0)
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

	return 0;

 on_error:
	git_remote_free(remote);
	return -1;
}
