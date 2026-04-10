// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CashFlow.Worksheet;

using Microsoft.CashFlow.Account;
using Microsoft.CashFlow.Forecast;
using Microsoft.Finance.GeneralLedger.Setup;

codeunit 846 "Cash Flow Wksh. -Register Line"
{
    Permissions = TableData "Cash Flow Forecast Entry" = rimd;
    TableNo = "Cash Flow Worksheet Line";

    trigger OnRun()
    begin
        GLSetup.Get();
        RunWithCheck(Rec);
    end;

    var
        CFWkshLine: Record "Cash Flow Worksheet Line";
        CFForecastEntry: Record "Cash Flow Forecast Entry";
        CashFlowForecast: Record "Cash Flow Forecast";
        GLSetup: Record "General Ledger Setup";
        CFAccount: Record "Cash Flow Account";
        CFWkshCheckLine: Codeunit "Cash Flow Wksh.- Check Line";
        NextEntryNo: Integer;

    procedure RunWithCheck(var CFWkshLine2: Record "Cash Flow Worksheet Line")
    begin
        CFWkshLine.Copy(CFWkshLine2);
        Code();
        CFWkshLine2 := CFWkshLine;
    end;

    local procedure "Code"()
    var
        CheckIfCFAccountBlocked: Boolean;
    begin
        if CFWkshLine.EmptyLine() then
            exit;

        CFWkshCheckLine.RunCheck(CFWkshLine);

        if NextEntryNo = 0 then begin
            CFForecastEntry.LockTable();
            NextEntryNo := CFForecastEntry.GetLastEntryNo() + 1;
        end;

        CashFlowForecast.Get(CFWkshLine."Cash Flow Forecast No.");
        CheckIfCFAccountBlocked := CFWkshLine."Cash Flow Account No." <> '';
        OnCodeOnAfterCalcCheckIfCFAccountBlocked(CFWkshLine, CheckIfCFAccountBlocked);
        if CheckIfCFAccountBlocked then begin
            CFAccount.Get(CFWkshLine."Cash Flow Account No.");
            CFAccount.TestField(Blocked, false);
        end;

        CFForecastEntry.Init();
        CFForecastEntry."Cash Flow Forecast No." := CFWkshLine."Cash Flow Forecast No.";
        CFForecastEntry."Cash Flow Date" := CFWkshLine."Cash Flow Date";
        CFForecastEntry."Document No." := CFWkshLine."Document No.";
        CFForecastEntry."Document Date" := CFWkshLine."Document Date";
        CFForecastEntry."Cash Flow Account No." := CFWkshLine."Cash Flow Account No.";
        CFForecastEntry."Source Type" := CFWkshLine."Source Type";
        CFForecastEntry."Source No." := CFWkshLine."Source No.";
        CFForecastEntry."G/L Budget Name" := CFWkshLine."G/L Budget Name";
        CFForecastEntry.Description := CFWkshLine.Description;
        CFForecastEntry."Payment Discount" := Round(CFWkshLine."Payment Discount", 0.00001);
        CFForecastEntry."Associated Entry No." := CFWkshLine."Associated Entry No.";
        CFForecastEntry.Overdue := CFWkshLine.Overdue;
        CFForecastEntry."Global Dimension 2 Code" := CFWkshLine."Shortcut Dimension 2 Code";
        CFForecastEntry."Global Dimension 1 Code" := CFWkshLine."Shortcut Dimension 1 Code";
        CFForecastEntry."Dimension Set ID" := CFWkshLine."Dimension Set ID";
        CFForecastEntry."Amount (LCY)" := Round(CFWkshLine."Amount (LCY)", 0.00001);
        CFForecastEntry.Positive := CFForecastEntry."Amount (LCY)" > 0;

        if CFForecastEntry.Description = CashFlowForecast.Description then
            CFForecastEntry.Description := '';
        CFForecastEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(CFForecastEntry."User ID"));
        CFForecastEntry."Entry No." := NextEntryNo;

        OnAfterCreateForecastEntry(CFForecastEntry, CFWkshLine);
        CFForecastEntry.Insert();

        NextEntryNo := NextEntryNo + 1;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateForecastEntry(var CashFlowForecastEntry: Record "Cash Flow Forecast Entry"; CashFlowWorksheetLine: Record "Cash Flow Worksheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterCalcCheckIfCFAccountBlocked(var CashFlowWorksheetLine: Record "Cash Flow Worksheet Line"; var CheckIfCFAccountBlocked: Boolean)
    begin
    end;
}

