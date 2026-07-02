// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.History;

using Microsoft.Inventory.Transfer;

codeunit 10461 "Transfer Shpt. Header - Edit"
{
    Permissions = TableData "Transfer Shipment Header" = rm;
    TableNo = "Transfer Shipment Header";

    trigger OnRun()
    var
        TransferShipmentHeader: Record "Transfer Shipment Header";
    begin
        TransferShipmentHeader := Rec;
        TransferShipmentHeader.LockTable();
        TransferShipmentHeader.Find();
        TransferShipmentHeader."CFDI Cancellation Reason Code" := Rec."CFDI Cancellation Reason Code";
        TransferShipmentHeader."Substitution Document No." := Rec."Substitution Document No.";
        TransferShipmentHeader.TestField("No.", Rec."No.");
        TransferShipmentHeader.Modify();
        Rec := TransferShipmentHeader;
    end;
}

