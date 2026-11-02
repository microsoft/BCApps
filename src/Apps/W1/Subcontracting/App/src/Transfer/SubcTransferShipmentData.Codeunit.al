// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Transfer;

codeunit 20509 "Subc. Transfer Shipment Data"
{
    Access = Internal;

    procedure GetHeaderData(TransferShipmentHeader: Record "Transfer Shipment Header"; var SubcontractorNo: Code[20]; var SubcontractorName: Text[100]; var SubcontractorAddressValue: Text[100]; var SubcontractorAddress: array[8] of Text[100]; var SubcontractPurchaseOrderNo: Code[20])
    begin
        Clear(SubcontractorNo);
        Clear(SubcontractorName);
        Clear(SubcontractorAddressValue);
        Clear(SubcontractorAddress);
        Clear(SubcontractPurchaseOrderNo);

        if TransferShipmentHeader."Subc. Source Type" <> TransferShipmentHeader."Subc. Source Type"::Subcontracting then
            exit;

        SubcontractorNo := TransferShipmentHeader."Source ID";
        if TransferShipmentHeader."Subc. Return Order" then begin
            SubcontractorName := TransferShipmentHeader."Transfer-from Name";
            SubcontractorAddressValue := TransferShipmentHeader."Transfer-from Address";
            SubcontractorAddress[1] := TransferShipmentHeader."Transfer-from Address";
            SubcontractorAddress[2] := TransferShipmentHeader."Transfer-from Address 2";
            SubcontractorAddress[3] := TransferShipmentHeader."Transfer-from City";
            SubcontractorAddress[4] := TransferShipmentHeader."Transfer-from Post Code";
            SubcontractorAddress[5] := TransferShipmentHeader."Transfer-from County";
            SubcontractorAddress[6] := TransferShipmentHeader."Trsf.-from Country/Region Code";
            SubcontractorAddress[7] := TransferShipmentHeader."Transfer-from Contact";
        end else begin
            SubcontractorName := TransferShipmentHeader."Transfer-to Name";
            SubcontractorAddressValue := TransferShipmentHeader."Transfer-to Address";
            SubcontractorAddress[1] := TransferShipmentHeader."Transfer-to Address";
            SubcontractorAddress[2] := TransferShipmentHeader."Transfer-to Address 2";
            SubcontractorAddress[3] := TransferShipmentHeader."Transfer-to City";
            SubcontractorAddress[4] := TransferShipmentHeader."Transfer-to Post Code";
            SubcontractorAddress[5] := TransferShipmentHeader."Transfer-to County";
            SubcontractorAddress[6] := TransferShipmentHeader."Trsf.-to Country/Region Code";
            SubcontractorAddress[7] := TransferShipmentHeader."Transfer-to Contact";
        end;
        SubcontractPurchaseOrderNo := TransferShipmentHeader."Subcontr. Purch. Order No.";
    end;
}
