// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

using System.Utilities;

codeunit 5943 "Lock-OpenServContract"
{

    trigger OnRun()
    begin
    end;

    var
        SignServContractDoc: Codeunit SignServContractDoc;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'It is not possible to lock this %1 Service %2 because some lines have zero %3.';
        Text001: Label 'It is not possible to open a %1 service contract';
#pragma warning restore AA0470
        Text002: Label 'New lines have been added to this contract.\Would you like to continue?';
        Text003: Label 'You cannot lock service contract with negative annual amount.';
        Text004: Label 'You cannot lock service contract with zero annual amount when invoice period is different from None.';
#pragma warning restore AA0074

    procedure LockServContract(FromServContractHeader: Record "Service Contract Header")
    var
        ServContractHeader: Record "Service Contract Header";
        ServContractLine: Record "Service Contract Line";
        RaiseError: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeLockServContract(FromServContractHeader);

        ServContractHeader := FromServContractHeader;
        if ServContractHeader."Change Status" = ServContractHeader."Change Status"::Locked then
            exit;

        IsHandled := false;
        OnLockServContractOnBeforeCheckAmounts(ServContractHeader, IsHandled);
        if not IsHandled then begin
            ServContractHeader.CalcFields("Calcd. Annual Amount");
            ServContractHeader.TestField("Annual Amount", ServContractHeader."Calcd. Annual Amount");
            if ServContractHeader."Annual Amount" < 0 then
                Error(Text003);
        end;

        IsHandled := false;
        OnLockServContractOnBeforeCheckZeroAnnualAmount(ServContractHeader, IsHandled);
        if not IsHandled then
            if ServContractHeader.IsInvoicePeriodInTimeSegment() then
                if ServContractHeader."Annual Amount" = 0 then
                    Error(Text004);

        CheckServiceItemBlockedForServiceContractAndItemServiceBlocked(ServContractHeader);

        ServContractHeader.LockTable();
        IsHandled := false;
        OnLockServContractOnAfterLockTable(ServContractHeader, IsHandled);
        if not IsHandled then
            if (ServContractHeader."Contract Type" = ServContractHeader."Contract Type"::Contract) and (ServContractHeader.Status = ServContractHeader.Status::Signed) then begin
                ServContractLine.Reset();
                ServContractLine.SetRange("Contract Type", ServContractHeader."Contract Type");
                ServContractLine.SetRange("Contract No.", ServContractHeader."Contract No.");
                ServContractLine.SetRange("Line Amount", 0);
                ServContractLine.SetFilter("Line Discount %", '<%1', 100);
                RaiseError := not ServContractLine.IsEmpty();
                OnErrorIfServContractLinesHaveZeroAmount(ServContractHeader, ServContractLine, RaiseError);
                if RaiseError then
                    Error(Text000, ServContractHeader.Status, ServContractHeader."Contract Type", ServContractLine.FieldCaption("Line Amount"));
                ServContractLine.Reset();
                ServContractLine.SetRange("Contract Type", ServContractHeader."Contract Type");
                ServContractLine.SetRange("Contract No.", ServContractHeader."Contract No.");
                ServContractLine.SetRange("New Line", true);
                if not ServContractLine.IsEmpty() then
                    if not SignServContract(ServContractHeader) then
                        exit;
            end;
        ServContractHeader.Get(FromServContractHeader."Contract Type", FromServContractHeader."Contract No.");
        ServContractHeader."Change Status" := ServContractHeader."Change Status"::Locked;
        ServContractHeader.Modify();

        OnAfterLockServContract(ServContractHeader, FromServContractHeader);
    end;

    procedure OpenServContract(ServContractHeader: Record "Service Contract Header")
    begin
        if ServContractHeader."Change Status" = ServContractHeader."Change Status"::Open then
            exit;
        ServContractHeader.LockTable();
        if (ServContractHeader.Status = ServContractHeader.Status::Cancelled) and (ServContractHeader."Contract Type" = ServContractHeader."Contract Type"::Contract) then
            Error(Text001, ServContractHeader.Status);
        ServContractHeader."Change Status" := ServContractHeader."Change Status"::Open;
        ServContractHeader.Modify();

        OnAfterOpenServContract(ServContractHeader);
    end;

    local procedure SignServContract(ServContractHeader: Record "Service Contract Header"): Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
        AutoSign: Boolean;
        IsHandled: Boolean;
    begin
        AutoSign := false;
        IsHandled := false;
        OnBeforeSignServContract(ServContractHeader, AutoSign, IsHandled);
        if IsHandled then
            exit(true);

        if not AutoSign then
            if not ConfirmManagement.GetResponseOrDefault(Text002, true) then
                exit(false);

        SignServContractDoc.AddendumToContract(ServContractHeader);
        exit(true);
    end;

    local procedure CheckServiceItemBlockedForServiceContractAndItemServiceBlocked(var ServiceContractHeader: Record "Service Contract Header")
    var
        ServiceContractLine: Record "Service Contract Line";
        ServContractManagement: Codeunit ServContractManagement;
    begin
        ServiceContractLine.SetRange("Contract Type", ServiceContractHeader."Contract Type");
        ServiceContractLine.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        ServiceContractLine.SetFilter("Service Item No.", '<>%1', '');
        if ServiceContractLine.FindSet() then
            repeat
                ServContractManagement.CheckServiceItemBlockedForServiceContract(ServiceContractLine);
                ServContractManagement.CheckItemServiceBlocked(ServiceContractLine);
            until ServiceContractLine.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLockServContract(var ServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnErrorIfServContractLinesHaveZeroAmount(ServiceContractHeader: Record "Service Contract Header"; ServiceContractLine: Record "Service Contract Line"; var RaiseError: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLockServContract(var ServiceContractHeader: Record "Service Contract Header"; var FromServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOpenServContract(var ServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLockServContractOnBeforeCheckZeroAnnualAmount(ServContractHeader: Record "Service Contract Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSignServContract(ServContractHeader: Record "Service Contract Header"; var AutoSign: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLockServContractOnBeforeCheckAmounts(var ServiceContractHeader: Record "Service Contract Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLockServContractOnAfterLockTable(var ServiceContractHeader: Record "Service Contract Header"; var IsHandled: Boolean)
    begin
    end;
}

