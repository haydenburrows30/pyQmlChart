import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import QtCharts

Window {
    visible: true
    width: 900
    height: 700
    title: "Qt Charts in Qt Quick - Interactive"

    property bool showFFT: false
    property bool logFFT: false
    property bool showPhase: false

    function updatePlot() {
        chartDataProvider.plotType = plotTypeCombo.currentValue

        chartDataProvider.generate_data()
        chartDataProvider.compute_fft()

        switch (true) {
            // CASE 1: FFT Phase Spectrum + Log Frequency
            case showFFT && showPhase && logFFT: {
                seriesHelper.fillSeriesOptimized(
                    lineSeries,
                    chartDataProvider.logPhaseX,
                    chartDataProvider.logPhaseY, 
                    chartDataProvider.pointCount
                )
                chartView.title = chartDataProvider.phaseTitle + " (Log Freq)"
                axisX.titleText = "log10(Frequency) [Hz]"
                axisX.min = chartDataProvider.logPhaseX.length > 0 ? Math.min.apply(null, chartDataProvider.logPhaseX) : 0
                axisX.max = chartDataProvider.logPhaseX.length > 0 ? Math.max.apply(null, chartDataProvider.logPhaseX) : 1
                axisY.titleText = "Phase (radians)"
                axisY.min = -Math.PI
                axisY.max = Math.PI
                peakLabel.visible = false
                break
            }
            
            // CASE 2: FFT Phase Spectrum + Linear Frequency
            case showFFT && showPhase: {
                seriesHelper.fillSeriesOptimized(
                    lineSeries,
                    chartDataProvider.phaseX,
                    chartDataProvider.phaseY,
                    chartDataProvider.pointCount
                )
                chartView.title = chartDataProvider.phaseTitle
                axisX.titleText = "Frequency (Hz)"
                axisX.min = 0
                axisX.max = chartDataProvider.phaseX.length > 0 ? chartDataProvider.phaseX[chartDataProvider.phaseX.length-1] : 1
                axisY.titleText = "Phase (radians)"
                axisY.min = -Math.PI
                axisY.max = Math.PI
                peakLabel.visible = false
                break
            }
            
            // CASE 3: FFT Magnitude Spectrum + Log Frequency
            case showFFT && logFFT: {
                seriesHelper.fillSeriesOptimized(
                    lineSeries,
                    chartDataProvider.logFFTX,
                    chartDataProvider.logFFTY,
                    chartDataProvider.pointCount
                )
                chartView.title = chartDataProvider.fftTitle + " (Log Freq)"
                axisX.titleText = "log10(Frequency) [Hz]"
                axisX.min = chartDataProvider.logFFTX.length > 0 ? Math.min.apply(null, chartDataProvider.logFFTX) : 0
                axisX.max = chartDataProvider.logFFTX.length > 0 ? Math.max.apply(null, chartDataProvider.logFFTX) : 1
                axisY.titleText = "Magnitude"
                axisY.min = 0
                axisY.max = chartDataProvider.logFFTY.length > 0 ? Math.max.apply(null, chartDataProvider.logFFTY) : 1
                peakLabel.visible = true
                peakLabel.text = "Peak Frequency: " + chartDataProvider.peakFreq.toFixed(3) + " Hz"
                break
            }
            
            // CASE 4: FFT Magnitude Spectrum + Linear Frequency
            case showFFT: {
                seriesHelper.fillSeriesOptimized(
                    lineSeries,
                    chartDataProvider.fftX,
                    chartDataProvider.fftY,
                    chartDataProvider.pointCount
                )
                chartView.title = chartDataProvider.fftTitle
                axisX.titleText = "Frequency (Hz)"
                axisX.min = 0
                axisX.max = chartDataProvider.fftX.length > 0 ? chartDataProvider.fftX[chartDataProvider.fftX.length-1] : 1
                axisY.titleText = "Magnitude"
                axisY.min = 0
                axisY.max = chartDataProvider.fftY.length > 0 ? Math.max.apply(null, chartDataProvider.fftY) : 1
                peakLabel.visible = true
                peakLabel.text = "Peak Frequency: " + chartDataProvider.peakFreq.toFixed(3) + " Hz"
                break
            }
            
            // CASE 5: Time domain waveform (default case)
            default: {
                seriesHelper.fillSeriesOptimized(
                    lineSeries, 
                    chartDataProvider.xValues, 
                    chartDataProvider.yValues,
                    chartDataProvider.pointCount
                );
                chartView.title = chartDataProvider.title
                axisX.titleText = "X Axis"
                axisY.titleText = "Y Axis"
                axisX.min = 0
                axisX.max = 10
                axisY.min = -3
                axisY.max = 3
                peakLabel.visible = false
                break
            }
        }
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10
        
        // Title
        Label {
            text: "Interactive Qt Charts Integration"
            font.pixelSize: 24
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }
        
        // Chart area
        ChartView {
            id: chartView
            Layout.fillWidth: true
            Layout.fillHeight: true
            antialiasing: true
            title: "Chart"

            property real zoomFactor: 1.2

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                drag.target: null
                cursorShape: Qt.OpenHandCursor

                property bool panning: false
                property real lastX: 0
                property real lastY: 0

                onPressed: function(mouse) {
                    if (mouse.button === Qt.LeftButton) {
                        panning = true
                        lastX = mouse.x
                        lastY = mouse.y
                        cursorShape = Qt.ClosedHandCursor
                    }
                }
                onReleased: function(mouse) {
                    panning = false
                    cursorShape = Qt.OpenHandCursor
                }
                onPositionChanged: function(mouse) {
                    if (panning) {
                        var dx = mouse.x - lastX
                        var dy = mouse.y - lastY

                        // Calculate axis ranges
                        var xRange = axisX.max - axisX.min
                        var yRange = axisY.max - axisY.min

                        // Calculate how much to shift per pixel
                        var xShift = -dx / chartView.plotArea.width * xRange
                        var yShift = dy / chartView.plotArea.height * yRange

                        axisX.min += xShift
                        axisX.max += xShift
                        axisY.min += yShift
                        axisY.max += yShift

                        lastX = mouse.x
                        lastY = mouse.y
                    }
                }
                onWheel: function(wheel) {
                    var factor = wheel.angleDelta.y > 0 ? chartView.zoomFactor : 1 / chartView.zoomFactor
                    chartView.zoom(factor)
                }
            }

            // Reset zoom button overlay
            Button {
                id: resetZoomBtn
                text: "Reset Zoom"
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 10
                z: 100
                visible: true
                onClicked: chartView.zoomReset()
            }

            ValueAxis {
                id: axisX
                min: 0
                max: 10
                tickCount: 6
                titleText: "X Axis"
            }
            
            ValueAxis {
                id: axisY
                min: -3
                max: 3
                tickCount: 7
                titleText: "Y Axis"
            }
            
            LineSeries {
                id: lineSeries
                name: "Function"
                axisX: axisX
                axisY: axisY
                // Line appearance
                width: 2
                color: plotTypeCombo.currentValue === "sine" ? "blue" :
                       plotTypeCombo.currentValue === "cosine" ? "red" : "green"
            }

            // Peak marker for FFT
            Rectangle {
                id: peakMarker
                visible: showFFT && chartDataProvider.peakFreq > 0
                color: "#ff00ff80"
                width: 2
                height: chartView.plotArea.height
                y: chartView.plotArea.y
                x: {
                    // Calculate x position for peak frequency
                    if (!showFFT || chartDataProvider.peakFreq <= 0)
                        return -100
                    var freq = chartDataProvider.peakFreq
                    if (logFFT && freq > 0) {
                        var minLog = axisX.min
                        var maxLog = axisX.max
                        var logFreq = Math.log10(freq)
                        var rel = (logFreq - minLog) / (maxLog - minLog)
                        return chartView.plotArea.x + rel * chartView.plotArea.width
                    } else {
                        var minX = axisX.min
                        var maxX = axisX.max
                        var rel = (freq - minX) / (maxX - minX)
                        return chartView.plotArea.x + rel * chartView.plotArea.width
                    }
                }
                z: 10
            }
        }
        
        // Plot type control
        RowLayout {
            Layout.fillWidth: true
            
            Label {
                text: "Plot Type:"
                Layout.preferredWidth: 100
            }
            
            ComboBox {
                id: plotTypeCombo
                Layout.fillWidth: true
                model: [
                    { text: "Sine Wave", value: "sine" },
                    { text: "Cosine Wave", value: "cosine" },
                    { text: "Parabola", value: "parabola" }
                ]
                textRole: "text"
                valueRole: "value"
                currentIndex: 0
                onActivated: updatePlot()
                onCurrentTextChanged: chartDataProvider.plotType = currentText
            }
        }
        
        // Amplitude control
        RowLayout {
            Layout.fillWidth: true
            
            Label {
                text: "Amplitude:"
                Layout.preferredWidth: 100
            }
            
            Slider {
                id: amplitudeSlider
                Layout.fillWidth: true
                from: 0.1
                to: 3.0
                value: chartDataProvider.amplitudeLevel
                stepSize: 0.1
                onValueChanged: {
                    amplitudeValue.text = value.toFixed(1)
                    chartDataProvider.amplitudeLevel = value
                }
                onMoved: updatePlot()
            }
            
            Label {
                id: amplitudeValue
                text: amplitudeSlider.value.toFixed(1)
                Layout.preferredWidth: 50
                horizontalAlignment: Text.AlignRight
            }
        }
        
        // Frequency control (except for parabola)
        RowLayout {
            Layout.fillWidth: true
            visible: plotTypeCombo.currentValue !== "parabola"
            
            Label {
                text: "Frequency:"
                Layout.preferredWidth: 100
            }
            
            Slider {
                id: frequencySlider
                Layout.fillWidth: true
                from: 0.1
                to: 3.0
                value: chartDataProvider.frequencyLevel
                stepSize: 0.1
                onValueChanged: {
                    frequencyValue.text = value.toFixed(1)
                    chartDataProvider.frequencyLevel = value
                }
                onMoved: updatePlot()
            }
            
            Label {
                id: frequencyValue
                text: frequencySlider.value.toFixed(1)
                Layout.preferredWidth: 50
                horizontalAlignment: Text.AlignRight
            }
        }
        
        // Phase/Offset control
        RowLayout {
            Layout.fillWidth: true
            
            Label {
                text: plotTypeCombo.currentValue === "parabola" ? "Offset:" : "Phase:"
                Layout.preferredWidth: 100
            }
            
            Slider {
                id: phaseSlider
                Layout.fillWidth: true
                from: 0.0
                to: 6.28
                value: chartDataProvider.phaseLevel
                stepSize: 0.1
                onValueChanged: {
                    phaseValue.text = value.toFixed(1)
                    chartDataProvider.phaseLevel = value
                }
                onMoved: updatePlot()
            }
            
            Label {
                id: phaseValue
                text: phaseSlider.value.toFixed(1)
                Layout.preferredWidth: 50
                horizontalAlignment: Text.AlignRight
            }
        }
        
        // Windowing and noise controls
        RowLayout {
            Layout.fillWidth: true

            Label {
                text: "Window:"
                Layout.preferredWidth: 100
            }
            ComboBox {
                id: windowCombo
                Layout.preferredWidth: 120
                model: [
                    { text: "None", value: "None" },
                    { text: "Hann", value: "Hann" },
                    { text: "Hamming", value: "Hamming" },
                    { text: "Blackman", value: "Blackman" }
                ]
                textRole: "text"
                valueRole: "value"
                currentIndex: 0
                onActivated: updatePlot()
                onCurrentTextChanged: chartDataProvider.windowType = currentText
            }

            Label {
                text: "Noise:"
                Layout.preferredWidth: 60
            }
            Slider {
                id: noiseSlider
                Layout.preferredWidth: 100
                from: 0.0
                to: 1.0
                value: chartDataProvider.noiseLevel
                stepSize: 0.05
                onValueChanged: {
                    noiseValue.text = value.toFixed(2)
                    chartDataProvider.noiseLevel = value
                }
                onMoved: updatePlot()
            }
            Label {
                id: noiseValue
                text: noiseSlider.value.toFixed(2)
                Layout.preferredWidth: 40
            }
            Label {
                text: "Points:"
                Layout.preferredWidth: 60
            }
            Slider {
                id: pointsSlider
                Layout.preferredWidth: 100
                from: 100
                to: 1000
                value: chartDataProvider.pointCount
                stepSize: 10
                onValueChanged: {
                    pointsValue.text = Math.round(value).toString()
                    chartDataProvider.pointCount = value
                }
                onMoved: updatePlot()
            }
            Label {
                id: pointsValue
                text: Math.round(pointsSlider.value).toString()
                Layout.preferredWidth: 40
            }
        }

        // Peak frequency label (shown only in FFT mode)
        Label {
            id: peakLabel
            visible: false
            text: ""
            font.pixelSize: 16
            color: "purple"
            Layout.alignment: Qt.AlignHCenter
        }

        // Log axis and phase spectrum toggles (only visible in FFT mode)
        RowLayout {
            Layout.fillWidth: true
            visible: showFFT
            spacing: 10

            CheckBox {
                id: logAxisCheck
                text: "Logarithmic Frequency Axis"
                checked: logFFT
                onToggled: {
                    logFFT = checked
                    updatePlot()
                }
            }
            CheckBox {
                id: phaseCheck
                text: "Show Phase Spectrum"
                checked: showPhase
                onToggled: {
                    showPhase = checked
                    updatePlot()
                }
            }
        }

        // Button row
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 20
            
            Button {
                text: "Reset Parameters"
                onClicked: {
                    chartDataProvider.amplitudeLevel = 1.0
                    chartDataProvider.frequencyLevel = 1.0
                    chartDataProvider.phaseLevel = 0.0
                    chartDataProvider.noiseLevel = 0.0
                    chartDataProvider.windowType = "None"
                    windowCombo.currentIndex = 0
                    updatePlot()
                }
            }
            
            Button {
                text: "Random Parameters"
                onClicked: {
                    chartDataProvider.amplitudeLevel = 0.1 + Math.random() * 2.9
                    chartDataProvider.frequencyLevel = 0.1 + Math.random() * 2.9
                    chartDataProvider.phaseLevel = Math.random() * 6.28
                    chartDataProvider.noiseLevel = Math.random()
                    chartDataProvider.windowType = ["None", "Hann", "Hamming", "Blackman"][Math.floor(Math.random() * 4)]
                    windowCombo.currentIndex = ["None", "Hann", "Hamming", "Blackman"].indexOf(chartDataProvider.windowType)
                    updatePlot()
                }
            }

            // FFT toggle button
            Button {
                text: showFFT ? "Show Wave" : "Show FFT"
                onClicked: {
                    showFFT = !showFFT
                    updatePlot()
                }
            }

            // Export CSV buttons
            Button {
                text: "Export Wave CSV"
                onClicked: chartDataProvider.export_csv("wave")
            }
            Button {
                text: "Export FFT CSV"
                onClicked: chartDataProvider.export_csv("fft")
            }
        }
    }
    
    // Generate a default plot on startup
    Component.onCompleted: {
        updatePlot()
    }
}
