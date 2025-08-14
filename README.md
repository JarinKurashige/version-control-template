# version-control-template
Used for version control of files that all follow an idential format (e.g. Project outputs for PCB work, reports, etc)

## Init repo

Run commands in this order

1. `git clone --filter=blob:none --no-checkout git@github.com:JarinKurashige/version-control-template.git`
	- Clone the repo with no files
2. `cd version-control-template`
- Move into file
3. `git sparse-checkout init --cone`
- Init the repo with spare checkouts to allow you to be able to not clone the entire repo at once
4. `git sparse-checkout set Makefile`
- Pull the make file so that you can init the repo
5. `Make init`
- Init all files
