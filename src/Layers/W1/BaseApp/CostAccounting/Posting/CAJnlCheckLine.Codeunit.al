// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Posting;

using Microsoft.CostAccounting.Account;
using Microsoft.CostAccounting.Journal;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.AuditCodes;

codeunit 1101 "CA Jnl.-Check Line"
{
    TableNo = "Cost Journal Line";

    trigger OnRun()
    begin
        SourceCodeSetup.Get();
        RunCheck(Rec);
    end;

    var
        SourceCodeSetup: Record "Source Code Setup";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Cost type or balance cost type must be defined.\Line %1, document %2, amount %3.';
        Text001: Label 'You cannot define both cost center and cost object.\Line %1, document %2, amount %3.';
        Text002: Label 'Balance cost center or balance cost object must be defined.\Line %1, document %2, amount %3.';
        Text003: Label 'You cannot define both balance cost center and balance cost object.\Line %1, document %2, amount %3.';
        Text004: Label 'Cost center or cost object must be defined. \Line %1, document %2, amount %3.';
#pragma warning restore AA0470
        Text005: Label 'is not within the permitted range of posting dates', Comment = 'starts with "Posting Date"';
#pragma warning restore AA0074

    procedure RunCheck(var CostJnlLine: Record "Cost Journal Line")
    var
        CostType: Record "Cost Type";
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunCheck(CostJnlLine, IsHandled);
        if IsHandled then
            exit;

        CostJnlLine.TestField("Posting Date");
        CostJnlLine.TestField("Document No.");

        SourceCodeSetup.Get();
        CostJnlLine.TestField(Amount);

        if (CostJnlLine."Cost Type No." = '') and (CostJnlLine."Bal. Cost Type No." = '') then
            Error(Text000, CostJnlLine."Line No.", CostJnlLine."Document No.", CostJnlLine.Amount);

        if CostJnlLine."Cost Type No." <> '' then begin
            CostType.Get(CostJnlLine."Cost Type No.");
            CostType.TestField(Blocked, false);
            CostType.TestField(Type, CostType.Type::"Cost Type");

            IsHandled := false;
            OnRunCheckOnBeforeCheckSourceCode(CostJnlLine, IsHandled);
            if not IsHandled then
                if CostJnlLine."Source Code" <> SourceCodeSetup."G/L Entry to CA" then
                    if (CostJnlLine."Cost Center Code" = '') and (CostJnlLine."Cost Object Code" = '') then
                        Error(Text004, CostJnlLine."Line No.", CostJnlLine."Document No.", CostJnlLine.Amount);
            OnRunCheckOnBeforeVerifyCostCenterAndObjectFilled(CostJnlLine, IsHandled);
            if not IsHandled then
                if (CostJnlLine."Cost Center Code" <> '') and (CostJnlLine."Cost Object Code" <> '') then
                    Error(Text001, CostJnlLine."Line No.", CostJnlLine."Document No.", CostJnlLine.Amount);
        end;

        if CostJnlLine."Bal. Cost Type No." <> '' then begin
            CostType.Get(CostJnlLine."Bal. Cost Type No.");
            CostType.TestField(Blocked, false);
            CostType.TestField(Type, CostType.Type::"Cost Type");

            IsHandled := false;
            OnRunCheckOnBeforeCheckBalCostCenterCode(CostJnlLine, IsHandled);
            if not IsHandled then
                if (CostJnlLine."Bal. Cost Center Code" = '') and (CostJnlLine."Bal. Cost Object Code" = '') then
                    Error(Text002, CostJnlLine."Line No.", CostJnlLine."Document No.", CostJnlLine.Amount);

            OnRunCheckOnBeforeVerifyBalCostCenterAndObjectFilled(CostJnlLine, IsHandled);
            if not IsHandled then
                if (CostJnlLine."Bal. Cost Center Code" <> '') and (CostJnlLine."Bal. Cost Object Code" <> '') then
                    Error(Text003, CostJnlLine."Line No.", CostJnlLine."Document No.", CostJnlLine.Amount);
        end;

        IsHandled := false;
        OnRunCheckOnBeforeDateNotAllowed(CostJnlLine, IsHandled);
        if not IsHandled then
            if GenJnlCheckLine.DateNotAllowed(CostJnlLine."Posting Date") then
                CostJnlLine.FieldError(CostJnlLine."Posting Date", Text005);

        OnAfterCheckCostJnlLine(CostJnlLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckCostJnlLine(var CostJnlLine: Record "Cost Journal Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunCheck(var CostJnlLine: Record "Cost Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunCheckOnBeforeDateNotAllowed(var CostJnlLine: Record "Cost Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunCheckOnBeforeVerifyCostCenterAndObjectFilled(var CostJournalLine: Record "Cost Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunCheckOnBeforeVerifyBalCostCenterAndObjectFilled(var CostJournalLine: Record "Cost Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunCheckOnBeforeCheckSourceCode(var CostJournalLine: Record "Cost Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunCheckOnBeforeCheckBalCostCenterCode(var CostJournalLine: Record "Cost Journal Line"; var IsHandled: Boolean)
    begin
    end;
}

