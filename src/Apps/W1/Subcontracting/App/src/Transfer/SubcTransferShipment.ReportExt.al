// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Transfer;

reportextension 20500 "Subc. Transfer Shipment" extends "Transfer Shipment"
{
    dataset
    {
        add("Transfer Shipment Header")
        {
            column(SubcVendorNo; SubcontractorNo)
            {
            }
            column(SubcVendorName; SubcontractorName)
            {
            }
            column(SubcVendorAddress; SubcontractorAddressValue)
            {
            }
            column(SubcVendorAddress1; SubcontractorAddress[1])
            {
            }
            column(SubcVendorAddress2; SubcontractorAddress[2])
            {
            }
            column(SubcVendorAddress3; SubcontractorAddress[3])
            {
            }
            column(SubcVendorAddress4; SubcontractorAddress[4])
            {
            }
            column(SubcVendorAddress5; SubcontractorAddress[5])
            {
            }
            column(SubcVendorAddress6; SubcontractorAddress[6])
            {
            }
            column(SubcVendorAddress7; SubcontractorAddress[7])
            {
            }
            column(SubcVendorAddress8; SubcontractorAddress[8])
            {
            }
            column(SubcPurchaseOrderNo; SubcontractPurchaseOrderNo)
            {
            }
            column(SubcVendorNoLbl; SubcontractorNoLbl)
            {
            }
            column(SubcVendorLbl; SubcontractorLbl)
            {
            }
            column(SubcPurchaseOrderNoLbl; SubcontractPurchaseOrderNoLbl)
            {
            }
        }
        add("Transfer Shipment Line")
        {
            column(SubcProductionOrderNo; "Subc. Prod. Order No.")
            {
            }
            column(SubcProductionOrderNoLbl; SubcontractProductionOrderNoLbl)
            {
            }
        }
        modify("Transfer Shipment Header")
        {
            trigger OnBeforePreDataItem()
            begin
                AddLoadFields(
                    "Subc. Source Type", "Source ID", "Subc. Return Order",
                    "Transfer-from Name", "Transfer-from Address", "Transfer-from Address 2",
                    "Transfer-from City", "Transfer-from Post Code", "Transfer-from County",
                    "Trsf.-from Country/Region Code", "Transfer-from Contact",
                    "Transfer-to Name", "Transfer-to Address", "Transfer-to Address 2",
                    "Transfer-to City", "Transfer-to Post Code", "Transfer-to County",
                    "Trsf.-to Country/Region Code", "Transfer-to Contact", "Subcontr. Purch. Order No.");
            end;

            trigger OnAfterAfterGetRecord()
            var
                SubcTransferShipmentData: Codeunit "Subc. Transfer Shipment Data";
            begin
                SubcTransferShipmentData.GetHeaderData(
                    "Transfer Shipment Header", SubcontractorNo, SubcontractorName, SubcontractorAddressValue,
                    SubcontractorAddress, SubcontractPurchaseOrderNo);
            end;
        }
    }

    rendering
    {
        layout(SubcontractingTransferShipment)
        {
            Type = RDLC;
            Caption = 'Subcontracting Transfer Shipment';
            Summary = 'Shows subcontractor and manufacturing references for posted subcontracting transfer shipments.';
            LayoutFile = './src/Transfer/SubcTransferShipment.rdlc';
        }
    }

    var
        SubcontractorAddress: array[8] of Text[100];
        SubcontractorAddressValue: Text[100];
        SubcontractorName: Text[100];
        SubcontractorNo: Code[20];
        SubcontractPurchaseOrderNo: Code[20];
        SubcontractorLbl: Label 'Subcontractor';
        SubcontractorNoLbl: Label 'Subcontractor No.';
        SubcontractProductionOrderNoLbl: Label 'Production Order No.';
        SubcontractPurchaseOrderNoLbl: Label 'Subcontract Purchase Order No.';
}
