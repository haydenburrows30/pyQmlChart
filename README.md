# pyQmlChart

Some optimized methods for filling a chart series in QML from Python.

https://github.com/user-attachments/assets/e1fd9558-ea6d-42bb-8c76-e5d443dc548a

## series_helper
Contains these methods:


1. ```fillSeries```
Main method for filling QML chart with ```series.replace```


2. ```fillSeriesFromArrays```
Creates array with ```QPointF```, then uses ```fillSeries``` to fill chart


3. ```fillSeriesOptimized```
Takes a point count value and uses the ```downSample``` (LTTB) method to downsample data while preserving important features.


4. ```fillSeriesParallel```
Uses ```downSample```, ```fillSeriesFromArrays``` and worker thread.  First the series is filled with lower resolution data, then the higher resolution is calculated and filled with the worker thread.

## Features

- Point count to speed up wave and fft generation
- Axis updates from python
- All calculations in python
- Zooming, scrolling and tooltips in chart