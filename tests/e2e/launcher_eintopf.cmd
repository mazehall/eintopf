@IF EXIST "%~dp0\node.exe" (
  "%~dp0\node.exe" "%~dp0launcher_eintopf" %*
) ELSE (
  node "%~dp0launcher_eintopf" %*
)