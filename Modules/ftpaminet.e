OPT MODULE
OPT OSVERSION=37
OPT PREPROCESS
 
MODULE 'socket_pragmas',
        'amitcp/sys/socket',
        'amitcp/sys/types',
        'amitcp/sys/time',
        'amitcp/netdb',
        'amitcp/netinet/in',
        'dos/dos',
        'dos',
        'oomodules/softtimer_oo',
        '*fileexist',
        '*makedir',
        '*playtone'
        
ENUM ERR_NOBSDSOCKET=$ff
ENUM CMD_FAIL=100, CMD_PASS, CMD_NOQUIT, CMD_FILENOTFOUND
ENUM ST_XFEROK=250, ST_TIMEOUT, ST_BREAK
CONST HYPHEN=25, SPACE=32

#define EXTRACTING      'Extracting from archive '
#define NOTFOUND        '\a not found on your system to extract package\n'
#define REFRESH         1

EXPORT OBJECT transfer
    remotepath
    filename
    localpath
    isreadme
    yes
    extract
    effect
ENDOBJECT

DEF sock,
    oku,
    xferport,
    res,
    xferfilelen,
    prefsxferbuffer,
    prefstimeout
    

EXPORT PROC download(tr:PTR TO transfer) HANDLE
    
    DEF sain:PTR TO sockaddr_in,
    hst:PTR TO hostent
    
    IF NOT initplay() THEN tr.effect:=0
    
    xferport:=5
    xferfilelen:=0
    prefsxferbuffer:=100
    prefstimeout:= 20
    oku:=-1
    IF tr.isreadme>0 THEN oku:=1
    
    IF (socketbase:=OpenLibrary('bsdsocket.library',NIL)) = NIL THEN Raise(ERR_NOBSDSOCKET)    
    
    IF (sock:=Socket(AF_INET, SOCK_STREAM,0))<>-1

        IF sain:=New(SIZEOF sockaddr_in)
            sain.family:=AF_INET
            IF hst:=Gethostbyname('aminet.net')
                CopyMem(Long(hst.addr_list), sain.addr, hst.length)
            ENDIF
        sain.port:=21
        ENDIF

        WriteF('\e[1;31;40mConnecting\e[0;31;40m to aminet.net (\s)\n', Inet_NtoA(sain.addr.addr))
        sound(tr)
        
        IF Connect(sock, sain, SIZEOF sockaddr_in)<>-1
            
            afterconnect(tr)
            freeplay()
        ELSE
            WriteF('Unable to connect\n')
        ENDIF

        CloseSocket(sock)
    ENDIF

    IF socketbase THEN CloseLibrary(socketbase)
    
EXCEPT
    SELECT exception
        CASE ERR_NOBSDSOCKET
            WriteF('Unable to open bsdsocket.library.\nPlease make sure your TCP/IP stack is running.\n')
    ENDSELECT
ENDPROC

->-------------------------------------------<-
PROC afterconnect(tr:PTR TO transfer)
    DEF myip,
        myipstr[50]:STRING,
        portstr[3]:STRING,
        quitflag=NIL

    myip:=Gethostid()
    StringF(myipstr,'\s',Inet_NtoA(myip))
    StrCopy(myipstr,ipwithcomma(myipstr))
    xferport:=xferport+1
    StringF(portstr,'\d',xferport)
    StrAdd(myipstr,',4,')
    StrAdd(myipstr,portstr)
    IF EstrLen(tr.remotepath)=0 THEN StrCopy(tr.remotepath,'.')
    
    IF ((quitflag:=senduser())=CMD_PASS)
    
        IF (sendpassword()=CMD_PASS)
    
            IF (cmdwritea('CWD ',tr.remotepath)=CMD_PASS) 
                IF (cmdwritea('TYPE ','I')=CMD_PASS) 
                    IF (cmdwritea('PORT ',myipstr)=CMD_PASS)
                        sendsize(tr)
    
                        starttransfer(tr)
    
                        logout()
                    ELSE
                        logout()
                    ENDIF
                ELSE
                    cmdwritea('QUIT','NOPAR')
                    logout()
                ENDIF
            ELSE
                logout()
            ENDIF
        ELSE
            logout()
        ENDIF
    ELSE
            IF quitflag<>CMD_NOQUIT
                logout()
            ENDIF
    ENDIF
ENDPROC

->-------------------------------------------<-
PROC logout()
    cmdwritea('QUIT','NOPAR')
ENDPROC

->-------------------------------------------<-
PROC ipwithcomma(ip:PTR TO CHAR)
    DEF ipstr[50]:STRING,
        x

    StrCopy(ipstr, ip)
    FOR x:=0 TO (EstrLen(ipstr)-1)
        IF ipstr[x]=46 THEN ipstr[x]:=44
    ENDFOR
ENDPROC ipstr

->-------------------------------------------<-
PROC reccmd()
    DEF buf[4096]:STRING,
        len,
        x[1]:STRING,
        readfds:fd_set,
        tv:timeval

    fd_zero(readfds)
    fd_set(sock,readfds)
    tv.sec:= prefstimeout
    tv.usec:=5

    IF WaitSelect(sock+1,readfds, NIL, NIL, tv, NIL)>0

        WHILE StrCmp(x,'\n')=FALSE
            len:=Recv(sock,x,1,0)
            StrAdd(buf,x)
        ENDWHILE

        StrCopy(buf,buf,EstrLen(buf)-2)
    ->ELSE
    ->    StrCopy(buf,'000 Reply from server Timed Out\n')
    ENDIF

ENDPROC buf

->-------------------------------------------<-
PROC sendsize(tr:PTR TO transfer)
    DEF sizexfer[500]:STRING,
        str[500]:STRING

    StringF(sizexfer,'SIZE \s\b\n',tr.filename)
    Send(sock,sizexfer,EstrLen(sizexfer),0)
    StrCopy(sizexfer,sizexfer,EstrLen(sizexfer)-2)
    str:=reccmd()

    IF StrCmp(str,'2',1)=TRUE
        MidStr(str,str,4,ALL)
        xferfilelen:=Val(str)
    ELSE
        xferfilelen:=0
    ENDIF

ENDPROC

->-------------------------------------------<-
PROC senduser()
    DEF str[4096]:STRING,
        rc[4]:STRING,
        un[500]:STRING,
        rec220=FALSE,
        rcnum,
        success

    WriteF('Connected\n\n')
    StringF(un,'USER \s', 'anonymous') -> username
    sendcommand(un)
    str:=reccmd()
    StrCopy(rc,str,4)
    rcnum:=Val(rc)

    SELECT 999 OF rcnum
        CASE 220
            rec220:=TRUE
            success:=CMD_PASS
        CASE 230, 332, 331
            success:=CMD_PASS
        CASE 421
            success:=CMD_NOQUIT
        DEFAULT
            success:=CMD_FAIL
    ENDSELECT

    IF success=CMD_PASS
        WHILE InStr(rc,'-',0) > FALSE -> Indicates more text
            str:=reccmd()
            StrCopy(rc,str,4)
        ENDWHILE

        IF rec220=TRUE
            str:=reccmd()
            StrCopy(rc,str,4)
            rcnum:=Val(rc)

            SELECT 999 OF rcnum
                CASE 220
                    rec220:=TRUE
                    success:=CMD_PASS
                CASE 230, 332, 331
                    success:=CMD_PASS
                CASE 421
                    success:=CMD_NOQUIT
                DEFAULT
                    success:=CMD_FAIL
            ENDSELECT

            WHILE InStr(rc,'-',0) > FALSE -> Indicates more text
                str:=reccmd()
                StrCopy(rc,str,4)
            ENDWHILE
        ENDIF
    ENDIF

ENDPROC success

->-------------------------------------------<-
PROC sendpassword()
    DEF str[4096]:STRING,
        rc[4]:STRING,
        pw[500]:STRING,
        success

    StringF(pw,'PASS \s', 'anonymous@amiget.net') -> Password
    sendcommand(pw)
    str:=reccmd()
    StrCopy(rc,str,4)

    IF StrCmp(rc,'230',3)=TRUE
        success:=CMD_PASS
    ELSE
        success:=CMD_FAIL
    ENDIF

    IF success=CMD_PASS
        WHILE StrCmp(rc,'230 ',4) = FALSE -> Indicates more text
            str:=reccmd()
            StrCopy(rc,str,4)
        ENDWHILE
    ENDIF
ENDPROC success

->-------------------------------------------<-
PROC cmdwritea(cmd:PTR TO CHAR, param:PTR TO CHAR)
    DEF str[4096]:STRING,
        rc[4]:STRING,
        command[500]:STRING,
        success

    StrCopy(command,cmd)

    IF StrCmp(param,'NOPAR',5)=TRUE
        sendcommand(command)
    ELSE
        StrAdd(command,param)
        sendcommand(command)
    ENDIF

    StrCopy(str,reccmd())
    StrCopy(rc, str, 4)

    IF rc[3]=HYPHEN
        rc[3]:=SPACE
        REPEAT 
            StrCopy(str, reccmd())
        UNTIL StrCmp(str,rc, 4)=TRUE
    ENDIF

    IF StrCmp(rc,'200',1)=TRUE
        success:=CMD_PASS
    ELSE
        success:=CMD_FAIL
    ENDIF
ENDPROC success

->-------------------------------------------<-
PROC sendcommand(cmd:PTR TO CHAR)
    DEF len=0,
        cmdstring[200]:STRING

    StrCopy(cmdstring,cmd) -> Converts the string to an E String
    StrAdd(cmdstring,'\b\n') -> Appends <CR/LF>
    len:=EstrLen(cmdstring) -> Returns the string length inc <CR/LF>
    Send(sock,cmdstring,len,MSG_WAITALL) -> Sends string through socket
ENDPROC

->-------------------------------------------<-
PROC starttransfer(tr:PTR TO transfer)
    DEF my_addr:PTR TO sockaddr_in,
        sockfd,
        new_fd,
        fh,
        path_filename[500]:STRING,
        cpsstr[50]:STRING,
        cpsrecv=0,
        buffer,
        lenreceived,
        readfds:fd_set,
        tv:timeval,
        timerec=1,
        yuzde=0, breadme=1024,
        x,
        ret[5]:STRING,
        progress[26]:STRING,
        cmdStr[500]:STRING,
        comment[80]:STRING,
        st:PTR TO softtimer
        
        
    NEW st.softtimer()
    res:=NIL    
    
    StrCopy(progress, '                         ')
    ->xferfilelen:=xferfilelen/1024 -> Set filelength to KB
    IF (tr.localpath[StrLen(tr.localpath)-1])<>":" THEN StrAdd(tr.localpath, '/')
    StringF(path_filename,'\s\s',tr.localpath,tr.filename) -> Setup local path

    -> Set up file xfersocket
    my_addr:=New(SIZEOF sockaddr_in)
    my_addr.family:=AF_INET
    my_addr.addr.addr:=INADDR_ANY
    my_addr.port:=xferport+1024

    IF (sockfd:=Socket(AF_INET, SOCK_STREAM,0))<>-1
        IF (Bind(sockfd, my_addr, SIZEOF sockaddr_in))=-1
            WriteF('Bind Associated Error\nTry \aamiget -D\a to download or \aamiget -R\a to display readme file again\n')
        ELSE
            IF (Listen(sockfd,5))=-1
                WriteF('Listen Associated Error\n')
            ELSE
                cpsrecv:=resume(path_filename)
                IF (cmdwriteb('RETR ', tr.filename))=CMD_PASS
                    IF (new_fd:=Accept(sockfd,NIL,NIL))=-1
                        WriteF('Accept Associated Error\n')
                    ELSE
                        IF (fh:=Open(path_filename,MODE_READWRITE))=NIL
                            WriteF('Unable to save file \a\s\a\n', path_filename)
                        ELSE
                            Seek(fh,NIL,OFFSET_END)
                            buffer:=New(prefsxferbuffer*1024) -> Set up receive buffer
                            
                            IF tr.isreadme=0 THEN WriteF('\tPackage  Name:\t\s\n\tDownload Size:\t\c\d KiB (\d Bytes)\n\n', tr.filename, $7e, xferfilelen/1024, xferfilelen)
                            
                            -> -y' skip proceed
                            IF tr.yes=0 
                                WriteF('Proceed to download? [Y/n] ')
                                ReadStr(stdout, ret)
                                StrCopy(ret, TrimStr(ret))
                                IF ((ret[0]="n") OR (ret[0]="N")) THEN JUMP skipdownload
                            ENDIF    
                                
                            WriteF('\e[1;31;40mRetrieving\e[0;31;40m ')
                            IF tr.isreadme=0 
                                WriteF('package')
                            ELSE
                                WriteF('readme file')
                            ENDIF
                            WriteF('...\n')
                            
                            fd_zero(readfds)
                            fd_set(new_fd,readfds)
                            tv.sec:=prefstimeout
                            tv.usec:=5

                            ->Start Timer off for REFRESH seconds
                            st.startTimer(REFRESH)
                            StrCopy(cpsstr, '?? KiB/s')
                            IF ((oku>=0) OR (xferfilelen<1024)) THEN breadme:=1
                            WHILE res<1
                                
                                IF (WaitSelect(new_fd+1,readfds, NIL, NIL, tv, NIL))=0
                                    res:=ST_TIMEOUT
                                ELSE
                                    IF (lenreceived:=Recv(new_fd,buffer,prefsxferbuffer*1024,0))>0
                                        
                                        timerec:=timerec+lenreceived

                                        ->When time request run out,
                                        ->calculate CPS then send another
                                        IF st.getTimerMsg()=TRUE
                                            timerec:=Div(timerec, REFRESH)
                                            StringF(cpsstr, '\d KiB/s', timerec/1024)
                                            timerec:=1
                                            st.waitAndRestart(REFRESH)
                                        ENDIF

                                        Write(fh,buffer,lenreceived)
                                        cpsrecv:=(cpsrecv+lenreceived)
                                        

                                        yuzde:=((cpsrecv/breadme)*100)/(xferfilelen/breadme)

                                        IF (oku<0) AND (xferfilelen>(50*1024)) -> No progress info to download readme files and download size < 50KB 
                                            FOR x:= 0 TO (yuzde/(100/StrLen(progress)))-1
                                                progress[x]:="-"
                                            ENDFOR
                                            progress[x-1]:=$BB
                                            
                                            WriteF('\b\e[1;31;40m\s[32]\e[0;31;40m \e[1;30;41m\s\e[0;31;40m \d[3]% \d[6] KiB  \s', tr.filename, progress, yuzde, cpsrecv/1024, cpsstr)
                                        ENDIF

                                        fd_zero(readfds)
                                        fd_set(new_fd,readfds)
                                        tv.sec:=prefstimeout
                                        tv.usec:=5
                                    ELSE
                                        res:=ST_XFEROK
                                    ENDIF
                                ENDIF
                            
                            ENDWHILE
                            st.stopTimer()
                            WriteF('\n')
                            
                            skipdownload:
                            Close(fh)
                            
                            IF FileLength(path_filename)<(xferfilelen)
                                res:= ST_BREAK
                            ENDIF
                                                      
                            SELECT res
                                CASE ST_BREAK
                                    WriteF('File received is shorter than expected length, file may be corrupt!\n')
                                    WriteF('Or current task is aborted by user to regain user control so try again same command to resume.\n')
                                
                                CASE ST_TIMEOUT
                                    WriteF('File Transfer Timed Out\n')
                                CASE ST_XFEROK
                                    IF tr.isreadme=0 
                                        WriteF('\e[1;31;40mSaved\e[0;31;40m to \a\s\a\n', path_filename)
                                        -> set comment for downloaded file
                                        StringF(comment,'Downloaded from aminet.net/\s/\s by Amiget', tr.remotepath, tr.filename)
                                        SetComment(path_filename, comment)
                                    ENDIF
                                    
                                    -> Extract
                                    IF tr.extract>0 
                                        
                                        -> LHA
                                        runProcess('SYS:C/lha', '.lha', 'lha -F x \s \s', path_filename)
                                        -> TAR.GZ
                                        runProcess('SYS:C/untgz', '.tar.gz', 'untgz \s \s', path_filename)
                                        -> ZIP
                                        runProcess('SYS:C/unzip', '.zip', 'unzip \s -d \s', path_filename)
                                        -> ADF for OS3.2 only
                                        IF (InStr(path_filename, '.adf')<>-1)
                                            IF fileExist('SYS:C/dacontrol')
                                                WriteF('\e[1;31;40mThe \a\s\a\e[0;31;40m file was mounted on the DA0:\n', path_filename)
                                                StringF(cmdStr, 'dacontrol load \s device DA0:',path_filename)
                                                Execute(cmdStr, NIL, NIL)   
                                            ENDIF
                                        ENDIF
                                        
                                    ENDIF
                                    
                                    -> open drawer using rexx
                                    IF ((fileExist('SYS:Rexxc/RX'))OR(fileExist('SYS:C/RX')) AND (tr.isreadme=0))
                                        StringF(cmdStr, 'Run <>NIL: rx "ADDRESS workbench WINDOW \a\s\a OPEN"', tr.localpath)
                                        Execute(cmdStr, NIL, NIL)
                                    ENDIF
                                    sound(tr)
                            ENDSELECT
                            
                        ENDIF
                    ENDIF
                ELSE -> Jump here if file not found
                    WriteF('File Transfer Error\n')
                    res:=CMD_FILENOTFOUND
                ENDIF
            ENDIF -> Jump here if listen fails
        ENDIF -> Jump here if Bind fails
            CloseSocket(sockfd)
            CloseSocket(new_fd)
    ELSE -> Jump here if socket opening fails
        WriteF('Socket Error\n')
    ENDIF
    Dispose(buffer)
ENDPROC

->-------------------------------------------<-
PROC resume(fileandpath:PTR TO CHAR)
    DEF filelen,
        filelenstr[50]:STRING

    IF (filelen:=FileLength(fileandpath))<0
    ELSE
        StringF(filelenstr,'\d',filelen)
        cmdwritec('REST ',filelenstr)
    ENDIF

    IF filelen=-1 THEN filelen:=0
ENDPROC filelen

->-------------------------------------------<-
PROC cmdwriteb(cmd:PTR TO CHAR, param:PTR TO CHAR)
    DEF str[4096]:STRING,
        rc[4]:STRING,
        command[500]:STRING,
        success

    StrCopy(command,cmd)

    IF StrCmp(param,'NOPAR',5)=TRUE
        sendcommand(command)
    ELSE
        StrAdd(command,param)
        sendcommand(command)
    ENDIF

    StrCopy(str,reccmd())
    StrCopy(rc,str,4)

    IF rc[3]=HYPHEN
        rc[3]:=SPACE
        REPEAT
            StrCopy(str, reccmd())
        UNTIL StrCmp(str, rc, 4)=TRUE
    ENDIF

    IF StrCmp(rc,'2',1)=TRUE
        success:=CMD_PASS
    ELSE
        success:=CMD_FAIL
    ENDIF

    IF StrCmp(rc,'501',3)= TRUE THEN success:=CMD_FILENOTFOUND
    IF StrCmp(rc,'1',1)=TRUE THEN success:=CMD_PASS
ENDPROC success

->-------------------------------------------<-
PROC cmdwritec(cmd:PTR TO CHAR, param:PTR TO CHAR)
    DEF str[4096]:STRING,
        rc[4]:STRING,
        command[500]:STRING,
        success

    StrCopy(command,cmd)

    IF StrCmp(param,'NOPAR',5)=TRUE
        sendcommand(command)
    ELSE
        StrAdd(command,param)
        sendcommand(command)
    ENDIF

    StrCopy(str,reccmd())
    StrCopy(rc,str,4)

    IF rc[3]=HYPHEN
        rc[3]:=SPACE
        REPEAT
            StrCopy(str, reccmd())
        UNTIL StrCmp(str, rc, 4)=TRUE
    ENDIF

    IF StrCmp(rc,'200',1)=TRUE
        success:=CMD_PASS
    ELSE
        success:=CMD_FAIL
    ENDIF

    IF StrCmp(rc,'3',1)=TRUE THEN success:=CMD_PASS
ENDPROC success

->-------------------------------------------<-
EXPORT PROC sound(tr:PTR TO transfer)
    IF tr.effect>0 
        play(930,2)
        play(960,1)
        play(1000,3)
    ENDIF
ENDPROC

->-------------------------------------------<-
EXPORT PROC getfilenamewithoutext(fname:PTR TO CHAR)
    DEF i
    FOR i:=StrLen(fname)-1 TO 0 STEP -1
        IF fname[i]="." THEN EXIT(TRUE)
    ENDFOR
    StrCopy(fname, fname, i)
    
ENDPROC fname

->-------------------------------------------<-
PROC runProcess(appPath:PTR TO CHAR, ext:PTR TO CHAR, withArguments:PTR TO CHAR, pf)
    DEF extPath[500]:STRING,
        cmd[500]:STRING
    
    IF InStr(pf, ext)<>-1
    
        StrCopy(extPath, pf)
        StrCopy(extPath, extPath, StrLen(extPath)-StrLen(ext))
        StrAdd(extPath, '/')
        mkdir(extPath)
    
        IF fileExist(appPath)
            WriteF('\e[1;31;40m\s\e[0;31;40m\a\s\a\n',EXTRACTING, pf)
            StringF(cmd, withArguments, pf, extPath)
            Execute(cmd, NIL, NIL)   
        ELSE
            WriteF('\a\e[1;31;40m\s\e[0;31;40m\s', appPath, NOTFOUND)
        ENDIF
        
    ENDIF
ENDPROC