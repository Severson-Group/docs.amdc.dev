@ECHO OFF

pushd %~dp0

REM Command file for Sphinx documentation

if "%SPHINXBUILD%" == "" (
	set SPHINXBUILD=sphinx-multiversion
)
set SOURCEDIR=source
set BUILDDIR=build

if "%1" == "" goto help
if "%1" == "clean" goto clean

%SPHINXBUILD% >NUL 2>NUL
if errorlevel 9009 (
	echo.
	echo.The 'sphinx-multiversion' command was not found. Make sure you have Sphinx
	echo.and sphinx-multiversion installed, then set the SPHINXBUILD environment
	echo.variable to point to the full path of the 'sphinx-build' executable.
	echo.Alternatively you may add the Sphinx directory to PATH.
	echo.
	echo.If you don't have Sphinx installed, grab it from
	echo.https://www.sphinx-doc.org/
	echo.
	echo.Sphinx-Multiversion can be installed with pip
	echo.pip install sphinx-multiversion
	exit /b 1
)

%SPHINXBUILD% %SOURCEDIR% %BUILDDIR% %SPHINXOPTS% %O%
goto end

:clean
del /s "$(BUILDDIR)"
goto end

:help
%SPHINXBUILD% --help

:end
popd
