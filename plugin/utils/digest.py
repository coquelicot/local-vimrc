#!/usr/bin/env python

import argparse
import hashlib
import hmac
import os
import sys

KEY_LEN = 32
KEY_FILE = os.path.expanduser("~/.vim/.local-vimrc-key")
DIGEST_PREFIX = '" local-vimrc-digest: '


def read_key(key_file=KEY_FILE):

    # if we don't have such file, generate one
    if not os.path.exists(key_file):
        fd = os.open(key_file, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        with os.fdopen(fd, "w") as fout:
            key = os.urandom(KEY_LEN).encode("hex")
            fout.write(key)

    with open(key_file, "r") as fin:
        key = fin.read().strip().decode("hex")
        assert len(key) == KEY_LEN
        return key


def read_rc(file=None):

    if file is None:
        lines = sys.stdin.readlines()
    else:
        with open(file, "r") as fin:
            lines = fin.readlines()

    # extract digest from last line
    if len(lines) > 0 and lines[-1].startswith(DIGEST_PREFIX):
        digest = lines.pop()[len(DIGEST_PREFIX):].strip()
    else:
        digest = None

    return "".join(lines), digest


def calc_digest(key, data):
    return hmac.new(key, data, hashlib.sha1).hexdigest()


def cmd_verify_rc(file):

    content, orgi_digest = read_rc(file)
    if orgi_digest is None:
        sys.stderr.write("Missing digest.\n")
        sys.exit(-1)

    digest = calc_digest(read_key(), content)
    if (digest != orgi_digest):
        sys.stderr.write("Wrong digest: expect `{}' but `{}' get.\n".format(
            digest, orgi_digest))
        sys.exit(-1)


def cmd_update_rc(file):

    content, _ = read_rc(file)
    if content != "" and content[-1] != "\n":
        content += "\n"

    digest = calc_digest(read_key(), content)
    content += DIGEST_PREFIX + digest + "\n"

    if file:
        with open(file, "w") as fout:
            fout.write(content)
    else:
        sys.stdout.write(content)


if __name__ == "__main__":

    parser = argparse.ArgumentParser()
    parser.add_argument("cmd", choices=["verify", "update"], help="command")
    parser.add_argument("file", nargs="?", help="target file")
    options = parser.parse_args()

    if options.cmd == "verify":
        cmd_verify_rc(options.file)
    elif options.cmd == "update":
        cmd_update_rc(options.file)
    else:
        assert False
