// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.Company;
using System.IO;

report 10005 "Export GIFI Info. to Excel"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Export GIFI Info. to Excel';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(GIFICode; "GIFI Code")
        {
            DataItemTableView = sorting(Code);
            RequestFilterFields = "Code";

            trigger OnAfterGetRecord()
            begin
                ExportBalance(GIFICode);
            end;

            trigger OnPostDataItem()
            begin
                TempExcelBuffer.CreateBookAndOpenExcel('', CompanyName, Text003, CompanyInformation.Name, UserId);
            end;

            trigger OnPreDataItem()
            var
                DummyGLAccount: Record "G/L Account";
            begin
                if GIFIFilterString <> '' then
                    SetFilter(Code, GIFIFilterString);
                ColNo := 1;
                EnterCell(RowNo, ColNo, TableCaption(), '', true);
                ColNo := ColNo + 1;
                if PrintGIFIName then begin
                    EnterCell(RowNo, ColNo, FieldCaption(Name), '', true);
                    ColNo := ColNo + 1;
                end;
                EnterCell(RowNo, ColNo, DummyGLAccount.FieldCaption("Balance at Date"), '', true);
                RowNo := RowNo + 1;
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
                    field(AsOfDate; AsOfDate)
                    {
                        ApplicationArea = BasicCA;
                        Caption = 'Balance As Of Date';
                        ToolTip = 'Specifies, in MMDDYY format, the date that the financial information will be based on. The financial information will be based on the account balances as of this date.';
                    }
                    field(UseAddRptCurr; UseAddRptCurr)
                    {
                        ApplicationArea = BasicCA;
                        Caption = 'Use Add. Rpt. Currency';
                        ToolTip = 'Specifies if you want to export the balances in the additional reporting currency. Clear this field if you want to export the balances in the local currency (LCY). Make your selection based on which one of these two currencies is Canadian dollars.';
                    }
                    field(PrintGIFIName; PrintGIFIName)
                    {
                        ApplicationArea = BasicCA;
                        Caption = 'Include GIFI Name';
                        ToolTip = 'Specifies if you want to have the name of each GIFI code exported to the Excel spreadsheet using an additional column. Otherwise, only the GIFI code and the financial amount will be included in the spreadsheet.';
                    }
                    field(IncludeZero; IncludeZero)
                    {
                        ApplicationArea = BasicCA;
                        Caption = 'Include Unused Codes';
                        ToolTip = 'Specifies if you want to include a row in the spreadsheet for each GIFI code in the table, even if the balance for that GIFI code is zero. Otherwise only GIFI codes which have non-zero balances will be exported.';
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
        CompanyInformation.Get();
        GIFIFilterString := GIFICode.GetFilter(Code);
        if AsOfDate = 0D then
            Error(Text001);

        RowNo := 1;
    end;

    var
        CompanyInformation: Record "Company Information";
        TempExcelBuffer: Record "Excel Buffer" temporary;
        AsOfDate: Date;
        PrintGIFIName: Boolean;
        UseAddRptCurr: Boolean;
        IncludeZero: Boolean;
        Text001: Label 'You must enter an As Of Date.';
        RowNo: Integer;
        ColNo: Integer;
        Text002: Label '0_);(0)';
        Text003: Label 'GIFI';
        GIFIFilterString: Text;

    local procedure EnterCell(RowNo: Integer; ColumnNo: Integer; CellValue: Text[250]; NumberFormat: Text[30]; Bold: Boolean)
    begin
        TempExcelBuffer.Init();
        TempExcelBuffer.Validate("Row No.", RowNo);
        TempExcelBuffer.Validate("Column No.", ColumnNo);
        if NumberFormat <> '' then begin
            TempExcelBuffer."Cell Type" := TempExcelBuffer."Cell Type"::Number;
            TempExcelBuffer.NumberFormat := NumberFormat;
        end else
            TempExcelBuffer."Cell Type" := TempExcelBuffer."Cell Type"::Text;

        TempExcelBuffer."Cell Value as Text" := CellValue;

        TempExcelBuffer.Bold := Bold;
        TempExcelBuffer.Insert();
    end;

    local procedure ExportBalance(var GIFICode: Record "GIFI Code")
    var
        GLAccount: Record "G/L Account";
        BalanceAtDate: Decimal;
        AdditionalCurrencyBalanceAtDate: Decimal;
    begin
        GLAccount.SetRange("Date Filter", 0D, AsOfDate);
        GLAccount.SetRange("GIFI Code", GIFICode.Code);

        if GLAccount.FindSet() then
            repeat
                GLAccount.CalcFields("Balance at Date", "Add.-Currency Balance at Date");
                BalanceAtDate += GLAccount."Balance at Date";
                AdditionalCurrencyBalanceAtDate += GLAccount."Add.-Currency Balance at Date";
            until GLAccount.Next() = 0;

        if IncludeZero or
           (BalanceAtDate <> 0) or
           (AdditionalCurrencyBalanceAtDate <> 0)
        then begin
            ColNo := 1;
            EnterCell(RowNo, ColNo, GIFICode.Code, '', false);
            ColNo := ColNo + 1;
            if PrintGIFIName then begin
                EnterCell(RowNo, ColNo, GIFICode.Name, '', false);
                ColNo := ColNo + 1;
            end;
            if UseAddRptCurr then
                EnterCell(RowNo, ColNo, Format(AdditionalCurrencyBalanceAtDate), Text002, false)
            else
                EnterCell(RowNo, ColNo, Format(BalanceAtDate), Text002, false);
            RowNo := RowNo + 1;
        end;
    end;
}

