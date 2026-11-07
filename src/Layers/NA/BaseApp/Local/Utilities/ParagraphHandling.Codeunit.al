// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

codeunit 10025 "Paragraph Handling"
{

    trigger OnRun()
    begin
    end;

    var
        SingleQuote: Char;
        Char127: Char;
        Text000: Label 'The StringPrintLength function in CodeUnit 10025 only works for font sizes from 7 through 10.';

    procedure InitGlobals()
    begin
        SingleQuote := 39;
        Char127 := 127;
    end;

    procedure StringPrintLength(PrintString: Text[250]; PointSize: Integer) Length: Integer
    var
        i: Integer;
        OneCharLen: Integer;
    begin
        // This function returns the number of millimeters on the print page
        // that the PrintString will take up, assuming the passed-in PointSize.
        InitGlobals();
        Length := 0;
        for i := 1 to StrLen(PrintString) do begin
            case PointSize of
                7:
                    case PrintString[i] of
                        SingleQuote:
                            OneCharLen := 46;
                        'i', 'j', 'l':
                            OneCharLen := 55;
                        '|':
                            OneCharLen := 61;
                        '!':
                            OneCharLen := 63;
                        ' ', ',', '.', '/', '\', ':', ';', 'I', '[', ']', 'f', 't':
                            OneCharLen := 68;
                        '`', 'r', '{', '}', '(', ')', '-':
                            OneCharLen := 83;
                        '"':
                            OneCharLen := 87;
                        '*':
                            OneCharLen := 95;
                        '^':
                            OneCharLen := 115;
                        'y':
                            OneCharLen := 116;
                        'v', 'x':
                            OneCharLen := 121;
                        'J', 'c', 'k', 's', 'z':
                            OneCharLen := 123;
                        '+', '<', '>', '=', '~':
                            OneCharLen := 145;
                        'F', 'T', 'Z':
                            OneCharLen := 151;
                        'Y':
                            OneCharLen := 159;
                        '&', 'A', 'B', 'E', 'K', 'P', 'S', 'V', 'X':
                            OneCharLen := 164;
                        'C', 'D', 'H', 'w':
                            OneCharLen := 174;
                        'N', 'R', 'U':
                            OneCharLen := 178;
                        Char127:
                            OneCharLen := 185;
                        'G':
                            OneCharLen := 190;
                        'Q':
                            OneCharLen := 192;
                        '%', 'M', 'O', 'm':
                            OneCharLen := 200;
                        'W':
                            OneCharLen := 238;
                        '@':
                            OneCharLen := 250;
                        else  /*all digits, many lower case letters, etc*/
                            OneCharLen := 138;
                    end;
                8:
                    case PrintString[i] of
                        SingleQuote:
                            OneCharLen := 54;
                        'i', 'j', 'l':
                            OneCharLen := 64;
                        '|', '!':
                            OneCharLen := 72;
                        ' ', ',', '.', '/', '\', ':', ';', 'I', '[', ']', 'f', 't':
                            OneCharLen := 78;
                        '`', 'r', '{', '}', '(', ')', '-':
                            OneCharLen := 94;
                        '"':
                            OneCharLen := 100;
                        '*':
                            OneCharLen := 110;
                        '^':
                            OneCharLen := 130;
                        'y':
                            OneCharLen := 138;
                        'x':
                            OneCharLen := 140;
                        'J', 'c', 'k', 's', 'v', 'z':
                            OneCharLen := 144;
                        '+', '<', '>', '=', '~':
                            OneCharLen := 166;
                        'F', 'T', 'Z':
                            OneCharLen := 172;
                        'Y':
                            OneCharLen := 186;
                        '&', 'A', 'B', 'E', 'K', 'P', 'S', 'V', 'X':
                            OneCharLen := 190;
                        'C', 'D', 'H', 'N', 'R', 'U', 'w':
                            OneCharLen := 204;
                        Char127:
                            OneCharLen := 212;
                        'G', 'O', 'Q':
                            OneCharLen := 220;
                        'M', 'm':
                            OneCharLen := 236;
                        '%':
                            OneCharLen := 250;
                        'W':
                            OneCharLen := 270;
                        '@':
                            OneCharLen := 288;
                        else  /*all digits, many lower case letters, etc*/
                            OneCharLen := 158;
                    end;
                9:
                    case PrintString[i] of
                        SingleQuote:
                            OneCharLen := 62;
                        'i', 'j', 'l':
                            OneCharLen := 70;
                        '|':
                            OneCharLen := 78;
                        '!':
                            OneCharLen := 82;
                        ' ', ',', '.', '/', '\', ':', ';', 'I', '[', ']', 'f', 't':
                            OneCharLen := 88;
                        '`', 'r', '{', '}', '(', ')', '-':
                            OneCharLen := 106;
                        '"':
                            OneCharLen := 112;
                        '*':
                            OneCharLen := 124;
                        '^':
                            OneCharLen := 144;
                        'y':
                            OneCharLen := 156;
                        'x':
                            OneCharLen := 158;
                        'J', 'c', 'k', 's', 'v', 'z':
                            OneCharLen := 160;
                        '+', '<', '>', '=', '~':
                            OneCharLen := 186;
                        'F', 'T', 'Z':
                            OneCharLen := 196;
                        'X':
                            OneCharLen := 210;
                        'Y':
                            OneCharLen := 212;
                        '&', 'A', 'B', 'E', 'K', 'P', 'S', 'V':
                            OneCharLen := 212;
                        'w':
                            OneCharLen := 224;
                        'C', 'D', 'H', 'N', 'R', 'U':
                            OneCharLen := 230;
                        Char127:
                            OneCharLen := 240;
                        'G', 'O', 'Q':
                            OneCharLen := 250;
                        'M', 'm':
                            OneCharLen := 266;
                        '%':
                            OneCharLen := 282;
                        'W':
                            OneCharLen := 302;
                        '@':
                            OneCharLen := 322;
                        else  /*all digits, many lower case letters, etc*/
                            OneCharLen := 176;
                    end;
                10:
                    case PrintString[i] of
                        SingleQuote:
                            OneCharLen := 68;
                        'i', 'j', 'l':
                            OneCharLen := 78;
                        '|':
                            OneCharLen := 88;
                        '!', ',', '.', ':', ';':
                            OneCharLen := 96;
                        ' ', '/', '\', 'I', '[', ']', 'f', 't':
                            OneCharLen := 98;
                        '`', 'r', '{', '}', '(', ')', '-':
                            OneCharLen := 116;
                        '"':
                            OneCharLen := 126;
                        '*':
                            OneCharLen := 138;
                        '^':
                            OneCharLen := 166;
                        'y':
                            OneCharLen := 174;
                        'J', 'c', 'k', 's', 'v', 'x', 'z':
                            OneCharLen := 176;
                        '+', '<', '>', '=', '~':
                            OneCharLen := 206;
                        'F', 'T', 'Z':
                            OneCharLen := 214;
                        '&', 'A', 'B', 'E', 'K', 'P', 'S', 'V', 'X', 'Y':
                            OneCharLen := 236;
                        'C', 'D', 'H', 'N', 'R', 'U', 'w':
                            OneCharLen := 254;
                        Char127:
                            OneCharLen := 266;
                        'G', 'O', 'Q':
                            OneCharLen := 274;
                        'M', 'm':
                            OneCharLen := 292;
                        '%':
                            OneCharLen := 314;
                        'W':
                            OneCharLen := 332;
                        '@':
                            OneCharLen := 358;
                        else  /*all digits, many lower case letters, etc*/
                            OneCharLen := 196;
                    end;
                else
                    Error(Text000);
            end;
            Length := Length + OneCharLen;
        end;
        exit((Length + 80) div 100);

    end;

    procedure SplitPrintLine(var PrintString: Text[250]; var PrintString2: Text[250]; SpaceOnPrintLine: Integer; PointSize: Integer)
    var
        OneWord: Text[250];
        s: Integer;
        e: Integer;
    begin
        // This function splits the print line passed in as PrintString so that it
        // will fit within SpaceOnPrintLine (in millimeters) on the printer,
        // assuming the passed-in PointSize. If the PrintString fits, it will be
        // returned unchanged and PrintString2 will be cleared. If it does not fit,
        // one word at a time (words are separated by spaces) is transferred to
        // PrintString2 from the beginning of PrintString until PrintString fits
        // or until PrintString2 would not fit if the next word were added.
        PrintString2 := '';
        while StringPrintLength(PrintString, PointSize) > SpaceOnPrintLine do begin
            if PrintString2 = '' then begin  // transfer leading spaces to other string
                s := 1;                        // this will keep indentation even
                while (s < StrLen(PrintString)) and (PrintString[s] = ' ') do begin
                    PrintString2 := PrintString2 + ' ';
                    s := s + 1;
                end;
            end else begin                   // skip the leading spaces
                s := 1;
                while (s < StrLen(PrintString)) and (PrintString[s] = ' ') do
                    s := s + 1;
            end;
            if PrintString[s] = ' ' then     // string consists solely of spaces
                exit;
            OneWord := '';                   // Copy out one word
            e := s;
            while (e < StrLen(PrintString)) and (PrintString[e] <> ' ') do begin
                OneWord := OneWord + CopyStr(PrintString, e, 1);
                e := e + 1;
            end;
            if PrintString[e] <> ' ' then
                exit;
            if StringPrintLength(PrintString2 + OneWord, PointSize) > SpaceOnPrintLine then
                exit;
            PrintString2 := PrintString2 + OneWord + ' ';
            while (e < StrLen(PrintString)) and (PrintString[e] = ' ') do
                e := e + 1;
            PrintString := DelStr(PrintString, s, e - s);
        end;
    end;

    procedure SplitPrintLineDown(var PrintString: Text[250]; var PrintString2: Text[250]; SpaceOnPrintLine: Integer; PointSize: Integer)
    var
        OneWord: Text[250];
        LeadingSpaces: Text[250];
        s: Integer;
        e: Integer;
    begin
        // This function splits the print line passed in as PrintString so that it
        // will fit within SpaceOnPrintLine (in millimeters) on the printer,
        // assuming the passed-in PointSize. If the PrintString fits, it will be
        // returned unchanged and PrintString2 will be cleared. If it does not fit,
        // one word at a time (words are separated by spaces) is transferred to
        // PrintString2 from the end of PrintString until PrintString fits.
        PrintString2 := '';
        LeadingSpaces := '';
        while StringPrintLength(PrintString, PointSize) > SpaceOnPrintLine do begin
            if PrintString2 = '' then begin  // transfer leading spaces to other string
                s := 1;                        // this will keep indentation even
                while (s < StrLen(PrintString)) and (PrintString[s] = ' ') do begin
                    LeadingSpaces := LeadingSpaces + ' ';
                    s := s + 1;
                end;
                if PrintString[s] = ' ' then     // string consists solely of spaces
                    exit;
            end;
            OneWord := '';                   // Copy out one word
            e := StrLen(PrintString);
            while (e > 1) and (PrintString[e] = ' ') do    // cut out trailing spaces
                e := e - 1;
            if e = 1 then
                if PrintString[e] = ' ' then
                    e := e - 1;
            if e = 0 then begin                // string consists solely of spaces
                PrintString2 := LeadingSpaces + PrintString2;
                exit;
            end;
            s := e;
            while (s > 1) and (PrintString[s] <> ' ') do begin
                OneWord := CopyStr(PrintString, s, 1) + OneWord;
                s := s - 1;
            end;
            if s = 1 then
                if PrintString[s] <> ' ' then begin
                    OneWord := CopyStr(PrintString, s, 1) + OneWord;
                    s := s - 1;
                end;
            if s = 0 then begin
                PrintString2 := LeadingSpaces + PrintString2;
                exit;
            end;
            PrintString2 := OneWord + ' ' + PrintString2;
            PrintString := DelStr(PrintString, s);
        end;
        PrintString2 := LeadingSpaces + PrintString2;
    end;

    procedure PadStrProportional(String: Text[250]; Length: Integer; PointSize: Integer; FillCharacter: Text[1]) NewString: Text[250]
    var
        TenCharLen: Integer;
        FillTenChar: Text[10];
    begin
        // This function performs the same function as the PADSTR intrinsic, with
        // two exceptions:  1) The Length parameter refers to length in millimeters
        // rather than string length; and 2) There is an additional PointSize parameter,
        // which indicates the font's point size.
        if FillCharacter = '' then
            FillCharacter := ' ';      // defaults to space, just like intrinsic
        FillTenChar := PadStr('', 10, FillCharacter);
        TenCharLen := StringPrintLength(FillTenChar, PointSize);
        NewString := String;
        while true do begin
            if StringPrintLength(NewString + FillCharacter, PointSize) > Length then
                exit(NewString);
            if StringPrintLength(NewString, PointSize) + TenCharLen < Length then
                NewString := NewString + FillTenChar
            else
                NewString := NewString + FillCharacter;
        end;
    end;
}

