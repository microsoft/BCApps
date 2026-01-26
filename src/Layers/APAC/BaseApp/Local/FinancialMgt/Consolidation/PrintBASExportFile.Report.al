// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

using System.Utilities;

report 11606 "Print BAS Export File"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/FinancialMgt/Consolidation/PrintBASExportFile.rdlc';
    Caption = 'Print BAS Export File';

    dataset
    {
        dataitem("BAS Calculation Sheet"; "BAS Calculation Sheet")
        {
            DataItemTableView = sorting(A1, "BAS Version");

            trigger OnAfterGetRecord()
            begin
                FileName := "File Name";
            end;
        }
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number);
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(FileName; FileName)
            {
            }
            column(USERID; UserId)
            {
            }
            column(TextLine; TextLine)
            {
            }
            column(GroupNo; GroupNo)
            {
            }
            column(Integer_Number; Number)
            {
            }
            column(Print_BAS_FileCaption; Print_BAS_FileCaptionLbl)
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
                if CopyStr(TextLine, 1, 4) = Text001 then begin
                    TextLine := '';
                    GroupNo += 1;
                end;
            end;

            trigger OnPostDataItem()
            begin
                TextFile.Close();
            end;

            trigger OnPreDataItem()
            begin
                if FileName = '' then
                    Error(Text000);
                Clear(TextFile);
                TextFile.TextMode := true;
                TextFile.Open(FileName);
                GroupNo := 0;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        Text000: Label 'Please enter the file name.';
        Text001: Label '<FF>';
        TextFile: File;
        FileName: Text[250];
        TextLine: Text[250];
        GroupNo: Integer;
        Print_BAS_FileCaptionLbl: Label 'Print BAS File';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
}

