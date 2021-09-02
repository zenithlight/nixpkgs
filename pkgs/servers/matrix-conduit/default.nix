{ stdenv, lib, fetchFromGitLab, rustPlatform, }:

rustPlatform.buildRustPackage rec {

  pname = "matrix-conduit";
  version = "0.2.0";

  src = fetchFromGitLab {
    owner = "famedly";
    repo = "conduit";
    rev = "v${version}";
    sha256 = "09c824392p2q6ir2ar0wfrbp8y2pfn0kwxhwi3ab5s03bs8bps7j";
  };

  cargoSha256 = "0379dvc8m8clc9lrxd1x0aciqvcgv3hjq7xfspz3bh8aq2a43pcs";

  meta = with lib; {
    description = "A Matrix homeserver written in Rust";
    homepage = "https://conduit.rs/";
    license = licenses.asl20;
    maintainers = with maintainers; [ pstn piegames ];
  };
}
