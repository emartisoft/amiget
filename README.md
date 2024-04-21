# amiget
A console application to search for and download packages from aminet for AmigaOS 3.X

# How to use
Let me try to explain how to use it by giving an example. 

Enter the following command to list the packages published on Aminet.net in the last 30 days.

```bash
amiget -L
```

This command creates a table with columns ID, Name, Path, Size, Date and Description. At the end of the list, it waits for you to enter for selection. 

If it consists of multiple pages, you can navigate between pages with Next, Prev and Go to Page. Identify and enter the ID of the package you want to process. The selected package is available for download. If this package is a compressed file (lha, zip, gz, tar.gz) it can be extracted after download. Or it can be mounted if it is an ADF image (this feature is only available for OS3.2). Or you may just want to view the readme file of the package. You can also skip these operations and return to the list.

Exit the application after downloading or viewing the readme file. At this point, enter the following command to return to the list:

```bash
amiget -S
```

Let's say you only viewed the readme file but then you want to download it. Then enter this command to download the active package:
```bash
amiget -D
```
You can use this command to download the same package again. You can also use it to resume the download if you interrupted it with CTRL-C.

Or you downloaded the package but want to view the readme file:
```bash
amiget -R
```
The package you are looking for may not have been published in the last 30 days. What to do? To search for demo packs for parties from 1992, enter this:
```bash
amiget -s demo party 92
```
You can also download the package you want to download without searching. For example, to download the package /util/misc/AmigaGPT.lha and save it in the RAM:Downloads/AI drawer:
```bash
amiget -d AmigetGPT.lha util/misc RAM:Downloads/AI
```
If you make an entry as a suboption:
```bash
amiget -dexy AmigetGPT.lha util/misc RAM:Downloads/AI
```
It does not ask for confirmation to download, notifies you with a sound effect and extracts all the contents of the package after the download is complete.

If you want to view the readme file:
```bash
amiget -r AmigetGPT.lha util/misc RAM:Downloads/AI
```
for suboption details:
```bash
amiget -h
```
