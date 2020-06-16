# System Design

Our goal is to build a book publishing platform following a distributed architecture, where writers can interact with readers by operating their own canisters.
Each canister is standalone, and provides all services including serving web pages, accepting user payments, running community forums, and so on.

To allow easy content discovery, there is another content aggregator canister that acts as search engine, and will accept submission and updates from writer canisters. It provides a public interface to serve the reader community at large.

## Canister Interface

### `WriterCanister`

Basic functional requirements:

- Writers can upload/update new books/chapters.
- Readers can subscribe to a book, read its chapters (optionally having to pay first).
- The writer can upload/update unfinished book chapters without publishing them.
- The writer can publish a book/chapter when it is ready.
- Payments are made per chapter.
- The writer decides payment option for a chapter, pre-pay, post-pay, monthly subscription, etc.
- We start with post-pay first.

```
// Get author's bio.
get_biography() -> Biography;

// List all published BookIds.
get_catalog() -> [BookId]

// Get the book summary of a published book.
get_book_summary(BookId) -> BookSummary

// Get the chapter summary of a published chapter.
get_chapter_summary(BookId, ChapterId) -> ChapterSummary

// Get the list of published ChapterIds.
get_chapters(BookId) -> Result<[ChapterId], BookNotFoundError>

// Get a published chapter content.
get_chapter(BookId, ChapterId) -> Result<Chapter, ChapterReadError>

// For reader to subscribe a book.
subscribe(BookId) -> ()

// For reader to unsubscribe a book.
unsubscribe(BookId) -> ()

// For reader to make payment for a chapter.
pay_chapter(BookId, ChapterId) -> Result<(), PaymentError>

// For writer to update a chapter.
update_chapter(BookId, ChapterId, Text) -> Result<(), BookNotFoundError>

// For writer to add a new book.
add_book(Title, Summary) -> BookId

// For writer to publish a book/chapter.
publish(BookId, ChapterId, PaymentScheme) -> Result<(), PublishError>;

// For writer to unpublish a book/chapter.
// (This only hides it from new readers, but not from paid subscribers)
unpublish(BookId, ChapterId) -> Result<(), PublishError>;

// For aggregator to pull new updates.
get_update_since(Date) -> Updates;
```

### `AggregatorCanister`

```
// For WriterCanister to join the aggregator.
join(WriterCanisterId);

// For WriterCanister to leave the aggregator.
leave(WriterCanisterId);

// For WriterCanister to push new updates.
push_update_since(Date, Updates);

// List top books according to the given Criteria (newest, highest ranked, etc.)
list_top(Count, Criteria) -> [BookSummary];
```

## Data Schema Overview

The core set of data managed by a WriterCanister includes the following (simplified) data types:

```
// Name of the writer and a short intro.
Biography = (Name, Bio)

// A collection of books is a mapping from BookId to Book.
Catalog = BookId -> Book

// A book has a title and a collection of chapters which is a mapping from ChapterId to Chapter.
Book = (Title, Chapters)

Chapter = ChapterId -> Text

// A collection of subscribers is a mapping from UserId to their Subscriptions.
Subscribers = UserId -> Subscriptions

// A collection of subscriptions is a mapping from BookId to a list of ChapterId that a user has paid for this book.
Subscriptions = BookId -> [ChapterId]
```
