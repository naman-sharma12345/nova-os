import QtQuick
import calamares.slideshow 1.0

Presentation {
    id: presentation
    function nextSlide() { presentation.goToNextSlide() }
    Timer { interval: 9000; running: presentation.activatedInCalamares; repeat: true; onTriggered: nextSlide() }
    Slide {
        Image { anchors.fill: parent; source: "slide1.jpg"; fillMode: Image.PreserveAspectCrop }
        Rectangle { anchors.fill: parent; gradient: Gradient { GradientStop { position: 0.35; color: "transparent" } GradientStop { position: 1.0; color: "#d807100e" } } }
        Item {   // a ruled box, the label set into a gap in the top rule
            x: 44; width: parent.width - 88; height: 150; anchors.bottom: parent.bottom; anchors.bottomMargin: 40
            Rectangle { x: 0; y: 8; width: 1; height: parent.height - 8; color: "#72e2bd6b" }
            Rectangle { x: parent.width - 1; y: 8; width: 1; height: parent.height - 8; color: "#72e2bd6b" }
            Rectangle { y: parent.height - 1; width: parent.width; height: 1; color: "#72e2bd6b" }
            Rectangle { y: 8; width: 10; height: 1; color: "#72e2bd6b" }
            Rectangle { x: lb1.x + lb1.width + 8; y: 8; width: parent.width - x; height: 1; color: "#72e2bd6b" }
            Text { id: lb1; x: 18; y: 1; text: "01   TIANXIA"; color: "#e2bd6b"; font.family: "Marcellus"; font.pixelSize: 11; font.letterSpacing: 4 }
            Text { x: 22; y: 34; width: parent.width - 44; text: "Tianxia"; color: "#eef3ec"; font.family: "Marcellus"; font.pixelSize: 30 }
            Text { x: 22; y: 80; width: parent.width - 44; wrapMode: Text.WordWrap; text: "All under heaven: jade mist, floating peaks and drifting qi, gathered into one desktop."; color: "#a9bdb4"; font.family: "Marcellus"; font.pixelSize: 15; lineHeight: 1.15 }
            Text { anchors.right: parent.right; anchors.rightMargin: 18; y: 1; text: "01 / 04"; color: "#7feef3ec"; font.family: "Marcellus"; font.pixelSize: 11; font.letterSpacing: 3 }
        }
    }
    Slide {
        Image { anchors.fill: parent; source: "slide2.jpg"; fillMode: Image.PreserveAspectCrop }
        Rectangle { anchors.fill: parent; gradient: Gradient { GradientStop { position: 0.35; color: "transparent" } GradientStop { position: 1.0; color: "#d807100e" } } }
        Item {   // a ruled box, the label set into a gap in the top rule
            x: 44; width: parent.width - 88; height: 150; anchors.bottom: parent.bottom; anchors.bottomMargin: 40
            Rectangle { x: 0; y: 8; width: 1; height: parent.height - 8; color: "#72e2bd6b" }
            Rectangle { x: parent.width - 1; y: 8; width: 1; height: parent.height - 8; color: "#72e2bd6b" }
            Rectangle { y: parent.height - 1; width: parent.width; height: 1; color: "#72e2bd6b" }
            Rectangle { y: 8; width: 10; height: 1; color: "#72e2bd6b" }
            Rectangle { x: lb2.x + lb2.width + 8; y: 8; width: parent.width - x; height: 1; color: "#72e2bd6b" }
            Text { id: lb2; x: 18; y: 1; text: "02   TWO PATHS"; color: "#e2bd6b"; font.family: "Marcellus"; font.pixelSize: 11; font.letterSpacing: 4 }
            Text { x: 22; y: 34; width: parent.width - 44; text: "Two paths"; color: "#eef3ec"; font.family: "Marcellus"; font.pixelSize: 30 }
            Text { x: 22; y: 80; width: parent.width - 44; wrapMode: Text.WordWrap; text: "Return to Tenka at any time with Super + T. The desk, the boot and the login all follow."; color: "#a9bdb4"; font.family: "Marcellus"; font.pixelSize: 15; lineHeight: 1.15 }
            Text { anchors.right: parent.right; anchors.rightMargin: 18; y: 1; text: "02 / 04"; color: "#7feef3ec"; font.family: "Marcellus"; font.pixelSize: 11; font.letterSpacing: 3 }
        }
    }
    Slide {
        Image { anchors.fill: parent; source: "slide3.jpg"; fillMode: Image.PreserveAspectCrop }
        Rectangle { anchors.fill: parent; gradient: Gradient { GradientStop { position: 0.35; color: "transparent" } GradientStop { position: 1.0; color: "#d807100e" } } }
        Item {   // a ruled box, the label set into a gap in the top rule
            x: 44; width: parent.width - 88; height: 150; anchors.bottom: parent.bottom; anchors.bottomMargin: 40
            Rectangle { x: 0; y: 8; width: 1; height: parent.height - 8; color: "#72e2bd6b" }
            Rectangle { x: parent.width - 1; y: 8; width: 1; height: parent.height - 8; color: "#72e2bd6b" }
            Rectangle { y: parent.height - 1; width: parent.width; height: 1; color: "#72e2bd6b" }
            Rectangle { y: 8; width: 10; height: 1; color: "#72e2bd6b" }
            Rectangle { x: lb3.x + lb3.width + 8; y: 8; width: parent.width - x; height: 1; color: "#72e2bd6b" }
            Text { id: lb3; x: 18; y: 1; text: "03   THE HEAVENLY KEYS"; color: "#e2bd6b"; font.family: "Marcellus"; font.pixelSize: 11; font.letterSpacing: 4 }
            Text { x: 22; y: 34; width: parent.width - 44; text: "The heavenly keys"; color: "#eef3ec"; font.family: "Marcellus"; font.pixelSize: 30 }
            Text { x: 22; y: 80; width: parent.width - 44; wrapMode: Text.WordWrap; text: "Super + Space to divine, Super + Return for the terminal, Super + Escape to ascend."; color: "#a9bdb4"; font.family: "Marcellus"; font.pixelSize: 15; lineHeight: 1.15 }
            Text { anchors.right: parent.right; anchors.rightMargin: 18; y: 1; text: "03 / 04"; color: "#7feef3ec"; font.family: "Marcellus"; font.pixelSize: 11; font.letterSpacing: 3 }
        }
    }
    Slide {
        Image { anchors.fill: parent; source: "slide4.jpg"; fillMode: Image.PreserveAspectCrop }
        Rectangle { anchors.fill: parent; gradient: Gradient { GradientStop { position: 0.35; color: "transparent" } GradientStop { position: 1.0; color: "#d807100e" } } }
        Item {   // a ruled box, the label set into a gap in the top rule
            x: 44; width: parent.width - 88; height: 150; anchors.bottom: parent.bottom; anchors.bottomMargin: 40
            Rectangle { x: 0; y: 8; width: 1; height: parent.height - 8; color: "#72e2bd6b" }
            Rectangle { x: parent.width - 1; y: 8; width: 1; height: parent.height - 8; color: "#72e2bd6b" }
            Rectangle { y: parent.height - 1; width: parent.width; height: 1; color: "#72e2bd6b" }
            Rectangle { y: 8; width: 10; height: 1; color: "#72e2bd6b" }
            Rectangle { x: lb4.x + lb4.width + 8; y: 8; width: parent.width - x; height: 1; color: "#72e2bd6b" }
            Text { id: lb4; x: 18; y: 1; text: "04   ASCENSION IS NEAR"; color: "#e2bd6b"; font.family: "Marcellus"; font.pixelSize: 11; font.letterSpacing: 4 }
            Text { x: 22; y: 34; width: parent.width - 44; text: "Ascension is near"; color: "#eef3ec"; font.family: "Marcellus"; font.pixelSize: 30 }
            Text { x: 22; y: 80; width: parent.width - 44; wrapMode: Text.WordWrap; text: "Your cave abode is being carved into the disk. Be still."; color: "#a9bdb4"; font.family: "Marcellus"; font.pixelSize: 15; lineHeight: 1.15 }
            Text { anchors.right: parent.right; anchors.rightMargin: 18; y: 1; text: "04 / 04"; color: "#7feef3ec"; font.family: "Marcellus"; font.pixelSize: 11; font.letterSpacing: 3 }
        }
    }
    function onActivate() { }
    function onLeave() { }
}
