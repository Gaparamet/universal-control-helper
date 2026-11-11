import Testing

/// Common parent for every Helper test. Several of these tests mutate process-global
/// static hooks (`TargetInputInjector`, `CapsLockManager`), and Swift Testing runs
/// separate suites in parallel, so all of them must live under this single serialized root.
@Suite(.serialized)
struct HelperSerialTests {}
