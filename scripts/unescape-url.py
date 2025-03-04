#!/usr/bin/env python3

# SPDX-FileCopyrightText: 2021 Gleb Smirnov <glebsmirnov0708@gmail.com>
#
# SPDX-License-Identifier: GPL-3.0-or-later

from urllib.parse import unquote_plus
from sys import stdin, stdout

stdout.write(unquote_plus(stdin.read()))
