# OCI360 - Oracle Cloud Infrastructure 360º View

## What is OCI360?

**Oracle Cloud Infrastructure 360º View** is a free open-source framework and tool to generate fancy html output of your tenancy that allows for quick analysis of an existing cloud estate to better optimize the use of cloud resources. You can also adapt it to generate your own queries and create some custom reports over your OCI tenancy.

The tool installs nothing and all it needs is a database schema to generate and read your tenancy model (more info below). It takes around 30 minutes to execute.

Output ZIP file can be large (several MBs), so you may want to execute OCI360 from a system directory with at least 1 GB of free space.

OCI360 uses [moat369](https://github.com/dbarj/moat369) API to generate html and graphs output. If you are familiar to edb360 and sqld360, you will notice they all have the same Look'n Feel.

**For a sample full report from my tenancy, check http://oci360.dbarj.com.br/.**

## How does it work?

OCI360 will load and convert all the JSON information of your OCI tenancy into Oracle Database tables and views, creating a full metadata structured model.
After the model is created on your database, it will query those tables and create reports about your OCI.

The overall execution can be divided in 3 steps:

#### Exporter Phase

First, the tool will connect to OCI through the delivered command line interface (OCI-CLI) and get tenancy metadata in JSON format.

![Exporter](https://raw.githubusercontent.com/dbarj/repo_pics/master/oci360/Exporter.png)

#### Converter Phase

Later, the tool will collect the JSON files output by the extractor and load the data to an Oracle Database for analysis and reporting.

![Converter](https://raw.githubusercontent.com/dbarj/repo_pics/master/oci360/Converter.png)

#### Reporter Phase

Finally, the tool will pull the data from the Oracle database to generate tables and charts that are then output in HTML format for consumption.

![Reporter](https://raw.githubusercontent.com/dbarj/repo_pics/master/oci360/Reporter.png)

## Execution Steps

For the execution steps, please check the [Wiki Page](https://github.com/dbarj/oci360/wiki/Execution-Steps).

## Results

1. Unzip output **OCI360_YYYYMMDD_HH24MI.zip** into a directory on your PC.

2. Review main html file **00001_oci360_index.html**.

![Output](https://raw.githubusercontent.com/dbarj/repo_pics/master/oci360/OCI360_Index.png)

## Sample Sections

Below are some sections generated by OCI360:

#### Infrastructure View

![Output](https://raw.githubusercontent.com/dbarj/repo_pics/master/oci360/OCI360_Infrastructure_View_Example.png)

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

**For a sample full report from my tenancy, check http://oci360.dbarj.com.br/.**

## Latest change

* 20.05 (2020-06-03)
  - Now OCI360 can also run in ADB.
  - New "Audit" section.
  - New "Usage" section.
  - oci_json_export.sh with new items.

Check **[CHANGELOG.md](https://github.com/dbarj/oci360/blob/master/CHANGELOG.md)** for more info.