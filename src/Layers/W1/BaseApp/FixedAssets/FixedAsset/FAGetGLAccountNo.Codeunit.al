// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Ledger;

using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Maintenance;

codeunit 5602 "FA Get G/L Account No."
{

    trigger OnRun()
    begin
    end;

    var
        FAPostingGr: Record "FA Posting Group";
        GLAccNo: Code[20];

    procedure GetAccNo(var FALedgEntry: Record "FA Ledger Entry"): Code[20]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        FAPostingGr.GetPostingGroup(FALedgEntry."FA Posting Group", FALedgEntry."Depreciation Book Code");
        OnGetAccNoOnAfterGetFAPostingGroup(FAPostingGr, FALedgEntry, GLAccNo, IsHandled);
        if IsHandled then
            exit(GLAccNo);
        GLAccNo := '';
        if FALedgEntry."FA Posting Category" = FALedgEntry."FA Posting Category"::" " then
            case FALedgEntry."FA Posting Type" of
                FALedgEntry."FA Posting Type"::"Acquisition Cost":
                    GLAccNo := FAPostingGr.GetAcquisitionCostAccount();
                FALedgEntry."FA Posting Type"::Depreciation:
                    GLAccNo := FAPostingGr.GetAccumDepreciationAccount();
                FALedgEntry."FA Posting Type"::"Write-Down":
                    GLAccNo := FAPostingGr.GetWriteDownAccount();
                FALedgEntry."FA Posting Type"::Appreciation:
                    GLAccNo := FAPostingGr.GetAppreciationAccount();
                FALedgEntry."FA Posting Type"::"Custom 1":
                    GLAccNo := FAPostingGr.GetCustom1Account();
                FALedgEntry."FA Posting Type"::"Custom 2":
                    GLAccNo := FAPostingGr.GetCustom2Account();
                FALedgEntry."FA Posting Type"::"Proceeds on Disposal":
                    GLAccNo := FAPostingGr.GetSalesAccountOnDisposalGain();
                FALedgEntry."FA Posting Type"::"Gain/Loss":
                    begin
                        if FALedgEntry."Result on Disposal" = FALedgEntry."Result on Disposal"::Gain then
                            GLAccNo := FAPostingGr.GetGainsAccountOnDisposal();
                        if FALedgEntry."Result on Disposal" = FALedgEntry."Result on Disposal"::Loss then
                            GLAccNo := FAPostingGr.GetLossesAccountOnDisposal();
                    end;
            end;

        if FALedgEntry."FA Posting Category" = FALedgEntry."FA Posting Category"::Disposal then
            case FALedgEntry."FA Posting Type" of
                FALedgEntry."FA Posting Type"::"Acquisition Cost":
                    GLAccNo := FAPostingGr.GetAcquisitionCostAccountOnDisposal();
                FALedgEntry."FA Posting Type"::Depreciation:
                    GLAccNo := FAPostingGr.GetAccumDepreciationAccountOnDisposal();
                FALedgEntry."FA Posting Type"::"Write-Down":
                    GLAccNo := FAPostingGr.GetWriteDownAccountOnDisposal();
                FALedgEntry."FA Posting Type"::Appreciation:
                    GLAccNo := FAPostingGr.GetAppreciationAccountOnDisposal();
                FALedgEntry."FA Posting Type"::"Custom 1":
                    GLAccNo := FAPostingGr.GetCustom1AccountOnDisposal();
                FALedgEntry."FA Posting Type"::"Custom 2":
                    GLAccNo := FAPostingGr.GetCustom2AccountOnDisposal();
                FALedgEntry."FA Posting Type"::"Book Value on Disposal":
                    begin
                        if FALedgEntry."Result on Disposal" = FALedgEntry."Result on Disposal"::Gain then
                            GLAccNo := FAPostingGr.GetBookValueAccountOnDisposalGain();
                        if FALedgEntry."Result on Disposal" = FALedgEntry."Result on Disposal"::Loss then
                            GLAccNo := FAPostingGr.GetBookValueAccountOnDisposalLoss();
                        FALedgEntry."Result on Disposal" := FALedgEntry."Result on Disposal"::" ";
                    end;
            end;

        if FALedgEntry."FA Posting Category" = FALedgEntry."FA Posting Category"::"Bal. Disposal" then
            case FALedgEntry."FA Posting Type" of
                FALedgEntry."FA Posting Type"::"Write-Down":
                    GLAccNo := FAPostingGr.GetWriteDownBalAccountOnDisposal();
                FALedgEntry."FA Posting Type"::Appreciation:
                    GLAccNo := FAPostingGr.GetAppreciationBalAccountOnDisposal();
                FALedgEntry."FA Posting Type"::"Custom 1":
                    GLAccNo := FAPostingGr.GetCustom1BalAccountOnDisposal();
                FALedgEntry."FA Posting Type"::"Custom 2":
                    GLAccNo := FAPostingGr.GetCustom2BalAccountOnDisposal();
            end;

        OnAfterGetAccNo(FALedgEntry, GLAccNo);
        exit(GLAccNo);
    end;

    procedure GetMaintenanceAccNo(var MaintenanceLedgEntry: Record "Maintenance Ledger Entry"): Code[20]
    var
        AccountNo: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        AccountNo := '';
        OnBeforeGetMaintenanceAccNo(MaintenanceLedgEntry, AccountNo, IsHandled);
        if IsHandled then
            exit(AccountNo);
        FAPostingGr.GetPostingGroup(
            MaintenanceLedgEntry."FA Posting Group", MaintenanceLedgEntry."Depreciation Book Code");
        exit(FAPostingGr.GetMaintenanceExpenseAccount());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAccNo(var FALedgEntry: Record "FA Ledger Entry"; var GLAccNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetAccNoOnAfterGetFAPostingGroup(var FAPostingGr: Record "FA Posting Group"; FALedgerEntry: Record "FA Ledger Entry"; var GLAccNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetMaintenanceAccNo(var MaintenanceLedgEntry: Record "Maintenance Ledger Entry"; var AccountNo: Code[20]; var IsHandled: Boolean)
    begin
    end;
}

