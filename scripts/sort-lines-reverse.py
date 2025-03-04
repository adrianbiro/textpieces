#!/usr/bin/env python3

# SPDX-FileCopyrightText: 2021 Gleb Smirnov <glebsmirnov0708@gmail.com>
#
# SPDX-License-Identifier: GPL-3.0-or-later

from sys import stdin, stdout

stdout.write('\n'.join(sorted(map(lambda s: s.replace('\n', ''), stdin), reverse=True)))
