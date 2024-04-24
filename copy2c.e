/*
Coded by emarti, Murat Ozdemir (March 29, 2024)
*/

OPT OSVERSION=37
OPT MODULE

MODULE 'dos', 'dos/dos'

EXPORT PROC copyToC()

    copyfile('amiget')
    copyfile('amiget.info')
    copyfile('amisearch')
    copyfile('amisearch.info')

ENDPROC

PROC copyfile(file)
    DEF cmd[100]:STRING
    StringF(cmd, 'Copy \s to SYS:C >NIL:', file)
    Execute(cmd, NIL, NIL)
ENDPROC
