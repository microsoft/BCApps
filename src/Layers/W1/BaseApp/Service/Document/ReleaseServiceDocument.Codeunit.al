// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Finance.VAT.Calculation;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Setup;

codeunit 416 "Release Service Document"
{
    TableNo = "Service Header";
    Permissions = TableData "Service Header" = rm,
                  TableData "Service Line" = r;

    trigger OnRun()
    begin
        ServiceHeader.Copy(Rec);
        ServiceHeader.SetHideValidationDialog(Rec.GetHideValidationDialog());
        Code();
        Rec := ServiceHeader;
    end;

    var
        ServiceHeader: Record "Service Header";
        InvtSetup: Record "Inventory Setup";
        WhseServiceRelease: Codeunit "Whse.-Service Release";
        SkipWhseRequestOperations: Boolean;
#pragma warning disable AA0470
        NothingToReleaseErr: Label 'There is nothing to release for %1 %2.', Comment = 'Example: There is nothing to release for Order 12345.';
#pragma warning restore AA0470

    local procedure "Code"()
    var
        ServLine: Record "Service Line";
        TempVATAmountLine0: Record "VAT Amount Line" temporary;
        TempVATAmountLine1: Record "VAT Amount Line" temporary;
        IsHandled: Boolean;
    begin
        if ServiceHeader."Release Status" = ServiceHeader."Release Status"::"Released to Ship" then
            exit;

        OnBeforeReleaseServiceDoc(ServiceHeader);

        if ServiceHeader."Document Type" = ServiceHeader."Document Type"::Quote then
            ServiceHeader.TestField("Bill-to Customer No.");

        CheckServiceItemBlockedForAllAndItemServiceBlocked(ServiceHeader);

        IsHandled := false;
        OnBeforeNothingToReleaseErr(ServiceHeader, IsHandled);
        if not IsHandled then begin
            ServLine.SetRange("Document Type", ServiceHeader."Document Type");
            ServLine.SetRange("Document No.", ServiceHeader."No.");
            ServLine.SetFilter(Type, '<>%1', ServLine.Type::" ");
            ServLine.SetFilter(Quantity, '<>0');
            if ServLine.IsEmpty() then
                Error(NothingToReleaseErr, ServiceHeader."Document Type", ServiceHeader."No.");
        end;

        IsHandled := false;
        OnCodeOnBeforeCheckLocationCode(ServLine, IsHandled);
        if not IsHandled then begin
            InvtSetup.Get();
            ServLine.SetCurrentKey(Type);
            ServLine.SetRange(Type, ServLine.Type::Item);
            if ServLine.FindSet() then
                repeat
                    if InvtSetup."Location Mandatory" then
                        if ServLine."Location Code" = '' then
                            VerifyLocationCode(ServLine);
                    if ServLine.IsInventoriableItem() then
                        ServLine.TestField("Unit of Measure Code");
                until ServLine.Next() = 0;
            ServLine.SetFilter(Type, '<>%1', ServLine.Type::" ");
        end;

        OnCodeOnAfterCheck(ServiceHeader, ServLine);

        ServLine.Reset();
        ServiceHeader.Validate(ServiceHeader."Release Status", ServiceHeader."Release Status"::"Released to Ship");
        ServLine.SetServHeader(ServiceHeader);
        ServLine.CalcVATAmountLines(0, ServiceHeader, ServLine, TempVATAmountLine0, ServLine.IsShipment());
        ServLine.CalcVATAmountLines(1, ServiceHeader, ServLine, TempVATAmountLine1, ServLine.IsShipment());
        ServLine.UpdateVATOnLines(0, ServiceHeader, ServLine, TempVATAmountLine0);
        ServLine.UpdateVATOnLines(1, ServiceHeader, ServLine, TempVATAmountLine1);
        ServiceHeader.Modify(true);

        if ServiceHeader."Document Type" = ServiceHeader."Document Type"::Order then
            if not SkipWhseRequestOperations then
                WhseServiceRelease.Release(ServiceHeader);

        OnAfterReleaseServiceDoc(ServiceHeader);
    end;

    procedure Reopen(var ServHeader: Record "Service Header")
    begin
        if ServHeader."Release Status" = ServHeader."Release Status"::Open then
            exit;

        OnBeforeReopenServiceDoc(ServHeader);
        ServHeader.Validate("Release Status", ServHeader."Release Status"::Open);
        ServHeader.Modify(true);
        if ServHeader."Document Type" in [ServHeader."Document Type"::Order] then
            if not SkipWhseRequestOperations then
                WhseServiceRelease.Reopen(ServHeader);
        OnAfterReopenServiceDoc(ServHeader);
    end;

    procedure PerformManualRelease(var ServHeader: Record "Service Header")
    begin
        OnBeforePerformManualRelease(ServHeader);

        CODEUNIT.Run(CODEUNIT::"Release Service Document", ServHeader);

        OnAfterPerformManualRelease(ServHeader);
    end;

    procedure PerformManualReopen(var ServHeader: Record "Service Header")
    begin
        OnBeforePerformManualReopen(ServHeader);
        Reopen(ServHeader);
    end;

    local procedure VerifyLocationCode(var ServLine: Record "Service Line")
    var
        Item: Record Item;
    begin
        if ServLine."No." <> '' then
            if Item.Get(ServLine."No.") then
                if Item.Type = Item.Type::"Non-Inventory" then
                    exit;

        ServLine.TestField("Location Code");
    end;

    internal procedure SetSkipWhseRequestOperations(NewSkipWhseRequestOperations: Boolean)
    begin
        SkipWhseRequestOperations := NewSkipWhseRequestOperations;
    end;

    local procedure CheckServiceItemBlockedForAllAndItemServiceBlocked(var ServiceHeader2: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
        ServOrderManagement: Codeunit ServOrderManagement;
    begin
        ServiceLine.SetRange("Document Type", ServiceHeader2."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader2."No.");
        if ServiceLine.FindSet() then
            repeat
                ServOrderManagement.CheckServiceItemBlockedForAll(ServiceLine);
                ServOrderManagement.CheckItemServiceBlocked(ServiceLine);
            until ServiceLine.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReleaseServiceDoc(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReleaseServiceDoc(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReopenServiceDoc(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReopenServiceDoc(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterCheck(ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNothingToReleaseErr(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPerformManualRelease(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePerformManualReopen(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePerformManualRelease(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeCheckLocationCode(var ServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;
}

