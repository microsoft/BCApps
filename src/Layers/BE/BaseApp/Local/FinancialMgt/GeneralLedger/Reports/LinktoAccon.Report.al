// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using System.IO;

report 11313 "Link to Accon"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Link to Accon';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = sorting("No.") where("Account Type" = const(Posting));
            RequestFilterFields = "Date Filter";

            trigger OnAfterGetRecord()
            begin
                if "Account Type" <> "Account Type"::Posting then
                    CurrReport.Skip();
                Clear(DebitAmt);
                Clear(CreditAmt);
                if UseAmtsInAddCurr then begin
                    CalcFields("Add.-Currency Balance at Date");
                    if "Add.-Currency Balance at Date" > 0 then
                        DebitAmt := "Add.-Currency Balance at Date"
                    else
                        CreditAmt := "Add.-Currency Balance at Date" * -1;
                end else begin
                    CalcFields("Balance at Date");
                    if "Balance at Date" > 0 then
                        DebitAmt := "Balance at Date"
                    else
                        CreditAmt := "Balance at Date" * -1;
                end;

                if ReportingCurr = BEFTok then
                    CED.Write(
                      Format(Format(PadStr("No.", 20), 20) +
                        Format(DebitAmt, 12, Text11302) +
                        Format(CreditAmt, 12, Text11302) +
                        Format(Name, 30)))
                else
                    CED.Write(
                      Format(Format(PadStr("No.", 20), 20) +
                        Format(DebitAmt, 13, Text11303) + CopyStr(Format(DebitAmt, 3, Text11304), 2, 2) +
                        Format(CreditAmt, 13, Text11303) + CopyStr(Format(CreditAmt, 3, Text11304), 2, 2) +
                        Format(Name, 30)));
            end;

            trigger OnPostDataItem()
            begin
                CED.Close();
                if FileName = '' then
                    FileMgt.DownloadHandler(ServerFileName, '', '', FileMgt.GetToFilterText('', ServerFileName), ClientFileNameTxt)
                else
                    FileMgt.CopyServerFile(ServerFileName, FileName, true);
                FileMgt.DeleteServerFile(ServerFileName);
            end;

            trigger OnPreDataItem()
            begin
                ServerFileName := FileMgt.ServerTempFileName('txt');

                Clear(CED);
                CED.TextMode := true;
                CED.WriteMode := true;
                CED.Create(ServerFileName);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(UseAmtsInAddCurr; UseAmtsInAddCurr)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Amounts in Add. Reporting Currency';
                        MultiLine = true;
                        ToolTip = 'Specifies if you want the amounts to be printed in the additional reporting currency. If you leave this check box empty, the amounts will be printed in LCY.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        GLSetup.Get();
        if UseAmtsInAddCurr then
            ReportingCurr := GLSetup."Additional Reporting Currency"
        else
            ReportingCurr := GLSetup."LCY Code";
    end;

    var
        BEFTok: Label 'BEF';
        Text11302: Label '<integer,12>', Locked = true;
        Text11303: Label '<integer,12>.', Locked = true;
        Text11304: Label '<Decimals,3>', Locked = true;
        GLSetup: Record "General Ledger Setup";
        FileMgt: Codeunit "File Management";
        UseAmtsInAddCurr: Boolean;
        ReportingCurr: Code[10];
        DebitAmt: Decimal;
        CreditAmt: Decimal;
        CED: File;
        ServerFileName: Text;
        ClientFileNameTxt: Label 'ACCON.txt', Locked = true;
        FileName: Text;

    [Scope('OnPrem')]
    procedure InitializeRequest(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;
}

