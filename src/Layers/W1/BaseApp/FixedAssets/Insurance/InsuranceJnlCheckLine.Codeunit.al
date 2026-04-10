// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Insurance;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.FixedAssets.Setup;

codeunit 5651 "Insurance Jnl.-Check Line"
{
    TableNo = "Insurance Journal Line";

    trigger OnRun()
    begin
        GLSetup.Get();
        RunCheck(Rec);
    end;

    var
        GLSetup: Record "General Ledger Setup";
        FASetup: Record "FA Setup";
        DimMgt: Codeunit DimensionManagement;
        CallNo: Integer;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'The combination of dimensions used in %1 %2, %3, %4 is blocked. %5';
        Text001: Label 'A dimension used in %1 %2, %3, %4 has caused an error. %5';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure RunCheck(var InsuranceJnlLine: Record "Insurance Journal Line")
    var
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        if InsuranceJnlLine."Insurance No." = '' then
            exit;
        InsuranceJnlLine.TestField("Insurance No.");
        InsuranceJnlLine.TestField("Document No.");
        InsuranceJnlLine.TestField("Posting Date");
        InsuranceJnlLine.TestField("FA No.");
        if CallNo = 0 then begin
            FASetup.Get();
            FASetup.TestField("Insurance Depr. Book");
        end;
        CallNo := 1;

        OnRunCheckOnBeforeCheckDimIDComb(InsuranceJnlLine);
        if not DimMgt.CheckDimIDComb(InsuranceJnlLine."Dimension Set ID") then
            Error(
              Text000,
              InsuranceJnlLine.TableCaption, InsuranceJnlLine."Journal Template Name", InsuranceJnlLine."Journal Batch Name", InsuranceJnlLine."Line No.",
              DimMgt.GetDimCombErr());

        TableID[1] := DATABASE::Insurance;
        No[1] := InsuranceJnlLine."Insurance No.";
        if not DimMgt.CheckDimValuePosting(TableID, No, InsuranceJnlLine."Dimension Set ID") then
            if InsuranceJnlLine."Line No." <> 0 then
                Error(
                  Text001,
                  InsuranceJnlLine.TableCaption, InsuranceJnlLine."Journal Template Name", InsuranceJnlLine."Journal Batch Name", InsuranceJnlLine."Line No.",
                  DimMgt.GetDimValuePostingErr())
            else
                Error(DimMgt.GetDimValuePostingErr());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunCheckOnBeforeCheckDimIDComb(var InsuranceJnlLine: Record "Insurance Journal Line")
    begin
    end;

}

