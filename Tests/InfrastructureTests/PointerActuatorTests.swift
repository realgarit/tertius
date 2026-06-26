import Testing
import CoreGraphics
@testable import Infrastructure
import Domain

@Suite("MiddleButtonEventFactory")
struct MiddleButtonEventFactoryTests {
    @Test("builds an otherMouse event at the given point with button number 2 (center)")
    func buildsMiddleEvent() {
        let e = MiddleButtonEventFactory.make(type: .otherMouseDown, at: CGPoint(x: 10, y: 20), source: nil)
        #expect(e != nil)
        #expect(e?.type == .otherMouseDown)
        #expect(e?.location == CGPoint(x: 10, y: 20))
        #expect(e?.getIntegerValueField(.mouseEventButtonNumber) == 2)
    }

    @Test("carries the supplied per-event delta in the mouse delta fields")
    func carriesDelta() {
        let e = MiddleButtonEventFactory.make(
            type: .otherMouseDragged,
            at: CGPoint(x: 10, y: 20),
            delta: CGVector(dx: 7, dy: -4),
            source: nil
        )
        #expect(e?.getIntegerValueField(.mouseEventDeltaX) == 7)
        #expect(e?.getIntegerValueField(.mouseEventDeltaY) == -4)
    }

    @Test("defaults to zero delta when none is supplied")
    func defaultsToZeroDelta() {
        let e = MiddleButtonEventFactory.make(type: .otherMouseDown, at: .zero, source: nil)
        #expect(e?.getIntegerValueField(.mouseEventDeltaX) == 0)
        #expect(e?.getIntegerValueField(.mouseEventDeltaY) == 0)
    }
}

@Suite("CGEventPointerActuator")
struct CGEventPointerActuatorTests {
    private func makeActuator(cursor: CGPoint) -> (CGEventPointerActuator, () -> [CGEvent]) {
        var posted: [CGEvent] = []
        let actuator = CGEventPointerActuator(
            cursorLocation: { cursor },
            post: { posted.append($0) }
        )
        return (actuator, { posted })
    }

    @Test("middleDown anchors at the current cursor and posts an otherMouseDown there")
    func downAnchorsAtCursor() {
        let (actuator, posted) = makeActuator(cursor: CGPoint(x: 100, y: 200))
        actuator.perform(.middleDown)

        #expect(posted().count == 1)
        #expect(posted().first?.type == .otherMouseDown)
        #expect(posted().first?.location == CGPoint(x: 100, y: 200))
    }

    @Test("middleDrag accumulates deltas from the anchor and posts otherMouseDragged")
    func dragAccumulates() {
        let (actuator, posted) = makeActuator(cursor: CGPoint(x: 100, y: 200))
        actuator.perform(.middleDown)
        actuator.perform(.middleDrag(dx: 5, dy: -3))
        actuator.perform(.middleDrag(dx: 2, dy: 2))

        #expect(posted().count == 3)
        #expect(posted()[1].type == .otherMouseDragged)
        #expect(posted()[1].location == CGPoint(x: 105, y: 197))
        #expect(posted()[2].location == CGPoint(x: 107, y: 199))
    }

    @Test("middleUp posts otherMouseUp at the current accumulated position")
    func upPostsRelease() {
        let (actuator, posted) = makeActuator(cursor: CGPoint(x: 100, y: 200))
        actuator.perform(.middleDown)
        actuator.perform(.middleDrag(dx: 10, dy: 10))
        actuator.perform(.middleUp)

        #expect(posted().last?.type == .otherMouseUp)
        #expect(posted().last?.location == CGPoint(x: 110, y: 210))
    }

    @Test("middleDrag carries the finger delta in the event's mouse delta fields")
    func dragCarriesDelta() {
        let (actuator, posted) = makeActuator(cursor: CGPoint(x: 100, y: 200))
        actuator.perform(.middleDown)
        actuator.perform(.middleDrag(dx: 5, dy: -3))

        #expect(posted()[1].getIntegerValueField(.mouseEventDeltaX) == 5)
        #expect(posted()[1].getIntegerValueField(.mouseEventDeltaY) == -3)
    }

    @Test("middleDown carries no delta — a real middle-press has no motion")
    func downCarriesNoDelta() {
        let (actuator, posted) = makeActuator(cursor: CGPoint(x: 100, y: 200))
        actuator.perform(.middleDown)

        #expect(posted()[0].getIntegerValueField(.mouseEventDeltaX) == 0)
        #expect(posted()[0].getIntegerValueField(.mouseEventDeltaY) == 0)
    }

    @Test("sub-pixel drags accumulate so slow motion is never lost to integer rounding")
    func subPixelDragsAccumulate() {
        let (actuator, posted) = makeActuator(cursor: .zero)
        actuator.perform(.middleDown)
        // Five 0.4px steps = 2.0px total. The integer event deltas must sum to
        // 2, not round each 0.4 down to 0 and lose the motion entirely.
        for _ in 0..<5 { actuator.perform(.middleDrag(dx: 0.4, dy: 0)) }

        let totalDx = posted().dropFirst().reduce(Int64(0)) {
            $0 + $1.getIntegerValueField(.mouseEventDeltaX)
        }
        #expect(totalDx == 2)
    }

    @Test(".none posts nothing")
    func noneIsNoOp() {
        let (actuator, posted) = makeActuator(cursor: .zero)
        actuator.perform(.none)
        #expect(posted().isEmpty)
    }
}
