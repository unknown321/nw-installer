Name ${APPNAME}
OutFile ${OUTFILE}
RequestExecutionLevel admin

PageEx license
    LicenseData LICENSE.txt
PageExEnd
Page custom connectUSB connectUSBLeave ": connect device"
Page components
Page custom reviewPage "" ": review"
Page instfiles

!include LogicLib.nsh
!include dvdfunc.nsh
!include nsDialogs.nsh
!include sections.nsh

Var USBLetter
Var USBLabel
Var A50text
Var A40text
Var A30text
Var WM1AZtext
Var ZX300text
Var DMPZ1text
Var A50Ztext

!define GetUSB "!insertmacro _GetUSB"
!define GetUSBLabel "!insertmacro _GetUSBLabel"

# usb devices on windows linger for a while
# you can disconnect your drive after detecting and it still will be picked up
# you can see them in device manager -> show hidden devices
!macro _GetUSB
  Push $USBLetter
  Call DVD_GetNextDrive
  Pop $1
  StrCpy $USBLetter $1
!macroend

!macro _GetUSBLabel arg1
  Push "${arg1}"
  Call DVD_GetLabel
  Pop $1
  StrCpy $USBLabel $1
!macroend

!include nsDialogs.nsh
var Label
Var Dialog
Var ImageCtrl1
Var BmpHandle1
Var ImageCtrl2
Var BmpHandle2

Function connectUSB
	nsDialogs::Create 1018
	Pop $Dialog

	${If} $Dialog == error
		Abort
	${EndIf}

	${NSD_CreateBitmap} 0 20 100% 100% ""
	Pop $ImageCtrl1
	${NSD_SetBitmap} $ImageCtrl1 $PLUGINSDIR\device.bmp $BmpHandle1

    ${NSD_CreateBitmap} 0 125 100% 100% ""
    Pop $ImageCtrl2
    ${NSD_SetBitmap} $ImageCtrl2 $PLUGINSDIR\explorer.bmp $BmpHandle2

    ${NSD_CreateLabel} 0 0 100% 32u "Connect usb device, turn on USB Mass storage and click 'Next'"
    Pop $Label

	nsDialogs::Show

	${NSD_FreeBitmap} $BmpHandle1
	${NSD_FreeBitmap} $BmpHandle2
FunctionEnd

Function connectUSBLeave
    GetDlgItem $0 $hWndParent 1
    EnableWindow $0 0

    Var /GLOBAL counter
    StrCpy $counter 0

    GetLetter:
        ${GetUSB}
        IntOp $counter $counter + 1

        # loop through 10 removable drives
        ${If} $counter >= 10
            IntOp $counter $counter * 0
            MessageBox MB_OKCANCEL "Please connect the device and click OK" IDOK GetLetter IDCANCEL 0
            Abort
        ${EndIf}

        ${If} $USBLetter == ""
            goto GetLetter
        ${Else}
            goto GetLabel
        ${EndIf}

    GetLabel:
        ${GetUSBLabel} $USBLetter
        ${If} $USBLabel == "WALKMAN"
            goto End
        ${Else}
            goto GetLetter
        ${EndIf}

    End:
        GetDlgItem $0 $hWndParent 1
        EnableWindow $0 1
FunctionEnd

var letterWithoutSlash
Function reviewPage
    nsDialogs::Create 1018
    ${NSD_CreateLabel} 0 0 100% 32u "Installing on $USBLetter, '$USBLabel'"
    Pop $Label
    nsDialogs::Show

    StrCpy $OUTDIR "$USBLetter"

    StrCpy $letterWithoutSlash $USBLetter 2
FunctionEnd

Section "!Currently installed firmware"
  SectionIn RO
SectionEnd

    section /o "WalkmanOne" FWWOne
        File "./walkmanOne/NW_WM_FW.UPG"
    sectionEnd

    section /o $A50text A50Stock
        File "./nw-a50/NW_WM_FW.UPG"
    sectionEnd

    section /o $A40text A40Stock
        File "./nw-a40/NW_WM_FW.UPG"
    sectionEnd

    section /o $A30text A30Stock
        File "./nw-a30/NW_WM_FW.UPG"
    sectionEnd

    section /o $A50Ztext A50Zmod
        File "./a50z/NW_WM_FW.UPG"
    sectionEnd

    section /o $WM1AZtext WM1AZStock
        File "./nw-wm1a/NW_WM_FW.UPG"
    sectionEnd

     section /o $ZX300text ZX300Stock
         File "./nw-zx300/NW_WM_FW.UPG"
     sectionEnd

     section /o $DMPZ1text DMPZ1Stock
         File "./dmp-z1/NW_WM_FW.UPG"
     sectionEnd

var selectGroupAction

Section "!Action"
  SectionIn RO
SectionEnd

    section "Install" ACTION_INSTALL
        File "../userdata.tar.gz"
    sectionEnd

    section "Remove" ACTION_UNINSTALL
        File "/oname=userdata.tar.gz" "../userdata.uninstaller.tar.gz"
    sectionEnd

    section ""
        File "/oname=$PLUGINSDIR\scsitool-nwz-v27.exe" "scsitool-nwz-v27.exe"
        # how did it work on nw-a40 and nw-zx300?
        ExecWait '"$PLUGINSDIR\scsitool-nwz-v27.exe" -d -s nw-a50 $letterWithoutSlash do_fw_upgrade'
    sectionEnd

var selectGroup

Function .onSelChange

!insertmacro StartRadioButtons $selectGroup
    !insertmacro RadioButton ${A50Stock}
    !insertmacro RadioButton ${A40Stock}
    !insertmacro RadioButton ${A30Stock}
    !insertmacro RadioButton ${FWWOne}
    !insertmacro RadioButton ${A50Zmod}
    !insertmacro RadioButton ${WM1AZStock}
    !insertmacro RadioButton ${ZX300Stock}
    !insertmacro RadioButton ${DMPZ1Stock}
!insertmacro EndRadioButtons

!insertmacro StartRadioButtons $selectGroupAction
    !insertmacro RadioButton ${ACTION_INSTALL}
    !insertmacro RadioButton ${ACTION_UNINSTALL}
!insertmacro EndRadioButtons
FunctionEnd

Function .onInit
    StrCpy $USBLetter ""
    StrCpy $USBLabel ""

    UserInfo::GetAccountType
    pop $0
    ${If} $0 != "admin" ;Require admin rights on NT4+
        MessageBox mb_iconstop "Administrator rights required!"
        SetErrorLevel 740 ;ERROR_ELEVATION_REQUIRED
        Quit
    ${EndIf}

    InitPluginsDir
    File /oname=$PLUGINSDIR\device.bmp "device.bmp"
    File /oname=$PLUGINSDIR\explorer.bmp "explorer.bmp"

    SectionSetFlags ${ACTION_INSTALL} 1
    SectionSetFlags ${ACTION_UNINSTALL} 0
    StrCpy $selectGroupAction ${ACTION_INSTALL}

    SectionSetFlags ${A50Stock} 1
    SectionSetFlags ${A40Stock} 0
    SectionSetFlags ${A30Stock} 0
    SectionSetFlags ${FWWOne} 0
    SectionSetFlags ${A50Zmod} 0
    SectionSetFlags ${WM1AZStock} 0
    SectionSetFlags ${ZX300Stock} 0
    SectionSetFlags ${DMPZ1Stock} 0
    StrCpy $selectGroup ${A50Stock}

    StrCpy $A50text ""
    StrCpy $A40text ""
    StrCpy $A30text ""
    StrCpy $WM1AZtext ""
    StrCpy $ZX300text ""
    StrCpy $DMPZ1text ""
    StrCpy $A50Ztext ""

    ${If} ${A40} != 0
        ${If} ${A40MOD_ONLY} == 1
            StrCpy $A40text "NW-A40 with A50 mod only"
        ${Else}
            StrCpy $A40text "NW-A40 (or A50 mod)"
        ${EndIf}
    ${EndIf}

    ${If} ${A30} != 0
        StrCpy $A30text "NW-A30"
    ${EndIf}

    ${If} ${A50} != 0
        StrCpy $A50text "NW-A50"
    ${EndIf}

    ${If} ${WM1AZ} != 0
        StrCpy $WM1AZtext "NW-WM1A/Z"
    ${EndIf}

    ${If} ${ZX300} != 0
        StrCpy $ZX300text "NW-ZX300"
    ${EndIf}

    ${If} ${DMPZ1} != 0
        StrCpy $DMPZ1text "DMP-Z1"
    ${EndIf}

    ${If} ${A50Z} != 0
        StrCpy $A50Ztext "NW-A50 with A50Z mod"
    ${EndIf}

FunctionEnd
