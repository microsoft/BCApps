// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import.Purchase;

using Microsoft.Purchases.Document;

page 6117 "Vendor Order Lines"
{
    ApplicationArea = All;
    PageType = List;
    SourceTable = "Purchase Line";
    Caption = 'Purchase Order Lines';
    SourceTableView = where("Document Type" = const("Purchase Document Type"::Order));
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                    Caption = 'Order No.';
                    ToolTip = 'Specifies the document number of the purchase order.';
                    DrillDownPageId = "Purchase Order";
                }
                field("Type"; Rec.Type)
                {
                    ApplicationArea = All;
                    Caption = 'Type';
                    ToolTip = 'Specifies the type of the purchase line.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Caption = 'No.';
                    ToolTip = 'Specifies the number of the purchase line.';
                }
                field("Description"; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                    ToolTip = 'Specifies the description for the purchase line.';
                }
                field("Quantity"; Rec.Quantity)
                {
                    ApplicationArea = All;
                    Caption = 'Quantity';
                    ToolTip = 'Specifies the quantity for the purchase line.';
                }
                field("Quantity Invoiced"; Rec."Quantity Invoiced")
                {
                    ApplicationArea = All;
                    Caption = 'Quantity Invoiced';
                    ToolTip = 'Specifies the quantity that has been invoiced for the purchase line.';
                }
                field("Unit Price"; Rec."Direct Unit Cost")
                {
                    ApplicationArea = All;
                    Caption = 'Unit Price';
                    ToolTip = 'Specifies the direct unit cost for the purchase line.';
                }
                field("Amount"; Rec.Amount)
                {
                    ApplicationArea = All;
                    Caption = 'Amount';
                    ToolTip = 'Specifies the total amount for the purchase line.';
                }
            }
        }
    }

    procedure SetVendor(VendorNo: Code[20])
    begin
        Rec.SetRange("Buy-from Vendor No.", VendorNo);
    end;

}