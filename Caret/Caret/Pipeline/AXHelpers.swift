import AppKit
import ApplicationServices

/// Thin, synchronous wrappers over the Accessibility C API.
/// All functions return `nil` on any AX error; callers decide what to do.
///
/// Marked `nonisolated` so any actor (including `TextCapture`) can call
/// these without hopping to the main thread — the AX C APIs are thread-safe.
nonisolated enum AXHelpers {
    static func focusedElement() -> AXUIElement? {
        copyAttribute(
            of: AXUIElementCreateSystemWide(),
            named: kAXFocusedUIElementAttribute,
            type: AXUIElement.self
        )
    }

    static func string(_ attribute: String, of element: AXUIElement) -> String? {
        copyAttribute(of: element, named: attribute, type: String.self)
    }

    static func range(_ attribute: String, of element: AXUIElement) -> NSRange? {
        guard let value = copyAttribute(of: element, named: attribute, type: AXValue.self)
        else { return nil }
        var cfRange = CFRange()
        guard AXValueGetValue(value, .cfRange, &cfRange) else { return nil }
        return NSRange(location: cfRange.location, length: cfRange.length)
    }

    static func bounds(for range: NSRange, in element: AXUIElement) -> CGRect? {
        var cfRange = CFRange(location: range.location, length: range.length)
        guard let rangeValue = AXValueCreate(.cfRange, &cfRange) else { return nil }
        guard
            let axResult = copyParameterizedAttribute(
                of: element,
                named: kAXBoundsForRangeParameterizedAttribute,
                parameter: rangeValue,
                type: AXValue.self
            )
        else { return nil }
        var rect = CGRect.zero
        guard AXValueGetValue(axResult, .cgRect, &rect) else { return nil }
        return rect
    }

    static func bundleID(of element: AXUIElement) -> String? {
        var pid: pid_t = 0
        guard AXUIElementGetPid(element, &pid) == .success else { return nil }
        return NSRunningApplication(processIdentifier: pid)?.bundleIdentifier
    }

    /// Screen-space frame of the element (top-left origin, AX coords).
    /// Combines `kAXPositionAttribute` and `kAXSizeAttribute`.
    static func frame(of element: AXUIElement) -> CGRect? {
        guard
            let posValue = copyAttribute(
                of: element, named: kAXPositionAttribute, type: AXValue.self
            ),
            let sizeValue = copyAttribute(
                of: element, named: kAXSizeAttribute, type: AXValue.self
            )
        else { return nil }
        var origin = CGPoint.zero
        var size = CGSize.zero
        guard
            AXValueGetValue(posValue, .cgPoint, &origin),
            AXValueGetValue(sizeValue, .cgSize, &size)
        else { return nil }
        return CGRect(origin: origin, size: size)
    }

    @discardableResult
    static func setString(_ value: String, attribute: String, of element: AXUIElement) -> Bool {
        AXUIElementSetAttributeValue(element, attribute as CFString, value as CFString)
            == .success
    }

    @discardableResult
    static func setRange(_ range: NSRange, attribute: String, of element: AXUIElement) -> Bool {
        var cfRange = CFRange(location: range.location, length: range.length)
        guard let axValue = AXValueCreate(.cfRange, &cfRange) else { return false }
        return AXUIElementSetAttributeValue(element, attribute as CFString, axValue) == .success
    }

    static func isSecure(_ element: AXUIElement) -> Bool {
        string(kAXSubroleAttribute, of: element) == (kAXSecureTextFieldSubrole as String)
    }

    private static func copyAttribute<T>(
        of element: AXUIElement,
        named attribute: String,
        type: T.Type
    ) -> T? {
        var value: CFTypeRef?
        guard
            AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success,
            let value = value as? T
        else { return nil }
        return value
    }

    private static func copyParameterizedAttribute<T>(
        of element: AXUIElement,
        named attribute: String,
        parameter: CFTypeRef,
        type: T.Type
    ) -> T? {
        var value: CFTypeRef?
        guard
            AXUIElementCopyParameterizedAttributeValue(
                element, attribute as CFString, parameter, &value
            ) == .success,
            let value = value as? T
        else { return nil }
        return value
    }
}
