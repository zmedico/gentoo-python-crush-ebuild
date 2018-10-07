# Copyright 1999-2018 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

PYTHON_COMPAT=( python2_7 python3_{4,5,6} )

inherit distutils-r1

MY_PN=crush
DESCRIPTION="crush is a library to control placement in a hierarchy"
HOMEPAGE="https://github.com/ceph/python-crush"
SRC_URI="mirror://pypi/${MY_PN:0:1}/${MY_PN}/${MY_PN}-${PV}.tar.gz
	doc? ( mirror://gentoo/${P}-sphinx.inv )"

LICENSE="GPL-3.0"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="doc test"
RESTRICT="!test? ( test )"

RDEPEND=">=dev-python/numpy-1.10.4[${PYTHON_USEDEP}]
	>=dev-python/pandas-0.19.1[${PYTHON_USEDEP}]"
DEPEND="${RDEPEND}
	dev-python/d2to1[${PYTHON_USEDEP}]
	>=dev-python/pbr-3.0.0[${PYTHON_USEDEP}]
	dev-python/setuptools[${PYTHON_USEDEP}]
	doc? (
		dev-python/mock[${PYTHON_USEDEP}]
		dev-python/sphinx[${PYTHON_USEDEP}]
	)
	test? ( dev-python/pytest[${PYTHON_USEDEP}] )"

S="${WORKDIR}/${MY_PN}-${PV}"

PATCHES=("${FILESDIR}/python-crush-1.0.35-merge-upstream-6a21da59837-f3bc838894aa.patch")

src_unpack() {
	default
	use doc && { cp "${DISTDIR}/${P}-sphinx.inv" "${S}/docs/${P}-sphinx.inv" || die; }
}

python_prepare_all() {
	sed -e 's:__ASSERT_FUNCTION decode_raw(v, p);:decode_raw(v, p);:' \
		-i crush/libcrush/include/encoding.h || die
	sed -e 's:#include "include/demangle\.h":\0\n#include "assert.h":' \
		-i crush/libcrush/common/mempool.cc || die
	sed -e "s|'http://crush.readthedocs.org/en/latest', None|'http://crush.readthedocs.org/en/latest', '${P}-sphinx.inv'|" \
		-i docs/conf.py || die
	sed -e '/:start-after:.*\[extension-crush.libcrush\]/d' \
		-e 's|\[extension-crush.libcrush\]|[extension-crush=libcrush]|' \
		-i docs/dev/hacking.rst || die
	sed -e 's|test_simple(|_\0|' \
		-e 's|test_very_different_weights(|_\0|' \
		-e 's|test_overweighted(|_\0|' \
		-i tests/test_optimize.py || die
	sed -e 's|test_analyze_bad_failure_domain(|_\0|' \
		-i tests/test_analyze.py || die
	sed -e 's|test_fail_mapping_name(|_\0|' \
		-e 's|test_fail_mapping_osds(|_\0|' \
		-i tests/test_ceph.py || die
	# Contains version locked direct deps (including build time deps),
	# and indirect deps from pip freeze.
	rm requirements*.txt crush.egg-info/requires.txt || die
	distutils-r1_python_prepare_all
}

python_compile_all() {
	use doc && esetup.py build_sphinx
}

python_test() {
	py.test -v tests || die "tests failed with ${EPYTHON}"
}

python_install_all() {
	use doc && HTML_DOCS=( build/html/. )
	distutils-r1_python_install_all
}

