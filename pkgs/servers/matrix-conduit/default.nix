{ stdenv, lib, fetchFromGitLab, rustPlatform, }:
rustPlatform.buildRustPackage rec {
  pname = "matrix-conduit";
  version = "unstable-2021-05-21";

  src = fetchFromGitLab {
    owner = "famedly";
    repo = "conduit";
    rev = "1aec80c57c02ef17475436c530b2ac2bc947b923";
    sha256 = "sha256-bz+afiRaGQ5wHRVzEXNoaFuS36JU9sOGjQ/7xQtl458=";
  };
  cargoSha256 = "sha256-tS7U2DPOt/H+yHgAhBO0RssQIQ/G+qc2Hhfp9mkhkiE=";

  meta = with lib; {
    description = "A Matrix homeserver written in Rust";
    homepage = "https://conduit.rs/";
    license = licenses.asl20;
    maintainers = with maintainers; [ pstn piegames ];
  };
}

