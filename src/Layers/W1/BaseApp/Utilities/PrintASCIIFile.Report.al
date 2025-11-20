// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using System.IO;
using System.Utilities;

report 1301 "Print ASCII File"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Utilities/PrintASCIIFile.rdlc';
    Caption = 'Print ASCII File';

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number);
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(FileName; FileName)
            {
            }
            column(TextLine; TextLine)
            {
            }
            column(Print_ASCII_FileCaption; Print_ASCII_FileCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if TextFile.Len = TextFile.Pos then
                    CurrReport.Break();
                TextFile.Read(TextLine);
                if CopyStr(TextLine, 1, 4) = Text001 then
                    TextLine := '';
            end;

            trigger OnPostDataItem()
            begin
                TextFile.Close();
            end;

            trigger OnPreDataItem()
            begin
                if ServerFileName = '' then
                    Error(Text000);
                Clear(TextFile);
                TextFile.TextMode := true;
                TextFile.Open(ServerFileName);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(FileName; FileName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'File Name';
                        Editable = false;
                        ToolTip = 'Specifies the name of the file to be printed.';

                        trigger OnAssistEdit()
                        var
                            FileMgt: Codeunit "File Management";
                        begin
                            ServerFileName := FileMgt.UploadFile(Text002, '');
                            if ServerFileName <> '' then
                                FileName := Text004;
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            FileName := '';
        end;
    }

    labels
    {
    }

    var
#pragma warning disable AA0074
        Text000: Label 'Please enter the file name.';
        Text001: Label '<FF>', Locked = true;
#pragma warning restore AA0074
        TextFile: File;
        FileName: Text;
        ServerFileName: Text;
        TextLine: Text[1024];
#pragma warning disable AA0074
        Text002: Label 'Import';
        Text004: Label 'The file was successfully uploaded to server';
#pragma warning restore AA0074
        Print_ASCII_FileCaptionLbl: Label 'Print ASCII File';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
}

