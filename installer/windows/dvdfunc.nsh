/* --------------------------------

  DVD functions - a replacement for the CD-ROM plugin for NSIS
    Created by Message, 2007

  Usage example:
    push ""                       ;push input to stack
    call DVD_GetNextDrive         ;call function
    pop $0                        ;pop output from stack

    push $0                       ;push input to stack
    call DVD_GetLabel             ;call function
    pop $1                        ;pop output from stack


  DVD_GetNextDrive : Finds the first/next CD/DVD-ROM drive and returns its full path on the stack.

             input : The function will search for the first CD/DVD drive AFTER this specified
                     drive letter. So with input "C:\" the function will start searching at D:\.
                     Only the first character of the input is used, and this first character
                     should be a Capital letter from A to Z.
                     If the input does not start with A-Z, the function returns an empty string
                     ("") on the stack.
                     If the input is empty, the function starts scanning at A:\.
                     If the function reaches Z:\, it will continue searching at A:\.
            output : The full path of the first CD/DVD-ROM drive the function found (starting at
                     the inputted drive letter), for example "E:\".
                     If there is only one CD/DVD-ROM drive in the sytem, starting the search at
                     that drive letter will result in the same drive letter being returned.
                     If the function could not find any CD/DVD-ROM drives in the system, it will
                     return an empty string ("") on the stack. If Windows could not find any
                     drives at all (either CD-ROM or otherwise), the function returns "ERROR".
                     This should never happen.

  DVD_GetLabel     : Returns the label of the CD/DVD currently in the specified drive on the stack.

             input : The full path to the root of the CD/DVD-ROM drive, so for example "E:\".
            output : The full volume label of the disc in the drive. If there is no disc in the
                     drive, or there is some other error, the function will return
                     "DVDGetLabel_error" on the stack.

  DVD_CheckDrive   : Checks if the specified drive  is a CD/DVD-ROM drive.

             input : The full path to the root of the CD/DVD-ROM drive, so for example "E:\".
            output : If the drive is a CD/DVD-ROM drive, the function will return "CDROM" on the
                     stack. (For other possible outputs, see the function code.)
*/

/*
Function DVD_CheckDrive
  Exch $R0
  Push $R1
  System::Call 'kernel32::GetDriveType(t "$R0") i .r11'
  StrCmp $R1 0 0 +2
  StrCpy $R0 "UNKNOWN"
  StrCmp $R1 1 0 +2
  StrCpy $R0 "INVALID"
  StrCmp $R1 2 0 +2
  StrCpy $R0 "REMOVABLE"
  StrCmp $R1 3 0 +2
  StrCpy $R0 "FIXED"
  StrCmp $R1 4 0 +2
  StrCpy $R0 "REMOTE"
  StrCmp $R1 5 0 +2
  StrCpy $R0 "CDROM"
  StrCmp $R1 6 0 +2
  StrCpy $R0 "RAMDISK"
  Pop $R1
  Exch $R0
FunctionEnd
*/


Function DVD_GetLabel
  Exch $R0
  Push $R1
  Push $R2

  ;leave function if no parameter was supplied
  StrCmp $R0 "" break

  ;get the label of the drive (return to $R1)
  System::Call 'Kernel32::GetVolumeInformation(t r10,t.r11,i ${NSIS_MAX_STRLEN},*i,*i,*i,t.r12,i ${NSIS_MAX_STRLEN})i.r10'
  StrCmp $R0 0 0 +3
    StrCpy $R0 "DVDGetLabel_error"
    goto +2
  StrCpy $R0 $R1
  break:

  Pop $R2
  Pop $R1
  Exch $R0
FunctionEnd


Function DVD_GetNextDrive
  Exch $R1
  Push $R0
  Push $R2
  Push $R3
  Push $R4


  ;get all drives (return to $R0, bitwise)
  System::Call 'kernel32::GetLogicalDrives() i .r10'
  StrCmp $R0 "0" 0 +3        ;if no drives found, error
    StrCpy $R1 "ERROR"
    goto break

  ;If no parameter was supplied at all, assume we're starting at A:\ and set the "no parameters" flag.
  StrCmp $R1 "" 0 +4
    StrCpy $R1 "0"
    StrCpy $R4 "-1"  ;no parameters flag. If $R4 is -1, it will never equal the current drive letter, thus the alphabet cycle check will never kick in
    goto loop

  ;get ascii-number of first char in function parameter
  System::Call "*(&t1 r11)i.r12"
  System::Call "*$R2(&i1 .r11)"
  System::Free $R2
  IntOp $R1 $R1 - 65

  ;check if parameter driveletter is between A and Z
  IntCmp $R1 0 0 +2
  IntCmp $R1 25 +3 +3
    StrCpy $R1 ""
    goto break

  ;If a valid parameter was supplied (ie we had a parameter and we survived so far), start at the driveletter directly after the supplied starting driveletter
  IntOp $R1 $R1 + 1
  StrCmp $R1 26 0 +2         ;if >Z
    StrCpy $R1 0             ;  return to A

  ;backup the (asciiconverted) starting driveletter, for detecting when we've cycled the entire alphabet.
  StrCpy $R4 $R1

  loop:
    IntOp $R2 0x01 << $R1
    IntOp $R3 $R2 & $R0
    ;if (0x01<<driveletter & drivesfound) == 0x01<<driveletter  (in other words, if there is a drive mounted at this driveletter)
    StrCmp $R3 $R2 0 NoDriveHere
      ;convert asciinumber of driveletter to character
      IntOp $R2 $R1 + 65
      IntFmt $R2 %c $R2
      ;get type of drive
      System::Call 'kernel32::GetDriveType(t "$R2:\") i .r13'
      StrCmp $R3 2 0 NoDriveHere
        ;if type is removable
        StrCpy $R1 "$R2:\"
        goto break
    NoDriveHere:
    IntOp $R1 $R1 + 1        ;increment driveletter
    StrCmp $R1 26 0 cycle    ;if >Z
      StrCmp $R4 "-1" 0 +3   ;  if there were no parameters
        StrCpy $R1 ""        ;    no CDROM drive found
        goto break
      StrCpy $R1 0           ;  else return to A
      goto loop              ;    and loop
    cycle:
    StrCmp $R1 $R4 0 loop    ;if we've cycled through the entire alphabet
      StrCpy $R1 ""          ;  no CDROM drives found at all
      goto break
  break:

  Pop $R4
  Pop $R3
  Pop $R2
  Pop $R0
  Exch $R1
FunctionEnd