# LFP-PowerAnalysis

This repository includes Local Field Potential (LFP) Power Analysis codes related to an upcoming journal paper. Links and citation will be provided upon publication.

## Quick Start
This work depends on `abfload()` function by Harald Hentschke to read `.abf` files, which can be obtained at [Mathworks Central File Exchange by Harald Hentschke](https://www.mathworks.com/matlabcentral/fileexchange/6190-abfload).

The scripts locate datafiles according to the table provided via an Excel file. A template for such file is provided in `datasetmap_template.xlsx`.

The main entry points are `power.m` and `power_byevent.m` files.

## Folder Structure

### Main Files
- `power.m` is a **script** file for Theta power analysis.
- `power_byevent.m` is a **script** file for Gamma<sub>s</sub> and Gamma<sub>m</sub> power analysis based on detected events.

### Functions
- `downsampleData.m` is a function for downsampling vectors. It calculates the needed downsampling ratio and iterations count to efficiently deliver the asked sampling rate. It also takes care of anti-aliasing filtering before downsampling.
- `filterTheta.m`, `filterGammaSlow.m`, and `filterGammaMid.m` are functions which design corresponding filters (i.e. Theta, Gamma<sub>s</sub>, and Gamma<sub>m</sub> frequency ranges, respectively) and then perform zero-phased filtering on the signal. Designed filters are cached for optimal speed in loops.
- `getSpeedRanges.m` is a function that calculates the movement speed of subject based on the optical quadrature encoder signal, and then returns the ranges of signal where speed matches the required criterion.
- `getEvents.m` is a function that detects the ranges of signal containing oscillation events exceeding the mean plus *n* times of the signal's standard deviation, and returns them.

## License
This project is released under GNU General Public License version 3. Please see LICENSE file.

