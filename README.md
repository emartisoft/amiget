# What's amiget?
A console application to search for and download packages from aminet on AmigaOS 3.X

This application was coded on a real Amiga using `Amiga-E` and `C` language.

An internet connection is required to use this application (bsdsocket.library). 

**Although it is not certain, the application may not work properly on Amiga emulators.**

![operation](https://github.com/emartisoft/amiget/blob/main/screenshots/operation.png?raw=true)

# How to use
Let me try to explain how to use it by giving an example. 

Enter the following command to list the packages published on Aminet.net in the last 30 days.

```bash
amiget -L
```

This command creates a table with columns `ID`, `Name`, `Path`, `Size`, `Date` and `Description`.

If it consists of multiple pages, you can navigate between pages with `Next`, `Prev` and `Go to Page`. Identify and enter the ID of the package you want to process. The selected package is available to download (`Download`). If this package is a compressed file (lha, zip or tar.gz) it can be extracted after download (`Download & Extract`). Or it can be mounted if it is an ADF image (this feature is only available for OS3.2)(`Download & Mount`). Or you may just want to view the readme file of the package (`Readme`). You can also skip these operations and return to the list (`Return List`).

Exits the application after downloaded package or displayed the readme file. At this point, enter the following command to return to the list:

```bash
amiget -S
```

Let's say you only viewed the readme file but then you want to download it. Then enter this command to download the active package:
```bash
amiget -D
```
You can also use this command to download the same package again. You can also use it to resume to download if you interrupted it with `CTRL-C`.

Or you downloaded the package but want to view the readme file:
```bash
amiget -R
```
The package you are looking for may not have been published in the last 30 days. What to do? For example: To search for demo packages for parties from 1992, enter this:
```bash
amiget -s demo party 92
```
If you want to sort the table by column names:
```bash
-sn : name
-sp : path
-sd : date
-ss : size
```
To sort by date:
```bash
amiget -sd demo party 92
```
Also if you want to sort in ascending or descending order:
```bash
-s?a : ascending
-s?z : descending
```
To sort in descending order by date
```bash
amiget -sdz demo party 92
```
You can also download the package you want to download without searching. For example, to download the package `/util/misc/AmigaGPT.lha` and save it in the `RAM:Downloads/AI` drawer:
```bash
amiget -d AmigetGPT.lha util/misc RAM:Downloads/AI
```
If you make an entry with suboption:
```bash
amiget -dexy AmigetGPT.lha util/misc RAM:Downloads/AI
```
It does not ask for confirmation to download, notifies you with a sound effect and extracts all the contents of the package after the download is complete.

If you want to view the readme file:
```bash
amiget -r AmigetGPT.lha util/misc
```
for suboption details:
```bash
amiget -h
```
Enter the following command to create an `amiget.cfg` config file in the `SYS:Prefs/Env-Archive` drawer:
```bash
amiget -c
```
After this command, a config file is created and the titled `SYS:Prefs/Env-Archive` window opens. To edit the file, open it with a text editor. The necessary explanations are described in the config file.

# How to compile
## amiget
Copy all module files in the Module drawer to the `EModules:` assignment.
```bash
copy #?.m to EModules:
```
Compile amiget with the following command:
```bash
evo amiget.e
```
More Info for `E-VO Amiga E Compiler`: https://github.com/dmcoles/EVO
## amisearch
To compile with `SAS/C`:
- Copy all header files from the include drawer to the `sc:include` assignment.
- Copy all lib files from the lib drawer to the `sc:lib` assignment.
- To compile amisearch:
```bash
execute amisearch.c
```
## installer
Compile installer with the following command:
```bash
evo copy2c.e
evo install.e
```
