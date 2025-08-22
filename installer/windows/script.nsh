Name ${APPNAME}
OutFile ${OUTFILE}
RequestExecutionLevel admin

PageEx license
    LicenseData LICENSE.txt
PageExEnd
Page custom actionEnter "" ": select action"
Page custom selectDevice "" ": select device"
Page custom hasw1 "" ": Walkman One installed?"
Page custom considerBackup "" ": consider backup"
Page custom connectUSB connectUSBLeave ": connect device"
Page custom reviewPage "" ": review"
Page instfiles

!include LogicLib.nsh
!include dvdfunc.nsh
!include nsDialogs.nsh
!include sections.nsh

!macro NSD_SetUserData hwnd data
	nsDialogs::SetUserData ${hwnd} ${data}
!macroend
!define NSD_SetUserData `!insertmacro NSD_SetUserData`

!macro NSD_GetUserData hwnd outvar
	nsDialogs::GetUserData ${hwnd}
	Pop ${outvar}
!macroend
!define NSD_GetUserData `!insertmacro NSD_GetUserData`

Var USBLetter
Var USBLabel
var backupURL
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

Var Label
Var Dialog
Var ImageCtrl1
Var BmpHandle1
Var ImageCtrl2
Var BmpHandle2
Var hwnd
Var SelectedAction

Function actionEnter
	nsDialogs::Create 1018
	Pop $Dialog

	${If} $Dialog == error
		Abort
	${EndIf}

    ${NSD_CreateLabel} 0 0 100% 6% "Select action:"

    ${NSD_CreateRadioButton} 0 12% 40% 6% "Install"
        Pop $hwnd
        ${NSD_SetState} $hwnd 1
        ${NSD_AddStyle} $hwnd ${WS_GROUP}
        ${NSD_SetUserData} $hwnd 1
        ${NSD_OnClick} $hwnd actionClick

    ${NSD_CreateRadioButton} 0 20% 40% 6% "Uninstall"
        Pop $hwnd
		${NSD_SetUserData} $hwnd 0
		${NSD_OnClick} $hwnd actionClick

	nsDialogs::Show
FunctionEnd

Function actionClick
	Pop $hwnd
	${NSD_GetUserData} $hwnd $SelectedAction
FunctionEnd


var SelectedDevice
var heightOffset
var heightOffsetPercent
Var A40text
Var A30text
Function selectDevice
	nsDialogs::Create 1018
	Pop $Dialog

	${If} $Dialog == error
		Abort
	${EndIf}

    ${NSD_CreateLabel} 0 0 100% 6% "Select device:"

    StrCpy $heightOffset 12
    StrCpy $heightOffsetPercent "$heightOffset%"
    ${If} ${A50} != 0
        ${NSD_CreateRadioButton} 0 $heightOffsetPercent 100% 6% "NW-A50"
            Pop $hwnd
            ${NSD_SetState} $hwnd 1
            ${NSD_AddStyle} $hwnd ${WS_GROUP}
            ${NSD_SetUserData} $hwnd "a50"
            ${NSD_OnClick} $hwnd deviceClick
            IntOp $heightOffset $heightOffset + 8
            StrCpy $heightOffsetPercent "$heightOffset%"
    ${EndIf}

    ${If} ${A40} != 0
        ${If} ${A40MOD_ONLY} == 1
            StrCpy $A40text "NW-A40 with A50 mod only"
        ${Else}
            StrCpy $A40text "NW-A40 (including A50 mod)"
        ${EndIf}

        ${NSD_CreateRadioButton} 0 $heightOffsetPercent 100% 6% $A40text
            Pop $hwnd
            ${NSD_SetUserData} $hwnd "a40"
            ${NSD_OnClick} $hwnd deviceClick
            IntOp $heightOffset $heightOffset + 8
            StrCpy $heightOffsetPercent "$heightOffset%"
    ${EndIf}

    ${If} ${A30} != 0
        ${If} ${A30MOD_ONLY} == 1
            StrCpy $A30text "NW-A30 with Walkman One only"
        ${Else}
            StrCpy $A30text "NW-A30"
        ${EndIf}

        ${NSD_CreateRadioButton} 0 $heightOffsetPercent 100% 6% $A30text
            Pop $hwnd
            ${NSD_SetUserData} $hwnd "a30"
            ${NSD_OnClick} $hwnd deviceClick
            IntOp $heightOffset $heightOffset + 8
            StrCpy $heightOffsetPercent "$heightOffset%"
    ${EndIf}

    ${If} ${A50Z} != 0
        ${NSD_CreateRadioButton} 0 $heightOffsetPercent 100% 6% "NW-A50Z"
            Pop $hwnd
            ${NSD_SetUserData} $hwnd "a50z"
            ${NSD_OnClick} $hwnd deviceClick
            IntOp $heightOffset $heightOffset + 8
            StrCpy $heightOffsetPercent "$heightOffset%"
    ${EndIf}

    ${If} ${WM1AZ} != 0
        ${NSD_CreateRadioButton} 0 $heightOffsetPercent 100% 6% "NW-WM1A/Z"
            Pop $hwnd
            ${NSD_SetUserData} $hwnd "wm1az"
            ${NSD_OnClick} $hwnd deviceClick
            IntOp $heightOffset $heightOffset + 8
            StrCpy $heightOffsetPercent "$heightOffset%"
    ${EndIf}

    ${If} ${ZX300} != 0
        ${NSD_CreateRadioButton} 0 $heightOffsetPercent 100% 6% "NW-ZX300"
            Pop $hwnd
            ${NSD_SetUserData} $hwnd "zx300"
            ${NSD_OnClick} $hwnd deviceClick
            IntOp $heightOffset $heightOffset + 8
            StrCpy $heightOffsetPercent "$heightOffset%"
    ${EndIf}

    ${If} ${DMPZ1} != 0
        ${NSD_CreateRadioButton} 0 $heightOffsetPercent 100% 6% "DMP-Z1"
            Pop $hwnd
            ${NSD_SetUserData} $hwnd "dmpz1"
            ${NSD_OnClick} $hwnd deviceClick
            IntOp $heightOffset $heightOffset + 8
            StrCpy $heightOffsetPercent "$heightOffset%"
    ${EndIf}

	nsDialogs::Show
FunctionEnd

Function deviceClick
	Pop $hwnd
	${NSD_GetUserData} $hwnd $SelectedDevice
FunctionEnd

var HasWalkmanOne
Function hasw1
	nsDialogs::Create 1018
	Pop $Dialog

	${If} $Dialog == error
		Abort
	${EndIf}

    ${NSD_CreateLabel} 0 0 100% 6% "Do you have Walkman One installed?"

    ${NSD_CreateRadioButton} 0 12% 40% 6% "Yes"
        Pop $hwnd
        ${NSD_AddStyle} $hwnd ${WS_GROUP}
        ${NSD_SetUserData} $hwnd 1
        ${NSD_OnClick} $hwnd walkmanOneClick

    ${NSD_CreateRadioButton} 0 20% 40% 6% "No"
        Pop $hwnd
        ${NSD_SetState} $hwnd 1
		${NSD_SetUserData} $hwnd 0
		${NSD_OnClick} $hwnd walkmanOneClick

	nsDialogs::Show
FunctionEnd

Var HyperlinkLabel
Function considerBackup
	nsDialogs::Create 1018
	Pop $Dialog

	${If} $Dialog == error
		Abort
	${EndIf}

    ${NSD_CreateLabel} 0 0 100% 6% "It would be wise to make a device backup before installation."
    ${NSD_CreateButton} 0 12% 100% 12% "Backup instructions (opens in browser)"
    Pop $HyperlinkLabel
    ${NSD_AddStyle} $HyperlinkLabel ${SS_CENTER}
    ${NSD_OnClick} $HyperlinkLabel OnHyperlinkClick

	nsDialogs::Show
FunctionEnd

Function OnHyperlinkClick
    ExecShell "open" "$backupURL"
FunctionEnd

Function walkmanOneClick
	Pop $hwnd
	${NSD_GetUserData} $hwnd $HasWalkmanOne
FunctionEnd


Function connectUSB
	nsDialogs::Create 1018
	Pop $Dialog

	${If} $Dialog == error
		Abort
	${EndIf}

	${NSD_CreateBitmap} 0 40 100% 100% ""
	Pop $ImageCtrl1
	${NSD_SetBitmap} $ImageCtrl1 $PLUGINSDIR\device.bmp $BmpHandle1

    ${NSD_CreateBitmap} 0 145 100% 100% ""
    Pop $ImageCtrl2
    ${NSD_SetBitmap} $ImageCtrl2 $PLUGINSDIR\explorer.bmp $BmpHandle2

    ${NSD_CreateLabel} 0 0 100% 32u "Connect usb device, turn on USB Mass storage and click 'Next'."
    Pop $Label

    ${NSD_CreateLabel} 0 20 100% 32u "Make sure it is called 'WALKMAN'."
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
    ${NSD_CreateLabel} 0 0 100% 32 "Installing on $USBLetter, '$USBLabel'"
    Pop $Label
    nsDialogs::Show

    StrCpy $OUTDIR "$USBLetter"

    StrCpy $letterWithoutSlash $USBLetter 2
FunctionEnd

Section reviewPageLeave
    DetailPrint "selected device: $SelectedDevice"
    ${If} $HasWalkmanOne == 1
        File "./walkmanOne/NW_WM_FW.UPG"
    ${Else}
        ${If} $SelectedDevice == "a50"
            File "./nw-a50/NW_WM_FW.UPG"
        ${ElseIf} $SelectedDevice == "a40"
            File "./nw-a40/NW_WM_FW.UPG"
        ${ElseIf} $SelectedDevice == "a30"
            File "./nw-a30/NW_WM_FW.UPG"
        ${ElseIf} $SelectedDevice == "a50z"
            File "./a50z/NW_WM_FW.UPG"
        ${ElseIf} $SelectedDevice == "wm1az"
            File "./nw-wm1a/NW_WM_FW.UPG"
        ${ElseIf} $SelectedDevice == "zx300"
             File "./nw-zx300/NW_WM_FW.UPG"
        ${ElseIf} $SelectedDevice == "dmpz1"
             File "./dmp-z1/NW_WM_FW.UPG"
        ${Else}
            MessageBox mb_iconstop "Invalid model selected"
            Quit
        ${EndIf}
    ${EndIf}

    ${If} $SelectedAction == 1
        File "../userdata.tar.gz"
    ${Else}
        File "/oname=userdata.tar.gz" "../userdata.uninstaller.tar.gz"
    ${EndIf}

    StrCpy $0 "$TEMP\output.txt"
    File "/oname=$PLUGINSDIR\scsitool-nwz-v27.exe" "scsitool-nwz-v27.exe"
    # how did it work on nw-a40 and nw-zx300?
    ReadEnvStr $R0 COMSPEC
    ExecWait '"$R0" /C "$PLUGINSDIR\scsitool-nwz-v27.exe" -d -s nw-a50 $letterWithoutSlash do_fw_upgrade > $0 2>&1'

    FileOpen $1 "$0" r
    StrCpy $2 ""
    ${Do}
      FileRead $1 $3
      ${If} ${Errors}
         ${ExitDo}
      ${EndIf}
      DetailPrint "$3"
    ${Loop}
    FileClose $1
    Delete "$0"
SectionEnd

Function .onInit
    StrCpy $USBLetter ""
    StrCpy $USBLabel ""
    StrCpy $backupURL "https://github.com/unknown321/wampy/blob/master/BACKUP.md"

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

    StrCpy $SelectedAction 1
    StrCpy $SelectedDevice "a50"
    StrCpy $HasWalkmanOne 0

    StrCpy $A40text ""

FunctionEnd
