import QtQuick
import Quickshell
import Quickshell.Io

Item {
    Process {
        id: proc
        command: ["echo", "hello"]
        running: true
        onStdout: console.log(data)
    }
}
