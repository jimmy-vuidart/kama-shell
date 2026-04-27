pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    readonly property var weekdayNames: [
        "dimanche",
        "lundi",
        "mardi",
        "mercredi",
        "jeudi",
        "vendredi",
        "samedi"
    ]
    readonly property var monthNames: [
        "janvier",
        "février",
        "mars",
        "avril",
        "mai",
        "juin",
        "juillet",
        "août",
        "septembre",
        "octobre",
        "novembre",
        "décembre"
    ]
    readonly property string formattedDateTime: {
        const currentDate = clock.date
        const weekday = root.weekdayNames[currentDate.getDay()] || ""
        const day = currentDate.getDate()
        const month = root.monthNames[currentDate.getMonth()] || ""
        const hours = root.pad2(currentDate.getHours())
        const minutes = root.pad2(currentDate.getMinutes())

        return `${weekday} ${day} ${month} - ${hours}:${minutes}`
    }

    function pad2(value) {
        return value < 10 ? `0${value}` : `${value}`
    }

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }
}
