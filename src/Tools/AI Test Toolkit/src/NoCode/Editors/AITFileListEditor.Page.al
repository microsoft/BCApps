// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

/// <summary>
/// Editor page for file list (array of filenames).
/// </summary>
page 149069 "AIT File List Editor"
{
    Caption = 'Edit File List';
    PageType = StandardDialog;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(Instructions)
            {
                Caption = '';
                ShowCaption = false;

                label(InstructionLabel)
                {
                    Caption = 'Enter file names, one per line. These should be files available in the .resources/files/ folder.';
                    ApplicationArea = All;
                }
            }
            group(Editor)
            {
                Caption = 'Files';
                ShowCaption = false;

                field(FileListText; FileListText)
                {
                    Caption = 'Files';
                    ToolTip = 'Specifies file names, one per line.';
                    MultiLine = true;
                    ApplicationArea = All;
                }
            }
        }
    }

    procedure SetFiles(FileArray: JsonArray)
    var
        FileToken: JsonToken;
        FileList: TextBuilder;
    begin
        foreach FileToken in FileArray do begin
            if FileList.Length > 0 then
                FileList.AppendLine();
            FileList.Append(FileToken.AsValue().AsText());
        end;
        FileListText := FileList.ToText();
    end;

    procedure GetFiles(): JsonArray
    var
        FileArray: JsonArray;
        Lines: List of [Text];
        Line: Text;
        TrimmedLine: Text;
    begin
        Lines := FileListText.Split(GetNewLineChars());
        foreach Line in Lines do begin
            TrimmedLine := Line.Trim();
            if TrimmedLine <> '' then
                FileArray.Add(TrimmedLine);
        end;
        exit(FileArray);
    end;

    local procedure GetNewLineChars(): List of [Text]
    var
        NewLineChars: List of [Text];
        CrLf: Text[2];
        Lf: Text[1];
        Cr: Text[1];
    begin
        CrLf[1] := 13; // CR
        CrLf[2] := 10; // LF
        Lf[1] := 10;
        Cr[1] := 13;
        NewLineChars.Add(CrLf);
        NewLineChars.Add(Lf);
        NewLineChars.Add(Cr);
        exit(NewLineChars);
    end;

    var
        FileListText: Text;
}
