# Transaction Tab Null Row Crash Test Report 2026-05-25

## Summary

- Fixed the transaction tab crash shown as `type 'Null' is not a subtype of type 'String' of 'function result'`.
- The transaction list now reads nullable ledger display fields with safe SQL defaults before mapping rows into `TransactionItem`.

## Test Results

| Check | Result |
| --- | --- |
| `flutter test test/transaction_flow_test.dart` | Passed, 49 tests |
| `flutter test test/page_walkthrough_test.dart` | Passed, 19 tests |
| `flutter analyze` | Passed, no issues |

## Notes

- The fix is defensive at the ledger query boundary for investment and cash transaction rows.
- Manual verification against the user's exact local dataset is still recommended because the screenshot came from runtime data that is not part of the test fixtures.
