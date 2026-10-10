import QtQuick
import calamares.slideshow 1.0

Presentation {
    id: presentation
    function nextSlide() { presentation.goToNextSlide() }
    Timer { interval: 9000; running: presentation.activatedInCalamares; repeat: true; onTriggered: nextSlide() }
    Slide {
        Image { anchors.fill: parent; source: "slide1.jpg"; fillMode: Image.PreserveAspectCrop }
        Rectangle { anchors.fill: parent; gradient: Gradient { GradientStop { position: 0.35; color: "transparent" } GradientStop { position: 1.0; color: "#d80a0908" } } }
        Item {   // a ruled box, the label set into a gap in the top rule
            x: 44; width: parent.width - 88; height: 150; anchors.bottom: parent.bottom; anchors.bottomMargin: 40
            Rectangle { x: 0; y: 8; width: 1; height: parent.height - 8; color: "#72c9a35a" }
            Rectangle { x: parent.width - 1; y: 8; width: 1; height: parent.height - 8; color: "#72c9a35a" }
            Rectangle { y: parent.height - 1; width: parent.width; height: 1; color: "#72c9a35a" }
            Rectangle { y: 8; width: 10; height: 1; color: "#72c9a35a" }
            Rectangle { x: lb1.x + lb1.width + 8; y: 8; width: parent.width - x; height: 1; color: "#72c9a35a" }
            Text { id: lb1; x: 18; y: 1; text: "01   TENKA"; color: "#c9a35a"; font.family: "Marcellus"; font.pixelSize: 11; font.letterSpacing: 4 }
            Text { x: 22; y: 34; width: parent.width - 44; text: "Tenka"; color: "#efe6d6"; font.family: "Marcellus"; font.pixelSize: 30 }
            Text { x: 22; y: 80; width: parent.width - 44; wrapMode: Text.WordWrap; text: "A desktop forged with intent: every edge, every motion, every colour drawn from sumi ink and vermilion."; color: "#b8ab96"; font.family: "Marcellus"; font.pixelSize: 15; lineHeight: 1.15 }
            Text { anchors.right: parent.right; anchors.rightMargin: 18; y: 1; text: "01 / 04"; color: "#7fefe6d6"; font.family: "Marcellus"; font.pixelSize: 11; font.letterSpacing: 3 }
        }
    }
    Slide {
        Image { anchors.fill: parent; source: "slide2.jpg"; fillMode: Image.PreserveAspectCrop }
        Rectangle { anchors.fill: parent; gradient: Gradient { GradientStop { position: 0.35; color: "transparent" } GradientStop { position: 1.0; color: "#d80a0908" } } }
        Item {   // a ruled box, the label set into a gap in the top rule
            x: 44; width: parent.width - 88; height: 150; anchors.bottom: parent.bottom; anchors.bottomMargin: 40
            Rectangle { x: 0; y: 8; width: 1; height: parent.height - 8; color: "#72c9a35a" }
            Rectangle { x: parent.width - 1; y: 8; width: 1; height: parent.height - 8; color: "#72c9a35a" }
            Rectangle { y: parent.height - 1; width: parent.width; height: 1; color: "#72c9a35a" }
            Rectangle { y: 8; width: 10; height: 1; color: "#72c9a35a" }
            Rectangle { x: lb2.x + lb2.width + 8; y: 8; width: parent.width - x; height: 1; color: "#72c9a35a" }
            Text { id: lb2; x: 18; y: 1; text: "02   TWO PATHS"; color: "#c9a35a"; font.family: "Marcellus"; font.pixelSize: 11; font.letterSpacing: 4 }
            Text { x: 22; y: 34; width: parent.width - 44; text: "Two paths"; color: "#efe6d6"; font.family: "Marcellus"; font.pixelSize: 30 }
            Text { x: 22; y: 80; width: parent.width - 44; wrapMode: Text.WordWrap; text: "Switch to Tianxia at any time with Super + T. The desk, the boot and the login all follow."; color: "#b8ab96"; font.family: "Marcellus"; font.pixelSize: 15; lineHeight: 1.15 }
            Text { anchors.right: parent.right; anchors.rightMargin: 18; y: 1; text: "02 / 04"; color: "#7fefe6d6"; font.family: "Marcellus"; font.pixelSize: 11; font.letterSpacing: 3 }
        }
    }
    Slide {
        Image { anchors.fill: parent; source: "slide3.jpg"; fillMode: Image.PreserveAspectCrop }
        Rectangle { anchors.fill: parent; gradient: Gradient { GradientStop { position: 0.35; color: "transparent" } GradientStop { position: 1.0; color: "#d80a0908" } } }
        Item {   // a ruled box, the label set into a gap in the top rule
            x: 44; width: parent.width - 88; height: 150; anchors.bottom: parent.bottom; anchors.bottomMargin: 40
            Rectangle { x: 0; y: 8; width: 1; height: parent.height - 8; color: "#72c9a35a" }
            Rectangle { x: parent.width - 1; y: 8; width: 1; height: parent.height - 8; color: "#72c9a35a" }
            Rectangle { y: parent.height - 1; width: parent.width; height: 1; color: "#72c9a35a" }
            Rectangle { y: 8; width: 10; height: 1; color: "#72c9a35a" }
            Rectangle { x: lb3.x + lb3.width + 8; y: 8; width: parent.width - x; height: 1; color: "#72c9a35a" }
            Text { id: lb3; x: 18; y: 1; text: "03   THE WAY OF THE KEYS"; color: "#c9a35a"; font.family: "Marcellus"; font.pixelSize: 11; font.letterSpacing: 4 }
            Text { x: 22; y: 34; width: parent.width - 44; text: "The way of the keys"; color: "#efe6d6"; font.family: "Marcellus"; font.pixelSize: 30 }
            Text { x: 22; y: 80; width: parent.width - 44; wrapMode: Text.WordWrap; text: "Super + Space to seek, Super + Return for the terminal, Super + Escape to rest or retreat."; color: "#b8ab96"; font.family: "Marcellus"; font.pixelSize: 15; lineHeight: 1.15 }
            Text { anchors.right: parent.right; anchors.rightMargin: 18; y: 1; text: "03 / 04"; color: "#7fefe6d6"; font.family: "Marcellus"; font.pixelSize: 11; font.letterSpacing: 3 }
        }
    }
    Slide {
        Image { anchors.fill: parent; source: "slide4.jpg"; fillMode: Image.PreserveAspectCrop }
        Rectangle { anchors.fill: parent; gradient: Gradient { GradientStop { position: 0.35; color: "transparent" } GradientStop { position: 1.0; color: "#d80a0908" } } }
        Item {   // a ruled box, the label set into a gap in the top rule
            x: 44; width: parent.width - 88; height: 150; anchors.bottom: parent.bottom; anchors.bottomMargin: 40
            Rectangle { x: 0; y: 8; width: 1; height: parent.height - 8; color: "#72c9a35a" }
            Rectangle { x: parent.width - 1; y: 8; width: 1; height: parent.height - 8; color: "#72c9a35a" }
            Rectangle { y: parent.height - 1; width: parent.width; height: 1; color: "#72c9a35a" }
            Rectangle { y: 8; width: 10; height: 1; color: "#72c9a35a" }
            Rectangle { x: lb4.x + lb4.width + 8; y: 8; width: parent.width - x; height: 1; color: "#72c9a35a" }
            Text { id: lb4; x: 18; y: 1; text: "04   NEARLY THERE"; color: "#c9a35a"; font.family: "Marcellus"; font.pixelSize: 11; font.letterSpacing: 4 }
            Text { x: 22; y: 34; width: parent.width - 44; text: "Nearly there"; color: "#efe6d6"; font.family: "Marcellus"; font.pixelSize: 30 }
            Text { x: 22; y: 80; width: parent.width - 44; wrapMode: Text.WordWrap; text: "Your system is being set down on the disk. Breathe."; color: "#b8ab96"; font.family: "Marcellus"; font.pixelSize: 15; lineHeight: 1.15 }
            Text { anchors.right: parent.right; anchors.rightMargin: 18; y: 1; text: "04 / 04"; color: "#7fefe6d6"; font.family: "Marcellus"; font.pixelSize: 11; font.letterSpacing: 3 }
        }
    }
    function onActivate() { }
    function onLeave() { }
}
