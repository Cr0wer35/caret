# Swift Crashcourse for Caret

_Last updated: 2026-04-21_

This is a **targeted** Swift primer for someone who has written a lot of TypeScript / Java / Python and zero Swift. It covers only what you'll actually touch in Caret. It is not a general Swift tutorial — go to [Swift.org](https://www.swift.org/documentation/) for that.

We focus on the concepts that surprise people coming from other typed languages.

## The 60-second mental model

Swift is:

- **Statically typed**, type-inferred. Feels like TypeScript with stricter rules.
- **Value-type first**: structs are the default (like C#), classes used sparingly (like in a Java-lite world).
- **Null-safe by design**: `Optional<T>` (written `T?`) is in your face everywhere, like Rust's `Option<T>`.
- **Concurrency-first in Swift 6**: the compiler *refuses* to let you share mutable state unsafely across threads. This is the biggest shift.
- **Protocol-oriented** (Go-ish interfaces, but richer).
- **Runs with ARC**, not GC. No manual memory, but you can create retain cycles if you're not careful with closures.

## Syntax in 30 lines

```swift
// Constants and variables
let name = "Caret"                  // immutable
var count: Int = 0                  // mutable, explicit type

// Optionals
var apiKey: String? = nil           // can be nil
if let key = apiKey { ... }         // unwrap safely
let safe = apiKey ?? "default"      // default value
let force = apiKey!                 // crash if nil — don't do this

// Functions
func greet(_ name: String, loud: Bool = false) -> String {
    loud ? "HELLO \(name.uppercased())!" : "Hello \(name)"
}
greet("world")                      // "Hello world"
greet("world", loud: true)          // "HELLO WORLD!"

// Structs (value type)
struct Point { var x: Double; var y: Double }
var p = Point(x: 1, y: 2)
var q = p                           // COPY, not reference
q.x = 99                            // p.x is still 1

// Classes (reference type) — used for Cocoa interop, NSPanel, etc.
class Counter { var n = 0; func tick() { n += 1 } }

// Protocols (interfaces on steroids)
protocol Greeter { func greet() -> String }
extension String: Greeter { func greet() -> String { "Hi \(self)" } }

// Enums with associated values (tagged unions)
enum Result { case success(String); case failure(Error) }
```

## Optionals — the most important chapter

Nothing in Swift is nullable unless you mark it with `?`. Your code literally cannot compile if you pass `nil` where a non-optional is expected.

```swift
let text: String = readFocusedText()      // must return String, cannot be nil
let maybe: String? = tryRead()            // may be nil

// Idiomatic patterns
if let t = maybe { print(t) }             // bind if present
guard let t = maybe else { return }       // bind or bail out early
maybe?.count                              // chained access, result is Int?
maybe.map { $0.uppercased() }             // transform if present
```

In Caret, you'll see optionals everywhere around AX calls because AX is a C API and almost everything can fail.

## Concurrency — the big one

Swift 6 *enforces* thread safety at compile time. This is strict and alien the first day, comfortable by day three.

### Three keywords you'll see constantly

- `async` — a function that can suspend and resume later.
- `await` — call site of an async function, hands off control.
- `actor` — a class-like type whose state is automatically serialized (one thread at a time inside).

```swift
// Async function
func fetchCorrection() async throws -> CorrectionResponse {
    let (data, _) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode(CorrectionResponse.self, from: data)
}

// Call site
Task {
    do {
        let result = try await fetchCorrection()
        print(result)
    } catch {
        print("failed:", error)
    }
}

// Actor — isolates mutable state
actor CorrectionCache {
    private var entries: [String: CorrectionResponse] = [:]
    func get(_ key: String) -> CorrectionResponse? { entries[key] }
    func set(_ key: String, _ value: CorrectionResponse) { entries[key] = value }
}

let cache = CorrectionCache()
await cache.set("foo", response)          // `await` because cross-actor calls are async
```

### @MainActor

Anything touching UI must run on the main thread. Swift models this as "the main actor":

```swift
@MainActor
class SuggestionPanel { ... }             // every method runs on the main thread

@MainActor
func showPanel() { ... }                  // this specific function must be called from main
```

Most SwiftUI views are implicitly `@MainActor`.

### Sendable

A type is `Sendable` if it's safe to pass between threads. Structs of primitives are `Sendable` for free. Classes usually are not. You'll see the compiler complain:

```
Type 'Foo' does not conform to the 'Sendable' protocol
```

Fixes:
- Make it a `struct` with value-type fields → free.
- Make it a `final class` and prove no shared mutable state with `@unchecked Sendable` (escape hatch, use sparingly).
- Wrap it in an `actor` if it holds mutable state.

### Task and cancellation

```swift
let task = Task {
    try await fetchCorrection()
}
// Later...
task.cancel()                             // cooperatively cancels; the task must check
```

In Caret, cancellation is critical for the trigger engine — new keystrokes must cancel in-flight LLM requests.

## SwiftUI vs AppKit — when to use which

| Use SwiftUI for | Use AppKit for |
|---|---|
| Settings window | `NSPanel` (the suggestion panel) |
| Menu bar popover content | `NSStatusItem` (the menu bar icon) |
| Onboarding view | `CGEventTap` (C-level API) |
| Anything form-y with labels + fields | `AXUIElement` (C-level API) |

SwiftUI is fast to build, declarative, and perfect for settings and forms. AppKit is mandatory for anything touching system-level UI or C APIs. They interop via `NSViewRepresentable` / `NSHostingView`.

Example — embedding SwiftUI in an `NSPanel`:

```swift
let panel = NSPanel(contentRect: .zero, styleMask: [.nonactivatingPanel, .hud],
                    backing: .buffered, defer: false)
panel.contentView = NSHostingView(rootView: SuggestionView(text: "hello"))
panel.orderFront(nil)
```

## Working with C APIs (AX, CGEventTap)

Lots of macOS APIs are C-based. Swift bridges them with some ceremony:

```swift
// Read a string attribute from a focused element
var value: CFTypeRef?
let err = AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &value)
guard err == .success, let text = value as? String else { return nil }
```

Key points:
- C types have `CF*` prefixes (CoreFoundation).
- Bridging to Swift types is often just `as?`.
- Errors are `AXError` enum — check against `.success`.
- Never hold a `CFTypeRef` across threads without care; they're not `Sendable`.

In Caret, all AX calls are centralized in `AXHelpers.swift` so C ugliness stays in one place.

## Keychain — the API that looks angry

The Security framework is from the pre-Swift era. It uses dictionaries and error codes. Wrap it once, forget it forever:

```swift
func storeKey(_ value: String, for service: String) throws {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: service,
        kSecValueData as String: value.data(using: .utf8)!,
    ]
    SecItemDelete(query as CFDictionary)  // replace existing
    let status = SecItemAdd(query as CFDictionary, nil)
    if status != errSecSuccess { throw KeychainError(status: status) }
}
```

80 lines total for store/read/delete. Don't pull in a dependency for this.

## Testing

Swift 6 has a new testing framework that's dramatically nicer than XCTest:

```swift
import Testing

@Suite("TriggerEngine")
struct TriggerEngineTests {
    @Test("Fires after 3 words + 400ms idle")
    func testBasicFire() async throws {
        let engine = TriggerEngine()
        await engine.record(.word)
        await engine.record(.word)
        await engine.record(.word)
        try await Task.sleep(for: .milliseconds(500))
        #expect(await engine.shouldFire == true)
    }
}
```

Use this for everything except UI tests (which still need XCTest).

## Common gotchas for TypeScript/Java devs

1. **No automatic string interpolation**: `"Hello \(name)"`, not `` `Hello ${name}` ``.
2. **Closures capture by reference by default**: if a closure outlives its context and captures `self`, you'll leak memory. Use `[weak self]` in long-lived closures.
3. **`Equatable` and `Hashable` are protocols you often have to conform to explicitly**: structs with all-Equatable fields get synthesis for free, but enums and classes sometimes don't.
4. **Imports are per-file, not global**: every file starts with `import Foundation`, `import AppKit`, etc.
5. **Access control**: `public` / `internal` (default) / `fileprivate` / `private`. `internal` is per-module — in Caret that's basically the whole app.
6. **No `try/catch` — it's `do/catch`**: `try` is at the expression level, then `catch` handles.
7. **Throwing is not like Java exceptions**: functions must declare `throws`, callers must use `try`. No hidden exceptions.

## What to read when stuck

- **Apple documentation** (the real, generated reference): https://developer.apple.com/documentation/
- **Swift.org book**: https://docs.swift.org/swift-book/
- **Paul Hudson's Hacking with Swift**: short, practical Swift recipes.
- **Swift Forums**: active, friendly, searchable.
- **Hacking with macOS** (same author) for AppKit/NSPanel specifics.

Do NOT rely on Stack Overflow answers older than 2022; Swift changed dramatically with Swift 5.5 (async/await) and Swift 6 (strict concurrency).

## The single-most-useful reflex

When the compiler complains about concurrency, **don't fight it**. The error message usually tells you exactly which layer needs isolation. Read it twice, then refactor with one of:

- Mark a type `Sendable`.
- Wrap mutable state in an `actor`.
- Pin a function to `@MainActor`.

Guessing with `@unchecked Sendable` or `nonisolated(unsafe)` is usually a sign you're avoiding the real problem. In Caret, we avoid both escape hatches unless there's a one-line justification in a code comment.
