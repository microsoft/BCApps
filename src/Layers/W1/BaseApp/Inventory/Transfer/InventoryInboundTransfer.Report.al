// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Transfer;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;

report 5702 "Inventory - Inbound Transfer"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Inventory/Transfer/InventoryInboundTransfer.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Inventory - Inbound Transfer';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Transfer Line"; "Transfer Line")
        {
            DataItemTableView = sorting("Transfer-to Code", Status, "Derived From Line No.", "Item No.", "Variant Code", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", "Receipt Date", "In-Transit Code") where(Status = const(Released), "Derived From Line No." = const(0));
            RequestFilterFields = "Transfer-to Code", "Item No.", "Receipt Date";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(Location_Name; Location.Name)
            {
            }
            column(TransfertoCode_TransLine; "Transfer-to Code")
            {
            }
            column(Item_Description; Item.Description)
            {
            }
            column(ItemNo_TransLine; "Item No.")
            {
            }
            column(ReceiptDate_TransLine; Format("Receipt Date"))
            {
            }
            column(InTransitCode_TransLine; "In-Transit Code")
            {
                IncludeCaption = true;
            }
            column(QtyinTransit_TransLine; "Qty. in Transit")
            {
                IncludeCaption = true;
            }
            column(DocNo_TransLine; "Document No.")
            {
                IncludeCaption = true;
            }
            column(TransromCode_TransLine; "Transfer-from Code")
            {
                IncludeCaption = true;
            }
            column(OutstandQty_TransLine; "Outstanding Quantity")
            {
                IncludeCaption = true;
            }
            column(ReceiptDate_TransLineCaption; ReceiptDate_TransLineCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Inventory___Inbound_TransferCaption; Inventory___Inbound_TransferCaptionLbl)
            {
            }
            column(TransfertoCode_TransLineCaption; TransfertoCode_TransLineCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                Item.Get("Item No.");
                Location.Get("Transfer-to Code");
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        Item: Record Item;
        Location: Record Location;
        ReceiptDate_TransLineCaptionLbl: Label 'Receipt Date';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Inventory___Inbound_TransferCaptionLbl: Label 'Inventory - Inbound Transfer';
        TransfertoCode_TransLineCaptionLbl: Label 'Transfer-to';
}

