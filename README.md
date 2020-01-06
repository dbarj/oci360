# OCI360 - Oracle Cloud Infrastructure 360º View

**Oracle Cloud Infrastructure 360º View** is a free open-source framework and tool to generate fancy html output of your tenancy that allows for quick analysis of an existing cloud estate to better optimize the use of cloud resources.

The tool installs nothing on the tenancy, and all it needs is some read/inspect privileges on your tenancy (more information below). It takes around 30 minutes to execute.

Output ZIP file can be large (several MBs), so you may want to execute OCI360 from a system directory with at least 1 GB of free space.

OCI360 uses [moat369](https://github.com/dbarj/moat369) API to generate html and graphs output. If you are familiar to edb360 and sqld360, you will notice they all have the same Look'n Feel.

## How does it works

OCI360 will load and convert all the JSON information of your OCI tenancy into Oracle Database tables and views, creating a full metadata structured model.
After the model is created on your database, it will query those tables and create reports about your OCI.

The overall execution can be divided in 3 steps:

#### Exporter Phase

![Exporter](https://raw.githubusercontent.com/dbarj/repo_pics/master/oci360/Exporter.png)

In this step, the tool:
- Connects to OCI through the delivered command line interface (CLI) and gets tenancy metadata in JSON format.

#### Converter Phase

![Converter](https://raw.githubusercontent.com/dbarj/repo_pics/master/oci360/Converter.png)

In this step, the tool:
- Collects the JSON files output by the extractor and loads the data to an Oracle Database for analysis and reporting.

#### Reporter Phase

![Reporter](https://raw.githubusercontent.com/dbarj/repo_pics/master/oci360/Reporter.png)

In this step, the tool:
- Pulls data from the Oracle database to generate tables and charts that are then output in HTML format for consumption.

## Execution Steps

For the execution steps, please check the [Wiki Page](https://github.com/dbarj/oci360/wiki/Execution-Steps).

## Results

1. Unzip output **OCI360_YYYYMMDD_HH24MI.zip** into a directory on your PC.

2. Review main html file **00001_oci360_index.html**.

![Output](https://raw.githubusercontent.com/dbarj/repo_pics/master/oci360/OCI360_Index.png)

## Sample Sections

Below are some sections generated by OCI360:

#### Compute Instances Info

![Output](https://raw.githubusercontent.com/dbarj/repo_pics/master/oci360/OCI360_Instances_Example.png)

#### Subscribed regions Map

![Output](https://raw.githubusercontent.com/dbarj/repo_pics/master/oci360/OCI360_Map_Example.png)

#### Space Summary

![Output](https://raw.githubusercontent.com/dbarj/repo_pics/master/oci360/OCI360_Space_Sum_Example.png)

#### Backup Utilization Forecast

![Output](https://raw.githubusercontent.com/dbarj/repo_pics/master/oci360/OCI360_Forecast_Example.png)

#### Shapes per Compute

![Output](https://raw.githubusercontent.com/dbarj/repo_pics/master/oci360/OCI360_Shapes_Example.png)

#### Volume Treemap

![Output](https://raw.githubusercontent.com/dbarj/repo_pics/master/oci360/OCI360_Treemap_Example.png)

## Latest change

* 2001 (2020-01-06)
  - Initial Release.

Check **CHANGELOG.md** for more info.