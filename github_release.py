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
import zipfile

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


def download_github(github_workflow):
    """ download workflow artifacts from github and exit """
    headers = {'Accept': 'application/vnd.github+json', 'Authorization': 'token %s' % github_token}

    print("I: downloading release artifacts for workflow %d" % github_workflow)
    r = requests.get("https://api.github.com/repos/gpodder/gpodder-osx-bundle/actions/artifacts", headers=headers)
    if not r.ok:
        print('ERROR: API fetch failed %d %s' % (r.status_code, r.reason))
        sys.exit(1)
    artifacts = r.json()
    artifact = [(a['id'], a['archive_download_url']) for a in artifacts['artifacts'] if a['workflow_run']['id'] == github_workflow]
    if len(artifact) != 1:
        error_exit("Nothing found to download")
    id, url = artifact[0]
    print("I: found artifact %d" % id)

    print("I: downloading %s" % url)
    os.mkdir("_build")
    with requests.get(url, stream=True, headers=headers) as r:
        if not r.ok:
            print('ERROR: artifact fetch failed %d %s' % (r.status_code, r.reason))
            sys.exit(1)
        with open('_build/bundle.zip', "wb") as f:
            for chunk in r.iter_content(chunk_size=1000000):
                f.write(chunk)
    print("I: unzipping _build/bundle.zip")
    with zipfile.ZipFile('_build/bundle.zip', 'r') as z:
        z.extractall('_build')
    os.remove('_build/bundle.zip')
    checksum()
    print("I: download success. Rerun without --download to upload")
    sys.exit(0)


def checksum():
    """ compare downloaded archive with checksums """
    for f in os.listdir("_build"):
        if re.match("pythonbase-.+\.zip.md5$", f):
            md5 = os.path.join("_build", f)
        elif re.match("pythonbase-.+\.zip.sha256$", f):
            sha256 = os.path.join("_build", f)
        elif re.match("pythonbase-.+\.zip$", f):
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
    """ compare previous_tag's pythonbase.contents with the one in _build
        @return formatted diff or empty string if no previous_tag
    """
    if not previous_tag:
        return ""
    resp = requests.get("https://github.com/gpodder/gpodder-osx-bundle/releases/download/%s/pythonbase.contents"
                        % previous_tag)
    if resp.status_code != 200:
        error_exit("Error getting previous pythonbase.contents (%i): %s\n%s" % (resp.status_code, resp.reason, resp.text))
    previousContents = [l + "\n" for l in resp.text.split("\n") if not l.startswith(" ")]
    with open("_build/pythonbase.contents", "r") as f:
        contents = [l for l in f.readlines() if not l.startswith(" ")]
    diff = difflib.unified_diff(previousContents, contents, fromfile=previous_tag, tofile=tag, n=1)
    return "```\n%s\n```" % "".join(diff)


def upload(repo, tag, previous_tag, github_workflow):
    """ create github release (draft) and upload assets """
    print("I: creating release %s" % tag)
    try:
        release = repo.create_release(tag, name=tag, draft=True)
    except Exception as e:
        error_exit("Error creating release '%s' (%r)" % (tag, e))

    items = [f for f in os.listdir("_build")
             if re.match("pythonbase-.+\.zip.*$", f) or f == "pythonbase.contents"]
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
    if github_workflow:
        workflow = ("\ngithub workflow [%i](https://github.com/gpodder/gpodder-osx-bundle/actions/runs/%i)"
                 % (github_workflow, github_workflow))
    else:
        workflow = ""
    if release.edit(body=diff + workflow):
        print("I: updated release description with diff")
    else:
        error_exit("E: updating release description")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='upload gpodder-osx-bundle artifacts to a github release\n'
        'Example usage: \n'
        '    GITHUB_TOKEN=xxx python github_release.py --download --github-workflow 1234567890 --previous-tag 22.7.27 22.7.28\n'
        '    GITHUB_TOKEN=xxx python github_release.py --github-workflow 1234567890 --previous-tag 22.7.27 22.7.28\n',
        formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument('tag', type=str,
                        help='gpodder-osx-bundle git tag to create a release from')
    parser.add_argument('--download', action='store_true',
                        help='download artifacts from given github workflow')
    parser.add_argument('--github-workflow', type=int, required=False,
                        help='github workflow number (in URL)')
    parser.add_argument('--previous-tag', type=str, required=False,
                        help='previous github tag for contents comparison')
    parser.add_argument('--debug', '-d', action='store_true',
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
    if not args.github_workflow:
        error_exit("E: --download requires --github-workflow number")
    if os.path.isdir("_build"):
        error_exit("E: _build directory exists", -1)
    download_github(args.github_workflow)
else:
    if not os.path.exists("_build"):
        error_exit("E: _build directory doesn't exist. Maybe you want to download github workflow artifacts (see Usage)", -1)

checksum()
upload(repo, args.tag, args.previous_tag, args.github_workflow)
