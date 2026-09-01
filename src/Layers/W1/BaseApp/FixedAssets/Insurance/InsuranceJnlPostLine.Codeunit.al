// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Insurance;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.FixedAssets.FixedAsset;

codeunit 5652 "Insurance Jnl.-Post Line"
{
    Permissions = TableData "Ins. Coverage Ledger Entry" = rimd,
                  TableData "Insurance Register" = rimd;
    TableNo = "Insurance Journal Line";

    trigger OnRun()
    begin
        GLSetup.Get();
        RunWithCheck(Rec);
    end;

    var
        GLSetup: Record "General Ledger Setup";
        FA: Record "Fixed Asset";
        Insurance: Record Insurance;
        InsuranceJnlLine: Record "Insurance Journal Line";
        InsCoverageLedgEntry: Record "Ins. Coverage Ledger Entry";
        InsCoverageLedgEntry2: Record "Ins. Coverage Ledger Entry";
        InsuranceReg: Record "Insurance Register";
        InsuranceJnlCheckLine: Codeunit "Insurance Jnl.-Check Line";
        MakeInsCoverageLedgEntry: Codeunit "Make Ins. Coverage Ledg. Entry";
        NextEntryNo: Integer;

    procedure RunWithCheck(var InsuranceJnlLine2: Record "Insurance Journal Line")
    begin
        InsuranceJnlLine.Copy(InsuranceJnlLine2);
        Code(true);
        InsuranceJnlLine2 := InsuranceJnlLine;
    end;

    procedure RunWithOutCheck(var InsuranceJnlLine2: Record "Insurance Journal Line")
    begin
        InsuranceJnlLine.Copy(InsuranceJnlLine2);
        Code(false);
        InsuranceJnlLine2 := InsuranceJnlLine;
    end;

    local procedure "Code"(CheckLine: Boolean)
    begin
        if InsuranceJnlLine."Insurance No." = '' then
            exit;
        if CheckLine then
            InsuranceJnlCheckLine.RunCheck(InsuranceJnlLine);
        Insurance.Get(InsuranceJnlLine."Insurance No.");
        Insurance.TestField(Blocked, false);
        FA.Get(InsuranceJnlLine."FA No.");
        FA.TestField("Budgeted Asset", false);
        FA.TestField(Blocked, false);
        FA.TestField(Inactive, false);
        MakeInsCoverageLedgEntry.CopyFromJnlLine(InsCoverageLedgEntry, InsuranceJnlLine);
        MakeInsCoverageLedgEntry.CopyFromInsuranceCard(InsCoverageLedgEntry, Insurance);
        if NextEntryNo = 0 then begin
            InsCoverageLedgEntry.LockTable();
            NextEntryNo := InsCoverageLedgEntry2.GetLastEntryNo() + 1;
            InsuranceReg.LockTable();
            InsuranceReg."No." := InsuranceReg.GetLastEntryNo() + 1;
            InsuranceReg.Init();
            InsuranceReg."From Entry No." := NextEntryNo + 1;
            InsuranceReg."Creation Date" := Today;
            InsuranceReg."Creation Time" := Time;
            InsuranceReg."Source Code" := InsuranceJnlLine."Source Code";
            InsuranceReg."Journal Batch Name" := InsuranceJnlLine."Journal Batch Name";
            InsuranceReg."User ID" := CopyStr(UserId(), 1, MaxStrLen(InsuranceReg."User ID"));
        end;
        NextEntryNo := NextEntryNo + 1;
        InsCoverageLedgEntry."Entry No." := NextEntryNo;
        InsCoverageLedgEntry."Dimension Set ID" := InsuranceJnlLine."Dimension Set ID";
        InsCoverageLedgEntry.Insert();
        if InsuranceReg."To Entry No." = 0 then begin
            InsuranceReg."To Entry No." := NextEntryNo;
            InsuranceReg.Insert();
        end else begin
            InsuranceReg."To Entry No." := NextEntryNo;
            InsuranceReg.Modify();
        end;

        OnAfterCode(InsCoverageLedgEntry);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCode(var InsCoverageLedgerEntry: Record "Ins. Coverage Ledger Entry")
    begin
    end;
}

