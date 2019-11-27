# Copyright 2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit acct-user

DESCRIPTION="A user for the aesmd"
ACCT_USER_ID=999
ACCT_USER_SHELL=/sbin/nologin
ACCT_USER_HOME=/var/opt/aesmd
ACCT_USER_HOME_OWNER=aesmd:aesmd
ACCT_USER_HOME_PERMS=0770
ACCT_USER_GROUPS=( aesmd )

acct-user_add_deps
