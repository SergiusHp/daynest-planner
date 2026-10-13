import XCTest

/// Автоматичні перевірки основних сценаріїв і знімки екранів (зберігаються як вкладення результатів тестів).
final class MyauDenUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func launch(_ extra: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest", "-uitest-reset"] + extra
        app.launch()
        return app
    }

    private func shot(_ app: XCUIApplication, _ name: String) {
        let a = XCTAttachment(screenshot: app.screenshot())
        a.name = name
        a.lifetime = .keepAlways
        add(a)
    }

    private func dayTitle(_ app: XCUIApplication) -> String { app.staticTexts["dayTitle"].label }

    // Привітання → три кроки знайомства → планер; далі відкривається одразу планер.
    func testFirstLaunchFlow() throws {
        let app = launch([])
        XCTAssertTrue(app.buttons["startButton"].waitForExistence(timeout: 5))
        shot(app, "01-welcome")
        app.buttons["startButton"].tap()
        XCTAssertTrue(app.staticTexts["obProgress"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.buttons["obNext"].label, "Далі")
        sleep(1); shot(app, "02-onboarding-1")
        app.buttons["obNext"].tap()
        sleep(2); shot(app, "03-onboarding-2")
        app.swipeLeft()                                      // свайп по демонстрації — теж далі
        sleep(2); shot(app, "04-onboarding-3")
        XCTAssertEqual(app.buttons["obNext"].label, "Почати")
        app.buttons["obNext"].tap()
        XCTAssertTrue(app.staticTexts["dayTitle"].waitForExistence(timeout: 3))
        XCTAssertEqual(dayTitle(app), "Сьогоднішні справи")
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Ознайомитись з програмою")).firstMatch.waitForExistence(timeout: 3))
        shot(app, "05-day-first")
        app.terminate()
        let again = XCUIApplication()
        again.launchArguments = ["-uitest"]
        again.launch()
        XCTAssertTrue(again.staticTexts["dayTitle"].waitForExistence(timeout: 5))
        XCTAssertFalse(again.buttons["startButton"].exists)
    }

    // Свайп уліво, що починається НАД справою, відкриває наступну сторінку (і при довгому списку).
    func testSwipeLeftOverTaskOpensCalendar() throws {
        let app = launch(["-uitest-skip-intro", "-uitest-seed-many"])
        let row = app.buttons["task-t1"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        shot(app, "06-day-many")
        row.swipeLeft()
        XCTAssertTrue(app.staticTexts["calTitle"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["calTitle"].isHittable)
    }

    // Вертикальна прокрутка довгого списку не перемикає сторінку.
    func testVerticalScrollKeepsPage() throws {
        let app = launch(["-uitest-skip-intro", "-uitest-seed-many"])
        let first = app.buttons["task-t1"]
        XCTAssertTrue(first.waitForExistence(timeout: 5))
        let y0 = first.frame.minY
        app.collectionViews["taskList"].swipeUp()
        sleep(1)
        XCTAssertTrue(app.staticTexts["dayTitle"].isHittable)      // сторінка та сама
        XCTAssertTrue(!first.exists || first.frame.minY < y0 - 40)  // список прокрутився
    }

    // Свайп управо по справі закреслює її; ще раз — повертає.
    func testSwipeRightCompletesTask() throws {
        let app = launch(["-uitest-skip-intro", "-uitest-seed-sample"])
        let check = app.switches["check-c"]
        XCTAssertTrue(check.waitForExistence(timeout: 5))
        shot(app, "06b-day-sample")
        XCTAssertEqual(check.value as? String, "не виконано")
        // повільний свайп пальцем, як у житті: натиснути й провести вправо
        func swipeRight(_ id: String) {
            let row = app.buttons["task-\(id)"]
            let start = row.coordinate(withNormalizedOffset: CGVector(dx: 0.15, dy: 0.5))
            start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 200, dy: 0)), withVelocity: .slow, thenHoldForDuration: 0.05)
        }
        swipeRight("c")
        let done = NSPredicate(format: "value == %@", "виконано")
        expectation(for: done, evaluatedWith: app.switches["check-c"])
        waitForExpectations(timeout: 4)
        // надійність: ще дві справи поспіль
        swipeRight("a")
        expectation(for: done, evaluatedWith: app.switches["check-a"])
        waitForExpectations(timeout: 4)
        sleep(2)
        swipeRight("b")
        expectation(for: done, evaluatedWith: app.switches["check-b"])
        waitForExpectations(timeout: 4)
        sleep(1); shot(app, "07-day-scratched")
        XCTAssertEqual(dayTitle(app), "Сьогоднішні справи")      // сторінка не змінилася
        sleep(2)
        swipeRight("d")                                            // свайп по виконаній — повертає
        let undone = NSPredicate(format: "value == %@", "не виконано")
        expectation(for: undone, evaluatedWith: app.switches["check-d"])
        waitForExpectations(timeout: 4)
    }

    // Котик відкриває «Новий план»; план додається до списку.
    func testAddPlanViaCat() throws {
        let app = launch(["-uitest-skip-intro", "-uitest-seed-sample"])
        XCTAssertTrue(app.buttons["catButton"].waitForExistence(timeout: 5))
        app.buttons["catButton"].tap()
        let field = app.textViews["planText"].exists ? app.textViews["planText"] : app.textFields["planText"]
        XCTAssertTrue(field.waitForExistence(timeout: 3))
        sleep(1)
        field.tap()
        field.typeText("Полити квіти")
        shot(app, "08-new-plan")
        app.buttons["savePlan"].tap()
        let added = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Полити квіти")).firstMatch
        XCTAssertTrue(added.waitForExistence(timeout: 6))
        shot(app, "08b-added")
    }

    // Сонечко повертає на сьогодні після вибору іншого дня.
    func testSunReturnsToToday() throws {
        let app = launch(["-uitest-skip-intro", "-uitest-seed-sample"])
        XCTAssertTrue(app.buttons["sunButton"].waitForExistence(timeout: 5))
        // вибираємо будь-який інший день тижня
        let today = Calendar.current.component(.weekday, from: Date())
        let names = ["неділя", "понеділок", "вівторок", "середа", "четвер", "пʼятниця", "субота"]
        let other = names[(today % 7)]
        let chip = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", other + ",")).firstMatch
        XCTAssertTrue(chip.exists)
        chip.tap()
        XCTAssertNotEqual(dayTitle(app), "Сьогоднішні справи")
        app.buttons["sunButton"].tap()
        let back = NSPredicate(format: "label == %@", "Сьогоднішні справи")
        expectation(for: back, evaluatedWith: app.staticTexts["dayTitle"])
        waitForExpectations(timeout: 3)
    }

    // На сторінці календаря виконані плани приховані.
    func testCalendarHidesDone() throws {
        let app = launch(["-uitest-skip-intro", "-uitest-seed-sample", "-uitest-page", "1"])
        XCTAssertTrue(app.staticTexts["calTitle"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Купити продукти"].exists)
        XCTAssertFalse(app.staticTexts["Подзвонити мамі"].exists)
        shot(app, "09-calendar-month")
        app.buttons["Тиждень"].tap()
        sleep(1)
        XCTAssertFalse(app.staticTexts["Подзвонити мамі"].exists)
        shot(app, "10-calendar-week")
    }

    // Обертання лапки змінює час і не гортає сторінку; кнопка-нота вмикає/вимикає музику.
    func testFocusDialAndMusic() throws {
        let app = launch(["-uitest-skip-intro", "-uitest-seed-sample", "-uitest-page", "2"])
        let dial = app.descendants(matching: .any)["dial"]
        XCTAssertTrue(dial.waitForExistence(timeout: 5))
        XCTAssertEqual(dial.value as? String, "25 хв")
        shot(app, "11-focus")
        // лапка на 25 хв → тягнемо до позначки «15» (праворуч)
        let from = dial.coordinate(withNormalizedOffset: CGVector(dx: (150 + 122 * sin(150 * Double.pi / 180) + 26) / 352,
                                                                   dy: (150 - 122 * cos(150 * Double.pi / 180) - 2) / 304))
        let to = dial.coordinate(withNormalizedOffset: CGVector(dx: (272.0 + 26) / 352, dy: (150.0 - 2) / 304))
        from.press(forDuration: 0.1, thenDragTo: to)
        XCTAssertEqual(dial.value as? String, "15 хв")
        XCTAssertTrue(app.buttons["playButton"].isHittable)          // лишилися на сторінці фокусу

        let music = app.buttons["musicButton"]
        XCTAssertEqual(music.label, "Музика вимкнена. Увімкнути")
        music.tap()
        XCTAssertEqual(music.label, "Музика грає. Вимкнути")
        music.tap()
        XCTAssertEqual(music.label, "Музика вимкнена. Увімкнути")

        app.buttons["playButton"].tap()
        sleep(2)
        XCTAssertEqual(app.buttons["playButton"].label, "Пауза")
        XCTAssertEqual(music.label, "Музика грає. Вимкнути")          // старт таймера вмикає музику
        shot(app, "12-focus-running")
        app.buttons["playButton"].tap()
        XCTAssertEqual(music.label, "Музика вимкнена. Увімкнути")     // пауза — музика зупиняється
        app.buttons["resetButton"].tap()
        XCTAssertEqual(app.buttons["playButton"].label, "Почати")
    }

    // Зменшений рух: онбординг показує статичні кадри.
    func testReducedMotionOnboarding() throws {
        let app = launch(["-uitest-reduce-motion"])
        XCTAssertTrue(app.buttons["startButton"].waitForExistence(timeout: 5))
        app.buttons["startButton"].tap()
        sleep(1); shot(app, "13-rm-1")
        app.buttons["obNext"].tap(); sleep(1); shot(app, "14-rm-2")
        app.buttons["obNext"].tap(); sleep(1); shot(app, "15-rm-3")
    }

    // Знімки основних екранів (запускається й на малому iPhone SE).
    func testScreensOverview() throws {
        let app = launch(["-uitest-skip-intro", "-uitest-seed-sample"])
        XCTAssertTrue(app.staticTexts["dayTitle"].waitForExistence(timeout: 5))
        shot(app, "20-day")
        app.swipeLeft(); sleep(1); shot(app, "21-calendar")
        app.swipeLeft(); sleep(1); shot(app, "22-focus")
        let onboarding = launch([])
        XCTAssertTrue(onboarding.buttons["startButton"].waitForExistence(timeout: 5))
        shot(onboarding, "23-welcome")
        onboarding.buttons["startButton"].tap(); sleep(2); shot(onboarding, "24-onboarding")
        onboarding.buttons["obNext"].tap(); sleep(2); shot(onboarding, "25-onboarding-2")
    }
}
