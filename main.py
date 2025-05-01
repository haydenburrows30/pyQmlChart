import sys
import numpy as np
import csv
from PySide6.QtCore import QObject, Signal, Slot, Property, QUrl, QStandardPaths, QDir
from PySide6.QtWidgets import QApplication
from PySide6.QtQml import QQmlApplicationEngine
from series_helper import SeriesHelper

class ChartDataProvider(QObject):
    # Signals to notify when data has changed
    dataChanged = Signal()
    titleChanged = Signal()
    fftDataChanged = Signal()
    fftTitleChanged = Signal()
    peakFreqChanged = Signal(float)
    windowTypeChanged = Signal()
    noiseLevelChanged = Signal()
    phaseDataChanged = Signal()
    phaseTitleChanged = Signal()
    logFFTDataChanged = Signal()
    logPhaseDataChanged = Signal()
    plotTypeChanged = Signal()
    amplitudeLevelChanged = Signal()
    frequencyLevelChanged = Signal()
    phaseLevelChanged = Signal()
    pointCountChanged = Signal()
    
    def __init__(self):
        super().__init__()
        self._x_values = []
        self._y_values = []
        self._title = "Chart"
        self._point_count = 500
        # FFT data
        self._fft_x = []
        self._fft_y = []
        self._fft_title = "FFT"
        self._peak_freq = 0.0
        self._window_type = "None"
        self._plot_type = "Sine Wave"
        self._noise_level = 0.0
        self._amplitude_level = 1.0
        self._frequency_level = 1.0
        self._phase_level = 0.0
        # Phase spectrum data
        self._phase_x = []
        self._phase_y = []
        self._phase_title = "Phase Spectrum"
        # Log scale FFT data
        self._log_fft_x = []
        self._log_fft_y = []
        # Log scale Phase data
        self._log_phase_x = []
        self._log_phase_y = []

    @Property(list, notify=dataChanged)
    def xValues(self):
        return self._x_values
        
    @Property(list, notify=dataChanged)
    def yValues(self):
        return self._y_values
        
    @Property(str, notify=titleChanged)
    def title(self):
        return self._title

    @Property(int, notify=pointCountChanged)
    def pointCount(self):
        return self._point_count
        
    @pointCount.setter
    def pointCount(self, count):
        if self._point_count != count:
            self._point_count = max(100, min(5000, count))  # Bounds check
            self.pointCountChanged.emit()
    
    @Property(float, notify=amplitudeLevelChanged)
    def amplitudeLevel(self):
        return self._amplitude_level

    @amplitudeLevel.setter
    def amplitudeLevel(self, level):
        if self._amplitude_level != level:
            self._amplitude_level = level
            self.amplitudeLevelChanged.emit()

    @Property(float, notify=frequencyLevelChanged)
    def frequencyLevel(self):
        return self._frequency_level

    @frequencyLevel.setter
    def frequencyLevel(self, level):
        if self._frequency_level != level:
            self._frequency_level = level
            self.frequencyLevelChanged.emit()

    @Property(float, notify=phaseLevelChanged)
    def phaseLevel(self):
        return self._phase_level

    @phaseLevel.setter
    def phaseLevel(self, level):
        if self._phase_level != level:
            self._phase_level = level
            self.phaseLevelChanged.emit()
            
    @Property(list, notify=fftDataChanged)
    def fftX(self):
        return self._fft_x

    @Property(list, notify=fftDataChanged)
    def fftY(self):
        return self._fft_y

    @Property(str, notify=fftTitleChanged)
    def fftTitle(self):
        return self._fft_title

    @Property(float, notify=peakFreqChanged)
    def peakFreq(self):
        return self._peak_freq

    @Property(str, notify=windowTypeChanged)
    def windowType(self):
        return self._window_type

    @windowType.setter
    def windowType(self, wtype):
        if self._window_type != wtype:
            self._window_type = wtype
            print(f"Window type set to: {wtype}")
            self.windowTypeChanged.emit()

    @Property(float, notify=noiseLevelChanged)
    def noiseLevel(self):
        return self._noise_level

    @noiseLevel.setter
    def noiseLevel(self, level):
        if self._noise_level != level:
            self._noise_level = max(0.0, min(2.0, level))
            self.noiseLevelChanged.emit()

    @Property(str, notify=plotTypeChanged)
    def plotType(self):
        return self._plot_type

    @plotType.setter
    def plotType(self, wtype):
        if self._plot_type != wtype:
            self._plot_type = wtype
            print(f"Plot type set to: {wtype}")
            self.plotTypeChanged.emit()

    @Property(list, notify=phaseDataChanged)
    def phaseX(self):
        return self._phase_x

    @Property(list, notify=phaseDataChanged)
    def phaseY(self):
        return self._phase_y

    @Property(str, notify=phaseTitleChanged)
    def phaseTitle(self):
        return self._phase_title

    @Property(list, notify=logFFTDataChanged)
    def logFFTX(self):
        return self._log_fft_x

    @Property(list, notify=logFFTDataChanged)
    def logFFTY(self):
        return self._log_fft_y
        
    @Property(list, notify=logPhaseDataChanged)
    def logPhaseX(self):
        return self._log_phase_x

    @Property(list, notify=logPhaseDataChanged)
    def logPhaseY(self):
        return self._log_phase_y

    @Slot()
    def generate_data(self):
        """Generate data based on current property values"""
        # Use the properties directly instead of parameters
        plot_type = self._plot_type.lower().split()[0]  # Convert "Sine Wave" to "sine"
        amplitude = self._amplitude_level
        frequency = self._frequency_level
        phase = self._phase_level
        
        # Generate x values with adaptive point density for smoother curves
        x = np.linspace(0, 100, self._point_count)
        
        # Calculate y values based on plot type and parameters
        if plot_type == "sine":
            # Create frequency in cycles per 100 units
            # For a frequency of 5 Hz, we want 5 complete cycles over the range [0, 100]
            angular_freq = frequency * (2 * np.pi / 100)  
            y = amplitude * np.sin(angular_freq * x + phase)
            self._title = f"Sine Wave: A={amplitude:.1f}, f={frequency:.1f} Hz, φ={phase:.1f}"
        elif plot_type == "cosine":
            angular_freq = frequency * (2 * np.pi / 100)
            y = amplitude * np.cos(angular_freq * x + phase)
            self._title = f"Cosine Wave: A={amplitude:.1f}, f={frequency:.1f} Hz, φ={phase:.1f}"
        elif plot_type == "parabola":
            y = amplitude * (x - phase)**2
            self._title = f"Parabola: A={amplitude:.1f}, offset={phase:.1f}"
        else:
            angular_freq = frequency * (2 * np.pi / 100)
            y = amplitude * np.sin(angular_freq * x + phase)
            self._title = f"Sine Wave: A={amplitude:.1f}, f={frequency:.1f} Hz, φ={phase:.1f}"
        
        # Add noise if requested
        if self._noise_level > 0.0:
            y = y + np.random.normal(0, self._noise_level, size=y.shape)

        # Convert numpy arrays to Python lists
        self._x_values = x.tolist()
        self._y_values = y.tolist()
        
        # Emit signals that data has changed
        self.dataChanged.emit()
        self.titleChanged.emit()
        
        return True

    @Slot()
    def compute_fft(self):
        """Compute FFT with correct frequency scaling."""
        # Compute FFT of current yValues
        if not self._y_values or len(self._y_values) < 2:
            self._fft_x = []
            self._fft_y = []
            self._fft_title = "FFT (no data)"
            self._peak_freq = 0.0
            self._phase_x = []
            self._phase_y = []
            self._phase_title = "Phase Spectrum (no data)"
            # Clear log data too
            self._log_fft_x = []
            self._log_fft_y = []
            self._log_phase_x = []
            self._log_phase_y = []
            self.fftDataChanged.emit()
            self.fftTitleChanged.emit()
            self.peakFreqChanged.emit(self._peak_freq)
            self.phaseDataChanged.emit()
            self.phaseTitleChanged.emit()
            self.logFFTDataChanged.emit()
            self.logPhaseDataChanged.emit()
            return False

        y = np.array(self._y_values)
        n = len(y)
        x = np.array(self._x_values)
        
        # Determine the sampling rate and period
        x_range = x[-1] - x[0]  # Always 100 in our case
        
        # Apply window if requested
        window = np.ones_like(y)
        if self._window_type == "Hann":
            window = np.hanning(n)
        elif self._window_type == "Hamming":
            window = np.hamming(n)
        elif self._window_type == "Blackman":
            window = np.blackman(n)
        yw = y * window
        
        # Compute FFT
        fft_vals = np.fft.rfft(yw)
        freq = np.fft.rfftfreq(n, d=1/n)
        
        # Normalize amplitude
        fft_mag = np.abs(fft_vals) / n * 2
        
        # Store linear scale data
        self._fft_x = freq.tolist()
        self._fft_y = fft_mag.tolist()
        self._fft_title = f"FFT Spectrum (N={n}, Window={self._window_type})"

        # Phase spectrum
        phase = np.angle(fft_vals)
        self._phase_x = freq.tolist()
        self._phase_y = phase.tolist()
        self._phase_title = f"Phase Spectrum (N={n}, Window={self._window_type})"
        
        # Generate logarithmic scale data for frequency domain
        mask = freq > 0
        if np.any(mask):
            log_freq = np.log10(freq[mask])
            self._log_fft_x = log_freq.tolist()
            self._log_fft_y = fft_mag[mask].tolist()
            self._log_phase_x = log_freq.tolist()
            self._log_phase_y = phase[mask].tolist()
        else:
            self._log_fft_x = []
            self._log_fft_y = []
            self._log_phase_x = []
            self._log_phase_y = []

        # Peak detection (ignore DC)
        if len(freq) > 1:
            idx = np.argmax(fft_mag[1:]) + 1
            self._peak_freq = freq[idx]
            print(f"Detected peak frequency: {self._peak_freq} Hz (set frequency: {self._frequency_level} Hz)")
        else:
            self._peak_freq = 0.0

        # Ensure all signals are emitted
        self.fftDataChanged.emit()
        self.fftTitleChanged.emit()
        self.peakFreqChanged.emit(self._peak_freq)
        self.phaseDataChanged.emit()
        self.phaseTitleChanged.emit()
        self.logFFTDataChanged.emit()
        self.logPhaseDataChanged.emit()
        
        return True

    @Slot(str)
    def export_csv(self, mode):
        if mode == "wave":
            x, y = self._x_values, self._y_values
            fname = "waveform.csv"
        else:
            x, y = self._fft_x, self._fft_y
            fname = "fft.csv"
        path = QStandardPaths.writableLocation(QStandardPaths.DocumentsLocation)
        filepath = QDir(path).filePath(fname)
        try:
            with open(filepath, "w", newline="") as f:
                writer = csv.writer(f)
                writer.writerow(["x", "y"])
                for xi, yi in zip(x, y):
                    writer.writerow([xi, yi])
            print(f"Exported to {filepath}")
            return True
        except Exception as e:
            print(f"Export failed: {e}")
            return False

    @Slot(list, result="QVariantMap")
    def getMinMax(self, array):
        """Calculate min and max values from an array with safety checks and padding.
        
        Returns a dictionary with min and max values that can be used to set axis ranges.
        """
        if not array or len(array) < 1:
            return {"min": 0, "max": 1}
            
        # Only sample a reasonable number of points for min/max calculation
        max_sample_points = 1000
        step = len(array) > max_sample_points and int(len(array) / max_sample_points) or 1
            
        # Use NumPy for faster calculation if possible
        if isinstance(array, np.ndarray):
            # Use efficient numpy operations
            if step > 1:
                sampled = array[::step]
                min_val = np.min(sampled)
                max_val = np.max(sampled)
            else:
                min_val = np.min(array)
                max_val = np.max(array)
        else:
            # Fallback to list operations
            min_val = array[0]
            max_val = array[0]
            
            for i in range(0, len(array), step):
                if array[i] < min_val:
                    min_val = array[i]
                if array[i] > max_val:
                    max_val = array[i]
        
        # Avoid zero ranges that cause render issues
        if abs(max_val - min_val) < 0.00001:
            max_val = min_val + 1
        
        # Add padding (5%)
        padding = (max_val - min_val) * 0.05
        
        return {"min": min_val - padding, "max": max_val + padding}
    
    @Slot(QObject, str)
    def setAxisRange(self, axis, data_type):
        """Set axis range based on data type.
        
        Args:
            axis: The QValueAxis object
            data_type: String indicating the type of data ('fft', 'phase', 'wave', etc.)
        """
        if data_type == "wave":
            # Time domain wave
            data = self._y_values
            if data:
                range_data = self.getMinMax(data)
                # Add extra padding for waves
                padding = (range_data["max"] - range_data["min"]) * 0.15
                axis.setMin(range_data["min"] - padding)
                axis.setMax(range_data["max"] + padding)
            else:
                axis.setMin(-1)
                axis.setMax(1)
                
        elif data_type == "wave_x":
            # X-axis for time domain
            axis.setMin(0)
            axis.setMax(100)
            
        elif data_type == "fft":
            # FFT magnitude
            data = self._fft_y
            if data:
                # For FFT magnitude, always start at 0
                axis.setMin(0)
                max_val = max(data) * 1.1  # Add 10% margin
                axis.setMax(max_val)
            else:
                axis.setMin(0)
                axis.setMax(1)
                
        elif data_type == "fft_x":
            # X-axis for FFT
            if self._fft_x:
                axis.setMin(0)
                axis.setMax(self._fft_x[-1])
            else:
                axis.setMin(0)
                axis.setMax(100)
                
        elif data_type == "phase":
            # Phase spectrum
            axis.setMin(-np.pi)
            axis.setMax(np.pi)
            
        elif data_type == "log_fft":
            # Log scale FFT magnitude
            data = self._log_fft_y
            if data:
                # For FFT magnitude, always start at 0
                axis.setMin(0)
                max_val = max(data) * 1.1  # Add 10% margin
                axis.setMax(max_val)
            else:
                axis.setMin(0)
                axis.setMax(1)
                
        elif data_type == "log_fft_x":
            # Log scale X-axis
            data = self._log_fft_x
            if data:
                range_data = self.getMinMax(data)
                axis.setMin(range_data["min"])
                axis.setMax(range_data["max"])
            else:
                axis.setMin(0)
                axis.setMax(1)

def main():
    app = QApplication(sys.argv)
    
    # Register the QML types
    engine = QQmlApplicationEngine()
    
    # Create and register the data provider
    chart_data_provider = ChartDataProvider()
    engine.rootContext().setContextProperty("chartDataProvider", chart_data_provider)
    
    # Create and register the series helper
    series_helper = SeriesHelper()
    engine.rootContext().setContextProperty("seriesHelper", series_helper)
    
    # Load the QML file
    engine.load(QUrl.fromLocalFile("main.qml"))
    if not engine.rootObjects():
        return -1
    return app.exec()

if __name__ == "__main__":
    sys.exit(main())
