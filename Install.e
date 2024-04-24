OPT OSVERSION=37
OPT PREPROCESS

MODULE 'window','classes/window',
      'gadgets/layout','layout',
      'libraries/gadtools','gadtools',
      'icon',
      'button','gadgets/button',
      'space',
      'label','images/label',
      'bitmap','images/bitmap',
      'images/bevel',
      'amigalib/boopsi',
      'intuition/intuition',
      'intuition/imageclass',
      'intuition/screens',
      'intuition/gadgetclass',
      '*copy2c',
      'reaction/reaction_macros',
      'reaction/reaction_lib'
      
#define VERSION 'Amiget Installer v1.0 (29.03.2024)'

->InstallWindow gadgets
ENUM LAYOUT_5, SPACE_6, LAYOUT_8, SPACE_9, BITMAP_11, BITMAP_12, BITMAP_13, 
  SPACE_14, LAYOUT_22, SPACE_26, LABEL_23, SPACE_24, LABEL_25, 
  SPACE_27, LAYOUT_33, BUTTON_34, LAYOUT_35, LABEL_21

DEF gScreen=0,gVisInfo=0,gDrawInfo=0,gAppPort=0

DEF mainGadgets[19]:ARRAY OF LONG

PROC setup()
  IF (windowbase:=OpenLibrary('window.class',0))=NIL THEN Throw("LIB","win")
  IF (layoutbase:=OpenLibrary('gadgets/layout.gadget',0))=NIL THEN Throw("LIB","layo")
  IF (gadtoolsbase:=OpenLibrary('gadtools.library',0))=NIL THEN Throw("LIB","gadt")
  IF (iconbase:=OpenLibrary('icon.library',0))=NIL THEN Throw("LIB","icon")
  IF (buttonbase:=OpenLibrary('gadgets/button.gadget',0))=NIL THEN Throw("LIB","btn")
  IF (spacebase:=OpenLibrary('gadgets/space.gadget',0))=NIL THEN Throw("LIB","spce")
  IF (labelbase:=OpenLibrary('images/label.image',0))=NIL THEN Throw("LIB","labl")
  IF (bitmapbase:=OpenLibrary('images/bitmap.image',0))=NIL THEN Throw("LIB","bmap")
  IF (gScreen:=LockPubScreen(NIL))=NIL THEN Raise("pub")
  IF (gVisInfo:=GetVisualInfoA(gScreen, [TAG_END]))=NIL THEN Raise("visi")
  IF (gDrawInfo:=GetScreenDrawInfo(gScreen))=NIL THEN Raise("dinf")
  IF (gAppPort:=CreateMsgPort())=NIL THEN Raise("port")
ENDPROC

PROC cleanup()
  IF gVisInfo THEN FreeVisualInfo(gVisInfo)
  IF gDrawInfo THEN FreeScreenDrawInfo(gScreen,gDrawInfo)
  IF gAppPort THEN DeleteMsgPort(gAppPort)
  IF gScreen THEN UnlockPubScreen(NIL,gScreen)

  IF gadtoolsbase THEN CloseLibrary(gadtoolsbase)
  IF iconbase THEN CloseLibrary(iconbase)
  IF windowbase THEN CloseLibrary(windowbase)
  IF layoutbase THEN CloseLibrary(layoutbase)
  IF buttonbase THEN CloseLibrary(buttonbase)
  IF spacebase THEN CloseLibrary(spacebase)
  IF labelbase THEN CloseLibrary(labelbase)
  IF bitmapbase THEN CloseLibrary(bitmapbase)
ENDPROC

PROC runWindow(windowObject:PTR TO LONG) HANDLE
  DEF running=TRUE
  DEF win:PTR TO window,wsig,code,msg,sig,result

  IF (win:=RA_OpenWindow(windowObject))
    GetAttr( WINDOW_SIGMASK, windowObject, {wsig} )
    

    WHILE running
      sig:=Wait(wsig)
      IF (sig AND (wsig))
        WHILE ((result:=RA_HandleInput(windowObject,{code}+2)) <> WMHI_LASTMSG)
          msg:=(result AND WMHI_CLASSMASK)
          SELECT msg
            CASE WMHI_CLOSEWINDOW
              running:=FALSE
            CASE WMHI_GADGETUP
              copyToC()
              SetGadgetAttrsA(mainGadgets[BUTTON_34], win, NIL,[GA_TEXT, 'Installation successful!', BUTTON_TEXTPEN, 2, BUTTON_BACKGROUNDPEN, 0, GA_READONLY, TRUE, BUTTON_BEVELSTYLE, BVS_NONE, TAG_DONE])
          ENDSELECT
        ENDWHILE
      ENDIF
    ENDWHILE
  ENDIF
EXCEPT DO
  RA_CloseWindow(windowObject)
ENDPROC

PROC installwindow() HANDLE
  DEF windowObject

  windowObject:=WindowObject,
    WA_TITLE, 'Amiget Installer',
    WA_SCREENTITLE, 'Amiget Installer',
    WA_LEFT, 5,
    WA_TOP, 20,
    WA_WIDTH, 320,
    WA_HEIGHT, 240,
    WA_MINWIDTH, 150,
    WA_MINHEIGHT, 80,
    WA_MAXWIDTH, 8192,
    WA_MAXHEIGHT, 8192,
    WINDOW_LOCKWIDTH, TRUE,
    WINDOW_LOCKHEIGHT, TRUE,
    WINDOW_APPPORT, gAppPort,
    WA_CLOSEGADGET, TRUE,
    WA_DEPTHGADGET, TRUE,
    WA_DRAGBAR, TRUE,
    WA_ACTIVATE, TRUE,
    WINDOW_POSITION, WPOS_CENTERWINDOW,
    WINDOW_ICONTITLE, 'Amiget Installer',
    WA_SMARTREFRESH, TRUE,
    WA_IDCMP, IDCMP_GADGETDOWN OR IDCMP_GADGETUP OR IDCMP_CLOSEWINDOW,
    WINDOW_PARENTGROUP, VLayoutObject,
    LAYOUT_SPACEOUTER, TRUE,
    LAYOUT_DEFERLAYOUT, TRUE,
      LAYOUT_ADDCHILD, mainGadgets[LAYOUT_5]:=LayoutObject,
        GA_ID, LAYOUT_5,
        LAYOUT_ORIENTATION, LAYOUT_ORIENT_VERT,
        LAYOUT_LABELPLACE, BVJ_IN_CENTER,
        LAYOUT_ADDCHILD, mainGadgets[SPACE_6]:=SpaceObject,
          GA_ID, SPACE_6,
        SpaceEnd,
        LAYOUT_ADDCHILD, mainGadgets[LAYOUT_8]:=LayoutObject,
          GA_ID, LAYOUT_8,
          LAYOUT_ORIENTATION, LAYOUT_ORIENT_HORIZ,
          LAYOUT_ADDCHILD, mainGadgets[SPACE_9]:=SpaceObject,
            GA_ID, SPACE_9,
          SpaceEnd,
          LAYOUT_ADDIMAGE, mainGadgets[BITMAP_11]:=BitMapObject,
            GA_ID, BITMAP_11,
            IA_LEFT, 0,
            IA_TOP, 0,
            IA_WIDTH, 0,
            IA_HEIGHT, 0,
            BITMAP_SCREEN, gScreen,
            BITMAP_SOURCEFILE, 'amiget.info',
          BitMapEnd,
          LAYOUT_ADDIMAGE, mainGadgets[BITMAP_12]:=BitMapObject,
            GA_ID, BITMAP_12,
            IA_LEFT, 0,
            IA_TOP, 0,
            IA_WIDTH, 0,
            IA_HEIGHT, 0,
            BITMAP_SCREEN, gScreen,
            BITMAP_SOURCEFILE, 'Install.info',
          BitMapEnd,
          LAYOUT_ADDIMAGE, mainGadgets[BITMAP_13]:=BitMapObject,
            GA_ID, BITMAP_13,
            IA_LEFT, 0,
            IA_TOP, 0,
            IA_WIDTH, 0,
            IA_HEIGHT, 0,
            BITMAP_SCREEN, gScreen,
            BITMAP_SOURCEFILE, 'System:C.info',
          BitMapEnd,
          LAYOUT_ADDCHILD, mainGadgets[SPACE_14]:=SpaceObject,
            GA_ID, SPACE_14,
          SpaceEnd,
        LayoutEnd,
        LAYOUT_ADDCHILD, mainGadgets[LAYOUT_22]:=LayoutObject,
          GA_ID, LAYOUT_22,
          LAYOUT_ORIENTATION, LAYOUT_ORIENT_HORIZ,
          LAYOUT_HORIZALIGNMENT, LALIGN_RIGHT,
          LAYOUT_ADDCHILD, mainGadgets[SPACE_26]:=SpaceObject,
            GA_ID, SPACE_26,
          SpaceEnd,
          LAYOUT_ADDIMAGE, mainGadgets[LABEL_23]:=LabelObject,
            GA_ID, LABEL_23,
            LABEL_DRAWINFO, gDrawInfo,
            LABEL_TEXT, 'Amiget',
            LABEL_JUSTIFICATION, LJ_RIGHT,
          LabelEnd,
          LAYOUT_ADDCHILD, mainGadgets[SPACE_24]:=SpaceObject,
            GA_ID, SPACE_24,
          SpaceEnd,
          LAYOUT_ADDIMAGE, mainGadgets[LABEL_25]:=LabelObject,
            GA_ID, LABEL_25,
            LABEL_DRAWINFO, gDrawInfo,
            LABEL_TEXT, ' SYS:C',
          LabelEnd,
          LAYOUT_ADDCHILD, mainGadgets[SPACE_27]:=SpaceObject,
            GA_ID, SPACE_27,
          SpaceEnd,
        LayoutEnd,
        LAYOUT_ADDCHILD, mainGadgets[LAYOUT_33]:=LayoutObject,
          GA_ID, LAYOUT_33,
          LAYOUT_ORIENTATION, LAYOUT_ORIENT_VERT,
          LAYOUT_LEFTSPACING, 16,
          LAYOUT_RIGHTSPACING, 16,
          LAYOUT_TOPSPACING, 8,
          LAYOUT_BOTTOMSPACING, 8,
          LAYOUT_ADDCHILD, mainGadgets[BUTTON_34]:=ButtonObject,
            GA_ID, BUTTON_34,
            GA_TEXT, 'Install',
            GA_RELVERIFY, TRUE,
            GA_TABCYCLE, TRUE,
            BUTTON_TEXTPEN, 1,
            BUTTON_BACKGROUNDPEN, 3,
            BUTTON_FILLTEXTPEN, 1,
            BUTTON_FILLPEN, 3,
          ButtonEnd,
        LayoutEnd,
        LAYOUT_ADDCHILD, mainGadgets[LAYOUT_35]:=LayoutObject,
          GA_ID, LAYOUT_35,
          LAYOUT_ORIENTATION, LAYOUT_ORIENT_VERT,
          LAYOUT_HORIZALIGNMENT, LALIGN_RIGHT,
          LAYOUT_TOPSPACING, 8,
          LAYOUT_ADDIMAGE, mainGadgets[LABEL_21]:=LabelObject,
            GA_ID, LABEL_21,
            LABEL_DRAWINFO, gDrawInfo,
            LABEL_TEXT, 'Amiget V1.0 (29.03.2024)',
            LABEL_JUSTIFICATION, LJ_CENTER,
          LabelEnd,
        LayoutEnd,
      LayoutEnd,
    LayoutEnd,
  WindowEnd  
  mainGadgets[18]:=0

  runWindow(windowObject)

EXCEPT DO
  IF windowObject THEN DisposeObject(windowObject);
ENDPROC

PROC main() HANDLE
  setup()
  installwindow()
EXCEPT DO
  cleanup()
ENDPROC

CHAR '$VER: ',VERSION,0 
