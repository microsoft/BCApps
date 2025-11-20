// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.Setup;
using Microsoft.Sales.Document;

codeunit 99000777 "Check Prod. Order Status"
{
    Permissions = tabledata "Manufacturing Setup" = r;

    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'The update has been interrupted to respect the warning.';
#pragma warning restore AA0074

    procedure SalesLineCheck(SalesLine: Record "Sales Line")
    var
        Item: Record Item;
        CheckProdOrderStatus: Page "Check Prod. Order Status";
        OK: Boolean;
    begin
        if GuiAllowed then
            if CheckProdOrderStatus.SalesLineShowWarning(SalesLine) then begin
                Item.Get(SalesLine."No.");
                CheckProdOrderStatus.SetRecord(Item);
                OK := CheckProdOrderStatus.RunModal() = ACTION::Yes;
                Clear(CheckProdOrderStatus);
                if not OK then
                    Error(Text000);
            end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnCheckReceiptOrderStatus', '', true, true)]
    local procedure OnCheckReceiptOrderStatus(var SalesLine: Record "Sales Line")
    begin
        CheckReceiptOrderStatus(SalesLine);
    end;

    procedure CheckReceiptOrderStatus(var SalesLine: Record "Sales Line")
    var
#if not CLEAN27
        AddonIntegrManagement: Codeunit Microsoft.Inventory.AddOnIntegrManagement;
#endif
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckReceiptOrderStatus(SalesLine, IsHandled);
#if not CLEAN27
        AddonIntegrManagement.RunOnBeforeCheckReceiptOrderStatus(SalesLine, IsHandled);
#endif
        if IsHandled then
            exit;

        if SalesLine."Document Type" <> SalesLine."Document Type"::Order then
            exit;

        if SalesLine.Type <> SalesLine.Type::Item then
            exit;

        SalesLineCheck(SalesLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckReceiptOrderStatus(SalesLine: Record "Sales Line"; var Checked: Boolean)
    begin
    end;
}

