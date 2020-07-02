import Array "mo:base/Array";
import Hash "mo:base/Hash";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import List "mo:base/List";
import Nat "mo:base/Nat";
import Option "mo:base/Option";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Prim "mo:prim";
import Principal "mo:base/Principal";
import TrieMap "mo:base/TrieMap";

type Biography = {
  name: Text;
  biography: Text;
};

type Catalog = TrieMap.TrieMap<BookId, Book>;

type Book = {
  summary: BookSummary;
  chapters: Chapters;
};

type Chapters = TrieMap.TrieMap<ChapterId, (Chapter, Bool)>;

type Chapter = {
  summary: ChapterSummary;
  content: Text;
};

type Subscribers = TrieMap.TrieMap<UserId, Subscriptions>;

type Subscriptions = TrieMap.TrieMap<BookId, [ChapterId]>;

type BookSummary = {
  title: Text;
  summary: Text;
};

type ChapterSummary = {
  title: Text;
  summary: Text;
};

type UserId = Principal;

type BookId = Nat;

type ChapterId = Text;

type BookNotFoundError = { #BookNotFound };

type ChapterReadError = {#ChapterNotFound; #ChapterNotPaid};

type PublishError = { #BookNotFound; #ChapterNotFound };

actor {

  // Author's biography.
  var biography: Biography = {
    name = "";
    biography = "";
  };

  // The database that holds all books.
  var catalog: Catalog = TrieMap.TrieMap<BookId, Book>(
    func(x:Nat, y:Nat) : Bool { x == y },
    Hash.hash
  );

  // Get author's biography.
  public func get_biography() : async Biography {
    biography
  };

  // List all published BookIds.
  public func get_catalog() : async [BookId] {
    Iter.toArray(
      Iter.map(
        catalog.entries(),
        func ((k, v) : (BookId, Book)) : BookId = { k }
      )
    )
  };

  // Get the book summary of a published book.
  public func get_book_summary(book_id: BookId) : async ?BookSummary {
    Option.map(catalog.get(book_id), func (book: Book) : BookSummary { book.summary })
  };

  // Get the chapter summary of a published chapter.
  public func get_chapter_summary(book_id: BookId, chapter_id: ChapterId)
  : async ?ChapterSummary {
    Option.chain(
      catalog.get(book_id), 
      func (book: Book) : ?ChapterSummary {
        Option.map(
          book.chapters.get(chapter_id),
          func ((chapter: Chapter, _: Bool)) : ChapterSummary { chapter.summary }
        )
      }
    )
  };

  // Get the list of published ChapterIds.
  public func get_chapters(book_id: BookId) : async Result.Result<[ChapterId], BookNotFoundError> {
    Result.fromOption<[ChapterId], BookNotFoundError>(
      Option.map(
        catalog.get(book_id), 
        func (book: Book) : [ChapterId] {
          Array.map(
            Array.filter(
              func ((_: ChapterId, (_: Chapter, published: Bool))) : Bool { published },
              Iter.toArray(book.chapters.entries())
            ),
            func ((chapter_id: ChapterId, _: (Chapter, Bool))) : ChapterId { chapter_id }
          )
        }
      ),
      #BookNotFound
    )
  };

  // Get a published chapter content.
  public func get_chapter(book_id: BookId, chapter_id: ChapterId)
  : async Result.Result<Chapter, ChapterReadError> {
    Result.fromOption<Chapter, ChapterReadError>(
      Option.chain(
        catalog.get(book_id), 
        func (book: Book) : ?Chapter {
          Option.chain(
            book.chapters.get(chapter_id),
            func ((chapter: Chapter, published: Bool)) : ?Chapter {
              if (published) { ?chapter } else { null }
            }
          )
        }
      ),
      #ChapterNotFound
    )
  };

  /*
  // For reader to subscribe a book.
  subscribe(BookId) -> ()
  
  // For reader to unsubscribe a book.
  unsubscribe(BookId) -> ()
  
  // For reader to make payment for a chapter.
  pay_chapter(BookId, ChapterId) -> Result<(), PaymentError>
  */
  
  // For writer to update a chapter.
  public func update_chapter(book_id: BookId, chapter_id: ChapterId, content: Text)
  : async Result.Result<(), BookNotFoundError> {
    let book_ = catalog.get(book_id);
    if (Option.isNull(book_)) {
      return (#err (#BookNotFound)); 
    };
    let book = Option.unwrap(book_);

    // Delete the chapter if content is empty
    if (content == "") {
      let _ = book.chapters.delete(chapter_id);
    }
    else {
      // chapter title is taken from 1st paragraph of content
      let (title_, remaining) = breakLn(content);
      // chapter summary is taken from 2nd paragraph of content
      let (summary_, body_) = breakLn(remaining);

      let chapter = {
        summary = {
          title = title_;
          summary = summary_;
        };
        content = body_;
      };
      let published = Option.get(
        Option.map(
          book.chapters.get(chapter_id),
          func ((_: Chapter, published_: Bool)) : Bool { published_ },
        ),
        false
      );
      let _ = book.chapters.put(chapter_id, (chapter, published));
    };
    #ok ()
  };

  // For writer to add a new book.
  public func add_book(title_: Text, summary_: Text) : async BookId {
    let book_id : BookId = catalog.size();
    let book : Book = {
      summary = {
        title = title_;
        summary = summary_;
      };
      chapters = TrieMap.TrieMap<ChapterId, (Chapter, Bool)>(
        func(x:Text, y:Text) : Bool { x == y },
        Text.hash // We need a better hash function
      );
    };
    let _ = catalog.put(book_id, book);
    book_id
  };

  // For writer to publish a book/chapter.
  public func publish(book_id: BookId, chapter_id: ChapterId)
  : async Result.Result<(), PublishError> {
    set_published(book_id, chapter_id, true)
  };

  // For writer to unpublish a book/chapter.
  // (This only hides it from new readers, but not from paid subscribers)
  // For writer to publish a book/chapter.
  public func unpublish(book_id: BookId, chapter_id: ChapterId)
  : async Result.Result<(), PublishError> {
    set_published(book_id, chapter_id, false)
  };

  func set_published(book_id: BookId, chapter_id: ChapterId, published: Bool)
  : Result.Result<(), PublishError> {
    let book_ = catalog.get(book_id);
    if (Option.isNull(book_)) {
      return (#err (#BookNotFound));
    };
    let book = Option.unwrap(book_);

    let chapter_ = book.chapters.get(chapter_id);
    if (Option.isNull(chapter_)) {
      return (#err (#ChapterNotFound));
    };
    let (chapter, _) = Option.unwrap(chapter_);
    let _ = book.chapters.put(chapter_id, (chapter, published));
    #ok ()
  };

  func arrayToText(chars: [Char]) : Text {
    Array.foldLeft<Char, Text>(
      chars,
      "",
      func (s: Text, c: Char) : Text { s # Prim.charToText(c) },
    )
  };

  func findIndex<A>(f : A -> Bool, xs : [A]) : ?Nat {
    for (i in Iter.range(0, xs.size() - 1)) {
      if (f(xs[i])) {
        return ?i;
      }
    };
    return null;
  }; 

  // Find the first line break, and return text before and after it as a tuple.
  func breakLn(text: Text) : (Text, Text) {
      let str : [Char] = Iter.toArray(Text.toIter(text));
      let n = str.size();
      let i = 0;
      var pos = 0;
      switch (findIndex(func (c: Char) : Bool { c == '\n' }, str)) {
        case null { (text, "") };
        case (?i) {
          (arrayToText(Array.tabulate<Char>(i, func (j: Nat) : Char { str[j] })),
           arrayToText(Array.tabulate<Char>(n - i - 1, func (j: Nat) : Char { str[j + i + 1] }))
          );
        };
      }
  }

};
