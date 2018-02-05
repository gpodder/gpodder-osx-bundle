#!/usr/bin/env python
"""
Upload macOS deps release files to a new draft release in gpodder-osx-bundle.
"""
import argparse
import difflib
import hashlib
import os
import sys
import re

from github3 import login
import requests


def debug_requests():
    """ turn requests debug on """
    import logging

    # These two lines enable debugging at httplib level (requests->urllib3->http.client)
    # You will see the REQUEST, including HEADERS and DATA, and RESPONSE with HEADERS but without DATA.
    # The only thing missing will be the response.body which is not logged.
    import http.client as http_client
    http_client.HTTPConnection.debuglevel = 1

    # You must initialize logging, otherwise you'll not see debug output.
    logging.basicConfig()
    logging.getLogger().setLevel(logging.DEBUG)
    requests_log = logging.getLogger("requests.packages.urllib3")
    requests_log.setLevel(logging.DEBUG)
    requests_log.propagate = True


def error_exit(msg, code=1):
    """ print msg and exit with code """
    print(msg, file=sys.stderr)
    sys.exit(code)


def download_circleci(circle_build, circle_token):
    """ download build artifacts from circleCI and exit """
    print("I: downloading release artifacts")
    circle_auth = {"circle-token": circle_token}
    os.mkdir("_build")
    artifacts = requests.get("https://circleci.com/api/v1.1/project/github/gpodder/gpodder-osx-bundle/%s/artifacts" % circle_build,
                             params=circle_auth).json()
    items = set([u["url"] for u in artifacts
                if re.match(".+/gPodder-.+\.deps\.zip.*$", u["path"])
                or u["path"].endswith("/gPodder.contents")])
    if len(items) == 0:
        error_exit("Nothing found to download")
    print("D: downloading %s" % items)
    for url in items:
        print("I: downloading %s" % url)
        output = os.path.join("_build", url.split('/')[-1])
        with requests.get(url, params=circle_auth, stream=True) as r:
            with open(output, "wb") as f:
                for chunk in r.iter_content(chunk_size=1000000):
                    f.write(chunk)
    print("I: download success. Rerun without --circle-build to upload")
    sys.exit(0)


def checksum():
    """ compare downloaded archive with checksums """
    for f in os.listdir("_build"):
        if re.match("gPodder-.+\.deps\.zip.md5$", f):
            md5 = os.path.join("_build", f)
        elif re.match("gPodder-.+\.deps\.zip.sha256$", f):
            sha256 = os.path.join("_build", f)
        elif re.match("gPodder-.+\.deps\.zip$", f):
            archive = os.path.join("_build", f)
    if md5 and sha256 and archive:
        m = hashlib.md5()
        with open(md5, "r") as f:
            md5value = f.read().strip().split(" = ")[1]
        s = hashlib.sha256()
        with open(sha256, "r") as f:
            sha256value = f.read().split(" ")[0]
        with open(archive, "rb") as f:
            bloc = f.read(4096)
            while bloc:
                m.update(bloc)
                s.update(bloc)
                bloc = f.read(4096)
        md5cmp = m.hexdigest()
        sha256cmp = s.hexdigest()
        if md5value != md5cmp:
            error_exit(("E: invalid %s md5:\n"
                        "expected=%s\n"
                        "computed=%s") % (archive, md5value, md5cmp))
        if sha256value != sha256cmp:
            error_exit(("E: invalid %s sha256:\n"
                        "expected=%s\n"
                        "computed=%s") % (archive, sha256value, sha256cmp))
    else:
        error_exit("E: missing zip (%s), md5 (%s) or sha256 (%s) in _build"
                   % (archive, sha256value, sha256cmp))


def get_diff_previous_tag(tag, previous_tag):
    """ compare previous_tag's gPodder.contents with the one in _build
        @return formatted diff or empty string if no previous_tag
    """
    if not previous_tag:
        return ""
    resp = requests.get("https://github.com/gpodder/gpodder-osx-bundle/releases/download/%s/gPodder.contents"
                        % previous_tag)
    if resp.status_code is not 200:
        error_exit("Error getting previous gPodder.contents (%i): %s\n%s" % (resp.status_code, resp.reason, resp.text))
    previousContents = [l + "\n" for l in resp.text.split("\n") if not l.startswith(" ")]
    with open("_build/gPodder.contents", "r") as f:
        contents = [l for l in f.readlines() if not l.startswith(" ")]
    diff = difflib.unified_diff(previousContents, contents, fromfile=previous_tag, tofile=tag, n=1)
    return "```\n%s\n```" % "".join(diff)


def upload(repo, tag, previous_tag, circle_build):
    """ create github release (draft) and upload assets """
    print("I: creating release %s" % tag)
    try:
        release = repo.create_release(tag, name=tag, draft=True)
    except Exception as e:
        error_exit("Error creating release '%s' (%r)" % (tag, e))

    items = [f for f in os.listdir("_build")
             if re.match("gPodder-.+\.deps\.zip.*$", f) or f == "gPodder.contents"]
    if len(items) == 0:
        error_exit("Nothing found to upload")
    print("D: uploading items\n - %s" % "\n - ".join(items))
    for itm in items:
        content_type = "application/zip" if itm.endswith("zip") else "text/plain"
        print("I: uploading %s..." % itm)
        with open(os.path.join("_build", itm), "rb") as f:
            try:
                asset = release.upload_asset(content_type, itm, f)
            except Exception as e:
                error_exit("Error uploading asset '%s' (%r)" % (itm, e))
    print("I: upload success")

    print("I: updating release description with diff")
    diff = get_diff_previous_tag(tag, previous_tag)
    if circle_build:
        build = ("\ncircleCI build [%i](https://circleci.com/gh/gpodder/gpodder-osx-bundle/%i)"
                 % (circle_build, circle_build))
    else:
        build = ""
    if release.edit(body=diff + build):
        print("I: updated release description with diff")
    else:
        error_exit("E: updating release description")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='upload built artifacts to a github release')
    parser.add_argument('tag', type=str,
                        help='gpodder-osx-bundle git tag to create a release from')
    parser.add_argument('--download',
                        help='download artifacts from given circle.ci build number')
    parser.add_argument('--circle-build', type=str, required=False,
                        help='circleCI build number')
    parser.add_argument('--previous-tag', type=str, required=False,
                        help='previous github tag for contents comparison')
    parser.add_argument('--debug', '-d',
                        help='debug requests')

args = parser.parse_args()

if args.debug:
    debug_requests()

github_token = os.environ.get("GITHUB_TOKEN")
if not github_token:
    error_exit("E: set GITHUB_TOKEN environment", -1)

gh = login(token=github_token)
repo = gh.repository('gpodder', 'gpodder-osx-bundle')

if args.download:
    if not args.circle_build:
        error_exit("E: --download requires --circle-build number")
    if os.path.isdir("_build"):
        error_exit("E: _build directory exists", -1)
    circle_token = os.environ.get("CIRCLE_TOKEN")
    if not circle_token:
        error_exit("E: set CIRCLE_TOKEN environment", -1)
    download_circleci(args.circle_build, circle_token)
else:
    if not os.path.exists("_build"):
        error_exit("E: _build directory doesn't exist. Maybe you want to download circleci build artifacts (see Usage)", -1)

checksum()
upload(repo, args.tag, args.previous_tag, args.circle_build)
