.PHONY: docs

default:
	@echo "targets: clean, install, flake8, upload"

clean:
	-rm -f ./.cbsh-history
	-rm -rf build
	-rm -rf dist
	-rm -rf *.egg-info
	-rm -rf ./docs/_build/*
	-find . -type d -name "__pycache__" -exec rm -rf {} \;
	-find . -name "*.pyc" -exec rm -f {} \;

docs:
	sphinx-build -b html ./docs ./docs/_build

install:
	pip install -r requirements-test.txt
	pip install -r requirements-rtd.txt
	pip install -e .

# upload to our internal deployment system
upload: clean
	python setup.py bdist_wheel
	aws s3 cp --acl public-read \
		dist/cbsh-*.whl \
		s3://fabric-deploy/cbsh/

# This will run pep8, pyflakes and can skip lines that end with # noqa
flake8:
	flake8 --ignore=E501 cbsh

pep8:
	pep8 --statistics --ignore=E501 -qq .

pep8_show_e231:
	pep8 --select=E231 --show-source

autopep8:
	autopep8 -ri --aggressive --ignore=E501 .

# build a statically linked executable using Pyinstaller
build_linux_exe: clean
	python setup.py sdist
	docker build -t cbsh -f docker/Dockerfile .
	docker create --name cbsh-build cbsh
	docker cp cbsh-build:/build/dist/cbsh ./dist/
	docker rm --force cbsh-build
	docker rmi cbsh

upload_linux_exe:
	aws s3 cp --acl public-read \
		dist/cbsh \
		s3://fabric-deploy/cbsh/linux/

build:
	python setup.py sdist bdist_wheel


publish: build
	twine upload dist/*
#	twine upload --repository-url=https://pypi.org/pypi dist/*
