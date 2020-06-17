# Bookworm

Welcome to the Bookworm project and to the internet computer development community.

We aim to build a decentralized book publishing platform.

[Business model (internal link)](https://docs.google.com/document/d/1IBrPQiPBkt7jFslnJUVR4wOh-g3j55LRJlntRfWBMHY)

[UI design and slides (internal link)](https://docs.google.com/presentation/d/1n0FY3-A5Sr3Pl82i37WQLSVBDaw3Oi0ydPbc1H1s1Kk)

[Draft of system design](./doc/system_design.md)

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
# there is no need to dfx stop, because the above crashes the system!
```

Frontend UI is still WIP.
