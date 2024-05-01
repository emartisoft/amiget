->-------------------------------------------<-
-> Amiget v1.1 (29/04/2024)
-> Coded by emarti, Murat Ozdemir 
->-------------------------------------------<-

OPT OSVERSION=37
OPT PREPROCESS
OPT LARGE

#define VERSION 'Amiget v1.1 (29.04.2024)'

MODULE  'ftpaminet',
        'dos/dos',
        'dos',
        'playtone',
        'arguments',
        'fileexist',
        'makedir'


#define SEARCHFILENAME  'RAM:T/search.dat'
#define PROCESSING      'RAM:T/processing.dat'
#define CONFIGFILE      'SYS:Prefs/Env-Archive/amiget.cfg'
#define BUFFER          $400

DEF amiftp:PTR TO transfer,
    paramCount,
    paramIndex,
    paramStr[$200]:STRING,
    aminetPath[$100]:STRING,
    aminetFilename[$100]:STRING,
    aminetFileReadme[$100]:STRING,
    destinationDrawer[$100]:STRING,
    searchwords[$100]:STRING,
    choice[6]:STRING,
    fp,
    line[BUFFER/2]:STRING,
    s: LONG,
    cfg,
    cfgDownloadDrawer[$200]:STRING,
    cfgLine[$200]:STRING,
    cfgTemp[$200]:STRING,
    recordsperpage=25,
    sort[2]:STRING,
    ord[2]:STRING
             
->-------------------------------------------<-
PROC main()

    amiftp:= NEW amiftp
    amiftp.isreadme:=0
    amiftp.yes:=0
    amiftp.extract:=0
    amiftp.effect:=0
    
    IF (cfg:=Open(CONFIGFILE, MODE_OLDFILE))=NIL
        -> No config file found
        StrCopy(cfgDownloadDrawer, 'RAM:') 
    ELSE
        WHILE (Fgets(cfg, cfgLine, BUFFER/2)<>NIL)
            IF cfgLine[0]<>"#"
                IF InStr(cfgLine, 'RECORDS_PER_PAGE')<>-1
                    MidStr(cfgTemp, cfgLine, 17)
                    recordsperpage := Val(cfgTemp)
                    
                ELSEIF InStr(cfgLine, 'DOWNLOAD_DRAWER')<>-1
                    MidStr(cfgTemp, cfgLine, 16)
                    StrCopy(cfgDownloadDrawer, cfgTemp)
                    cfgDownloadDrawer[StrLen(cfgDownloadDrawer)-1]:=$0
                    IF NOT fileExist(cfgDownloadDrawer)
                        mkdir(cfgDownloadDrawer)
                    ENDIF
                    amiftp.localpath:= cfgDownloadDrawer
                    
                ELSEIF InStr(cfgLine, 'AUTO_YES=Yes')<>-1
                    amiftp.yes:=1
                    
                ELSEIF InStr(cfgLine, 'SOUND_EFFECT=Yes')<>-1
                    amiftp.effect:=1
                ENDIF
            ENDIF
                      
        ENDWHILE
        Close(cfg)
    ENDIF

    initplay()
    
    StrCopy(paramStr, arg)
    paramCount:=getargs(0, paramStr) -> total argument count
    
    SELECT paramCount
        CASE -1
            help()
        CASE 3
            paramCount:=getargs(2, aminetFilename)
            paramCount:=getargs(3, aminetPath)
            StrCopy(destinationDrawer, cfgDownloadDrawer, ALL)
        CASE 4
            paramCount:=getargs(2, aminetFilename)
            paramCount:=getargs(3, aminetPath)
            paramCount:=getargs(4, destinationDrawer)
            IF destinationDrawer[StrLen(destinationDrawer)-1]="/" THEN destinationDrawer[StrLen(destinationDrawer)-1]:=$0    
            IF NOT fileExist(destinationDrawer)
                mkdir(destinationDrawer)
            ENDIF
        DEFAULT
            
    ENDSELECT
    
    IF aminetPath[StrLen(aminetPath)-1]<>"/" THEN StrAdd(aminetPath, '/', ALL) ELSE aminetPath[StrLen(aminetPath)-1]:=$0

    paramCount:=getargs(1, paramStr)
    IF (paramStr[0]<>"-")  -> always use/begins '-' char.
        help()
    ENDIF
    
    paramIndex:=1
    
    SELECT paramStr[paramIndex]
    
        CASE "h" -> help
            help()
        CASE "v" -> version
            version()
            CleanUp(0)
        CASE "c" -> creates default config file
            createConfigFile()
        CASE "s" -> search
            -> amisearch is exists?
            IF NOT ((fileExist('PROGDIR:amisearch'))OR(fileExist('SYS:C/amisearch')))
                WriteF('\e[1;31;40m\aamisearch\a not found.\e[0;31;40m Try reinstalling \aAmiget\a to fix the problem\n')
                JUMP end2
            ENDIF
            
            -> sort and order
            StrCopy(sort, 'n')
            StrCopy(ord, 'a')
            paramIndex:=2
            REPEAT
                -> sort by name
                IF (paramStr[paramIndex]="n") THEN StrCopy(sort, 'n')
                -> sort by path
                IF (paramStr[paramIndex]="p") THEN StrCopy(sort, 'p')
                -> sort by date
                IF (paramStr[paramIndex]="d") THEN StrCopy(sort, 'd')
                -> sort by size
                IF (paramStr[paramIndex]="s") THEN StrCopy(sort, 's')
                -> ascending order
                IF (paramStr[paramIndex]="a") THEN StrCopy(ord, 'a')
                -> descending order
                IF (paramStr[paramIndex]="z") THEN StrCopy(ord, 'z')
                paramIndex++
            UNTIL paramIndex > StrLen(paramStr)
            
            MidStr(searchwords, arg, paramIndex, ALL)
            StrCopy(searchwords, TrimStr(searchwords))
            IF StrLen(searchwords)<2
                WriteF('Insufficient length for search\n')
                JUMP end2
            ENDIF  

            StringF(searchwords, 'amisearch \s\s \s', sort, ord, searchwords);
            prerunamisearch:
            DeleteFile(SEARCHFILENAME)
            
            sound(amiftp)
            s:=SystemTagList(searchwords, NIL)
            
            IF s<1 THEN JUMP end
            table:
            IF (opendocument(SEARCHFILENAME, s)>0)
                
                sound(amiftp)
                WriteF(' \e[1;31;40mPackage Name:\e[0;31;40m \s\n\n', aminetFilename)
                whattodo:
                WriteF(' \e[0;30;41m [D]ownload \e[0;31;40m')
                IF ((InStr(aminetFilename, '.lha')>-1) OR (InStr(aminetFilename, '.zip')>-1) OR (InStr(aminetFilename, '.gz')>-1) ) THEN
                        WriteF('  \e[0;30;41m Download & [E]xtract \e[0;31;40m')
                IF InStr(aminetFilename, '.adf') > -1 THEN
                    WriteF('  \e[0;30;41m Download & [M]ount \e[0;31;40m')
                
                WriteF('  \e[0;30;41m [R]eadme \e[0;31;40m  \e[0;30;41m Return [L]ist \e[0;31;40m  \e[0;30;41m [Q]uit \e[0;31;40m   \e[1;31;40mEnter your choice ==>\e[0;31;40m  ')
                
                ReadStr(stdout, choice) 
                StrCopy(choice, TrimStr(choice))
                LowerStr(choice)
                
                
                IF (choice[0]="d")
                    StrCopy(destinationDrawer, cfgDownloadDrawer, ALL)
                    downloadpackage()
                    JUMP end2
                ELSEIF (choice[0]="e") OR (choice[0]="m")
                    StrCopy(destinationDrawer, cfgDownloadDrawer, ALL)
                    amiftp.extract:=1
                    downloadpackage()
                    JUMP end2
                ELSEIF (choice[0]="r")
                    readpackage()
                ELSEIF (choice[0]="l")
                    JUMP table
                ELSEIF (choice[0]="q")
                    JUMP end
                ELSE
                    WriteF('\c\c\b',8,8)
                    JUMP whattodo
                ENDIF
            
                
            ENDIF 
            end:
                -> to delete message that includes 'amisearch failure return code -4'
                fillChar($8, 1)
                WriteF('\b')
                fillChar($20, 128)
                WriteF('\b')   
            end2:
            
            
        CASE "r" -> readme
            
            REPEAT
                -> sound effect
                IF (paramStr[paramIndex]="e") THEN amiftp.effect:=1
                paramIndex++
            UNTIL paramIndex > StrLen(paramStr)
            readpackage()
            
        CASE "d" -> download
            REPEAT
                -> yes
                IF (paramStr[paramIndex]="y") THEN amiftp.yes:=1
                -> extract
                IF (paramStr[paramIndex]="x") THEN amiftp.extract:=1
                -> mount adf
                IF (paramStr[paramIndex]="m") THEN amiftp.extract:=1
                -> sound effect
                IF (paramStr[paramIndex]="e") THEN amiftp.effect:=1
                paramIndex++
            UNTIL paramIndex > StrLen(paramStr)
            downloadpackage()
        CASE "S" -> reprocess the last search for packages
            s:=0
            
            IF (fp:= Open(SEARCHFILENAME, MODE_OLDFILE)) <> NIL
                WHILE (Fgets(fp, line, BUFFER/2)<>NIL)
                    s++
                ENDWHILE
                Close(fp)
                
                WriteF('\n\e[1;31;40m Last search results\n Found \d package(s)\e[0;31;40m\n\n',s)
                JUMP table
            ELSE
                WriteF('\e[1;31;40mNo found\e[0;31;40m the last search for packages\n')
            ENDIF
        CASE "D" -> Downloads the processed package
         
            IF activePackage()=TRUE
                downloadpackage()
            ELSE
                WriteF('No processed package\n')
            ENDIF
        CASE "L" -> Latest packages, last 30 days
            StrCopy(searchwords, 'amisearch **recent**')
            JUMP prerunamisearch 
        CASE "R" -> Displays readme file of the processed package
            IF activePackage()
                readpackage()
            ELSE
                WriteF('No processed package\n')
            ENDIF
        DEFAULT
            help()
    ENDSELECT
    
    -> Bye
    freeplay()
    
    END amiftp
    
    IF (amiftp)
        Dispose(amiftp)
        amiftp:=NIL
    ENDIF
    
    
ENDPROC

->-------------------------------------------<-
PROC activePackage()
    IF (cfg:=Open(PROCESSING, MODE_OLDFILE))<>NIL
            
                Fgets(cfg, aminetPath, BUFFER/2)
                aminetPath[StrLen(aminetPath)-1]:=0
                Fgets(cfg, aminetFilename, BUFFER/2)
                aminetFilename[StrLen(aminetFilename)-1]:=0
                StrCopy(destinationDrawer, cfgDownloadDrawer, ALL)
                Close(cfg)
    ELSE
        RETURN FALSE
    ENDIF
ENDPROC TRUE

->-------------------------------------------<-
PROC readpackage()
    amiftp.yes:=1
    amiftp.isreadme:=1
    
    amiftp.remotepath := aminetPath
    amiftp.filename:= aminetFilename
    
    processingSave()
    amiftp.localpath:= 'RAM:T/'
    StrCopy(aminetFileReadme, getfilenamewithoutext(aminetFilename))
    StrAdd(aminetFileReadme, '.readme')
    amiftp.filename:= aminetFileReadme
    

    freeplay()
    download(amiftp)
    initplay()
    
    StringF(aminetFileReadme, 'RAM:T/\s', aminetFileReadme)
    opendocument(aminetFileReadme, 0)
ENDPROC

->-------------------------------------------<-
PROC downloadpackage()
    amiftp.remotepath := aminetPath
    amiftp.filename:= aminetFilename
    amiftp.localpath:= destinationDrawer
    processingSave()
    freeplay()
    download(amiftp)
    initplay()
ENDPROC

->-------------------------------------------<-
PROC help()
    version()
    sound(amiftp)
    WriteF( 'usage: amiget <options>\n\nThe following options are available:\n'+
            '\t-s[<sort><order>] <query>\n\t\tSearches for packages\n'+
            '\t\t\tSort:\n'+
            '\t\t\tn\tName (default)\n'+
            '\t\t\tp\tPath\n'+
            '\t\t\td\tDate\n'+
            '\t\t\ts\tSize\n\n'+
            '\t\t\tOrder:\n'+
            '\t\t\ta\tAscending (default)\n'+
            '\t\t\tz\tDescending\n\n'
            
           ) 
    WriteF( '\t-S\n\t\tReprocesses last search for packages\n'+
            '\t-D\n\t\tDownloads the processed package\n'+
            '\t\t\ta) After displays readme of package\n'+
            '\t\t\tb) To download the same package again\n'+
            '\t\t\tc) To resume to download the same package\n'+
            '\t-R\n\t\tDisplays readme of the processed package\n'+
            '\t-L\n\t\tLatest packages, last 30 days\n\n'
          )
            
    WriteF( '\t-r[<suboptions>] <aminetfilename> <aminetpath>\n'+
            '\t\tDisplays readme of package\n\n'+
            '\t-d[<suboptions>] <aminetfilename> <aminetpath> [<destinationdrawer>]\n'+
            '\t\tDownloads a package from aminet\n\n\t\tThe default destination drawer is "RAM:" or\n'+
            '\t\tcreates if not exist when entered\n\n\t\tsuboptions:\n'
          )
            
    WriteF( '\t\ty\t Automatic yes to prompts\n'+
            '\t\tx\t Extracts all files from package (for lha, tar.gz and zip only)\n'+
            '\t\tm\t Mounts ADF image (for OS3.2.X only)\n'+
            '\t\te\t Informs with sound effect\n\n'+
            '\t-h\tDisplays this help\n'+
            '\t-v\tDisplays version\n'+
            '\t-c\tCreates config file to set some variables\n\n'
          )
          
    WriteF( 'examples:\n'+
            '\tamiget -dxey DAControlGUI.lha disk/misc\n'+
            '\tamiget -de Concrete.lha demo/aga RAM:Demos\n'+
            '\tamiget -s demo party\n'+
            '\tamiget -sdz commodore\n'+
            '\tamiget -re GoAway.lha demo/tp92\n'+
            '\tamiget -R\n\n'+
            'More help, email bug reports, questions, discussions to \e[3;31;40m<dtemarti@gmail.com>\e[0;31;40m\n'+
            'and/or open issue at \e[3;31;40mhttps://github.com/emartisoft/amiget\e[0;31;40m\n\n'
          )
          
    CleanUp(0)
ENDPROC
        
->-------------------------------------------<-
PROC version()
    DEF ver[150]:STRING, lenVer, n
    StrCopy(ver, '\n\e[1;31;40m ')
    StrAdd(ver, VERSION)
    StrAdd(ver, '\n\e[1;33;40m Copyright © 2024 by emarti, Murat Ozdemir\n\e[0;31;40m All rights reserved, MIT License\n\n')
    lenVer:=StrLen(ver)
    
    sound(amiftp)
    FOR n:=0 TO lenVer
        WriteF('\c',ver[n])
        IF ver[n]=" " THEN Delay(3)
    ENDFOR
    Delay(15)
ENDPROC

->-------------------------------------------<-
PROC processingSave()
    DEF pstr[$200]:STRING
    StringF(pstr, '\s\n\s\n',amiftp.remotepath, amiftp.filename)
    
    IF (cfg:=Open(PROCESSING, MODE_NEWFILE))<>NIL
            Write(cfg, pstr, $200)
            Close(cfg)
    ENDIF
ENDPROC

->-------------------------------------------<-
PROC createConfigFile()
    sound(amiftp)
    IF NOT fileExist(CONFIGFILE)
        IF (cfg:=Open(CONFIGFILE, MODE_NEWFILE))<>NIL
            Write(cfg, {configstr}, 700)
            Close(cfg)
            WriteF('Config file created \e[1;31;40m[\s]\e[0;31;40m\n', CONFIGFILE)
        ELSE
            WriteF('Unable to create config file\n')
        ENDIF
    ELSE
        WriteF('Config file already exists\n')
    ENDIF
    IF fileExist('SYS:Rexxc/RX')
        Execute('rx "ADDRESS workbench WINDOW \aSYS:Prefs/Env-Archive\a OPEN"', NIL, NIL)
    ENDIF
ENDPROC

configstr:
CHAR '# ------------------------------------------------------------------',$0a,
 '# Amiget Config File',$0a,
 '# ------------------------------------------------------------------',$0a,$0a,
 '# The maximum number of search results per page, 25 is default',$0a,
 'RECORDS_PER_PAGE=25',$0a,$0a,
 '# The destination drawer to download package file, "RAM:" is default',$0a,
 '# DOWNLOAD_DRAWER=DEMO:Game/Downloads',$0a,
 'DOWNLOAD_DRAWER=RAM:Packages',$0a,$0a,
 '# Automatic yes to prompts after search to download package,',$0a,'# [Yes/No] "No" is default',$0a,
 '# AUTO_YES=Yes',$0a,
 'AUTO_YES=No',$0a,$0a,
 '# Inform with sound effect, [Yes/No] "No" is default',$0a,
 '# WARNING: If SOUND_EFFECT value is "Yes", the system',$0a,
 '# may crash while listening to music',$0a,
 '# SOUND_EFFECT=Yes',$0a,
 'SOUND_EFFECT=No',$0a,$0a,$00

->-------------------------------------------<-
PROC opendocument(filepath:PTR TO CHAR, packageCount=0)
DEF done=TRUE,
    readmefile,
    readmefilename[$100]:STRING,
    startline=0, 
    endline,
    currentline,
    pageCount, currentPage,
    gopage,
    selection = 0
    
    endline := recordsperpage
    readmefile := packageCount = 0
    
    IF NOT readmefile
        -> search.dat
        StrCopy(filepath, SEARCHFILENAME)
    ELSE
        -> readmefile
        -> totalline for readme file => packageCount
        
        packageCount:=0
        IF(fp:= Open(filepath, MODE_OLDFILE)) <> NIL
            WHILE (Fgets(fp, line, BUFFER/2)<>NIL)
                packageCount++
            ENDWHILE
            Close(fp)
        ENDIF
        
        
       MidStr(readmefilename, aminetFileReadme, 6)
       StrCopy(readmefilename, getfilenamewithoutext(readmefilename))
         
    
    ENDIF
    
    pageCount := packageCount / recordsperpage
    IF Mod(packageCount,recordsperpage)>0 THEN pageCount++ 

    IF(fp:= Open(filepath, MODE_OLDFILE)) <> NIL
    
        
        fillChar($8, 16)
        WriteF('\b')
        fillChar($20, 200)
        WriteF('\b')
        
        WHILE (done)
        
            currentline:=0
            
            Seek(fp, 0, OFFSET_BEGINNING)
            
            
            IF NOT readmefile
                WriteF('\e[1;31;40m    ID                           Name         Path   Size Date        Description\e[0;31;40m\n');
                WriteF('\e[1;31;40m------ ------------------------------ ------------ ------ ----------  -----------\e[0;31;40m\n');
            ELSE
                IF startline=0 THEN WriteF('\e[1;31;40m\s Readme File\e[0m\n', readmefilename)
                
            ENDIF
            
            
            WHILE (Fgets(fp, line, BUFFER/2)<>NIL)
                IF (currentline >= startline) AND (currentline < endline) THEN WriteF('\s', line)
                currentline++
            ENDWHILE
            
            sound(amiftp)
            currentPage:=(startline / recordsperpage)+1
            
            WriteF('\n')
            input:
            
            WriteF('\e[1;31;40m Page[\d/\d]\e[0m  \e[0;30;41m [P]rev \e[0m  \e[0;30;41m [N]ext \e[0m  \e[0;30;41m [G]o to Page \e[0m  \e[0;30;41m [Q]uit \e[0m  ', currentPage, pageCount);
            IF NOT readmefile THEN WriteF('\e[0;30;41m Type ID to select \e[0m');
            WriteF('\e[1;31;40m  Enter your choice ==> \e[0m ');
            
            
            ReadStr(stdout, choice) 
            StrCopy(choice, TrimStr(choice))
            LowerStr(choice)
            
            IF choice[0]=NIL
                //WriteF('\b')
                fillChar($8, 16)
                WriteF('\b')
                JUMP input
            ENDIF
            
            IF (choice[0]="n")
                IF (currentPage<pageCount)
                    startline += recordsperpage
                    endline := startline + recordsperpage
                    IF (endline > packageCount) THEN endline:=packageCount
                ELSE
                    fillChar($8, 16)
                    WriteF('\b')
                    JUMP input    
                ENDIF
                
            ELSEIF (choice[0]="p")
                    startline -= recordsperpage
                    endline := startline + recordsperpage
                    IF (startline < 0)
                        startline:=0
                        endline:=recordsperpage
                        
                        fillChar($8, 16)
                        WriteF('\b')
                        JUMP input
                    ENDIF
            ELSEIF (choice[0]="g")
                    IF pageCount<>1
                        WriteF('\n\e[1;31;40m Enter page number (1-\d) ==>\e[0m  ', pageCount)
                        ReadStr(stdout, choice)
                        gopage:=Val(choice)
                        
                        IF ((gopage>0) AND (gopage<=pageCount))
                            gopage--
                            startline := recordsperpage * gopage
                            endline := startline + recordsperpage
                            
                        ENDIF
                    ELSE
                        fillChar($8, 16)
                        WriteF('\b')
                        JUMP input
                    ENDIF
                    
            
            ELSEIF (choice[0]="q")
                    selection:=-1
                    done:=FALSE
                    
            ELSE
                    selection:=Val(choice)
                    IF((selection>0) AND (selection<=packageCount)) AND (NOT readmefile)
                        -> after searching, defines aminetPath and aminetFilename from fp
                        Seek(fp, 0, OFFSET_BEGINNING)
                        currentline:=1
                        WHILE (Fgets(fp, line, BUFFER/2)<>NIL)
                            IF (currentline = selection)
                                ->WriteF('\s\n', line)
                                MidStr(aminetFilename, line, 7, 30); StrCopy(aminetFilename, TrimStr(aminetFilename))
                                MidStr(aminetPath, line, 38, 12); StrCopy(aminetPath, TrimStr(aminetPath))
                                ->WriteF('*\s*\s*\n', aminetPath, aminetFilename)
                            ENDIF
                            currentline++
                        ENDWHILE
                        done:=FALSE
                    ELSE
                        fillChar($8, 16)
                        WriteF('\b')
                        JUMP input
                    ENDIF
            ENDIF
            
            WriteF('\b\c\b', $8)
            fillChar($20, 200)
            WriteF('\b\e[1;31;40m Page[\d/\d]\e[0m\n\n', currentPage, pageCount)
            
            
        ENDWHILE
        
        Close(fp)
    ENDIF
    
ENDPROC selection

->-------------------------------------------<-
PROC fillChar(c, length)
    DEF i
    FOR i:=0 TO length
        WriteF('\c', c)
    ENDFOR
ENDPROC

->-------------------------------------------<-
CHAR '$VER: ',VERSION,0 
