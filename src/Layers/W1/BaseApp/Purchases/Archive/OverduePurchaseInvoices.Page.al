// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

page 10001 "Overdue Purchase Invoices"
{
    ApplicationArea = All;
    Caption = 'Overdue Purchase Invoices';
    CardPageID = "Posted Purchase Invoice";
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = ListPart;
    SourceTable = "Purch. Inv. Header";
    UsageCategory = None;

    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("No."; Rec."No.")
                {
                    ToolTip = 'Specifies the purchase invoice number.';
                }
                field("Pay-to Name"; Rec."Pay-to Name")
                {
                    ToolTip = 'Specifies the name of the vendor to whom the invoice is to be paid.';
                }
                field("Remaining Amount"; Rec."Remaining Amount")
                {
                    ToolTip = 'Specifies the remaining amount of the invoice.';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ToolTip = 'Specifies the date when the invoice is due.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetFilter("Due Date", '<=%1', WorkDate());
    end;
}
