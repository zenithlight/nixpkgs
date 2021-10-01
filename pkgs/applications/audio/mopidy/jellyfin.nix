{ lib, python3Packages, mopidy }:

python3Packages.buildPythonApplication rec {
  pname = "Mopidy-Jellyfin";
  version = "1.0.0";

  src = python3Packages.fetchPypi {
    inherit pname version;
    sha256 = "aX5ynYGhTSx6Pxk7YFNaEHjbpZTxkVfHgxHm3vOkROw=";
  };

  propagatedBuildInputs = [ mopidy python3Packages.unidecode python3Packages.websocket-client ];

  # no tests implemented
  doCheck = false;
  pythonImportsCheck = [ "mopidy_jellyfin" ];

  meta = with lib; {
    homepage = "https://github.com/jellyfin/mopidy-jellyfin";
    description = "Mopidy extension for playing audio files from Jellyfin";
    license = licenses.asl20;
    maintainers = [ maintainers.pstn ];
  };
}

