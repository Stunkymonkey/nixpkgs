{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  fetchpatch,
  setuptools,
  # build inputs
  starlette,
  brotli,
  # check inputs
  httpx,
  requests,
  mypy,
  brotlipy,
}:
buildPythonPackage (finalAttrs: {
  pname = "brotli-asgi";
  version = "1.6.0";
  pyproject = true;

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "fullonic";
    repo = "brotli-asgi";
    tag = "v${finalAttrs.version}";
    hash = "sha256-cF7A3mnkQmvtc9DgHiwqYEQQ6QagjoBGTmcBzUm6vvs=";
  };

  patches = [
    # the v1.6.0 tag lacks the version bump in setup.py
    # https://github.com/fullonic/brotli-asgi/pull/41
    (fetchpatch {
      name = "bump-version-to-1.6.0.patch";
      url = "https://github.com/fullonic/brotli-asgi/commit/9119b34b58a2930ceb3a8bc2274ce36b23ad522a.patch";
      hash = "sha256-/1L4xf25wFEZrFXxbFvHuxt8B/l4q5VHXXSlyO7+Ox0=";
    })
  ];

  build-system = [ setuptools ];

  dependencies = [
    starlette
    brotli
  ];

  pythonImportsCheck = [ "brotli_asgi" ];

  nativeCheckInputs = [
    httpx
    requests
    mypy
    brotlipy
  ];

  meta = {
    description = "Compression AGSI middleware using brotli";
    homepage = "https://github.com/fullonic/brotli-asgi";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ happysalada ];
  };
})
