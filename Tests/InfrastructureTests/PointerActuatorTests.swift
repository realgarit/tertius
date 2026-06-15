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

    @Test(".none posts nothing")
    func noneIsNoOp() {
        let (actuator, posted) = makeActuator(cursor: .zero)
        actuator.perform(.none)
        #expect(posted().isEmpty)
    }
}
