# Bookworm

Welcome to the Bookworm project and to the internet computer development community.

We aim to build a decentralized book publishing platform.

[Draft of system design](./docs/system_design.md)

To run unit tests locally:

```
cd bookworm/
./run.sh setup
./run.sh tests
dfx stop
```

Example of uploading a chapter (as a writer):

```
cd bookworm/
./two_cities.sh setup
./two_cities.sh upload
dfx stop
```

Frontend UI is still WIP.
