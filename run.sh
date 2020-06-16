#!/usr/bin/env bash

function setup() {
  rm -rf canisters
  dfx start --clean --background
  dfx build || exit 1
  dfx canister install --all
}

function call() {
  fun=$1
  arg=$2
  expected=$3
  dfx canister call bookworm "$fun" "$arg" 2> /dev/null
}

function test_call() {
  fun=$1
  arg=$2
  expected=$3
  echo Run: dfx canister call bookworm \""$fun"\" \""$arg"\"
  output=$(dfx canister call bookworm "$fun" "$arg" 2> /dev/null)
  if [ "$expected" != "$output" ]; then
    echo Expecting:
    echo $expected
    echo But got:
    echo $output
    exit 2
  fi
  echo Ok
}

function parse() {
  echo $*|sed -e 's/^(//' -e 's/)$//'
}

function run_tests() {
  book_id=$(parse $(call add_book '("Some Book", "This is a test book")'))
  echo book_id = $book_id
  
  ok="(variant { 24860 = null })"
  chapter_id="\"1.1\""
  chapter="Chapter One
Synopsis
Real Content";
  test_call update_chapter "($book_id, $chapter_id, \"$chapter\")" "$ok"
  test_call publish "($book_id, $chapter_id)" "$ok"
  test_call get_biography "(record { 1224700491 = \"\"; 1355600947 = \"\"; })"
  
  # dfx canister call bookworm get_catalog
  
  test_call get_book_summary "($book_id)" \
    "(opt record { 272307608 = \"Some Book\"; 2162756390 = \"This is a test book\"; })"
  
  test_call get_chapter_summary "($book_id, $chapter_id)" \
    "(opt record { 272307608 = \"Chapter One\"; 2162756390 = \"Synopsis\"; })"
  
  test_call get_chapters "($book_id)" "(variant { 24860 = vec { \"1.1\"; } })"
  
  test_call get_chapter "($book_id, $chapter_id)" \
    "(variant { 24860 = record { 427265337 = \"Real Content\"; 2162756390 = record { 272307608 = \"Chapter One\"; 2162756390 = \"Synopsis\"; }; } })"
}

case "$1" in
  setup) setup;;
  tests) run_tests;;
  *) echo Usage $0: "[setup|tests]";;
esac
