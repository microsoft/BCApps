// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Processing.Import.Purchase;

using Microsoft.Purchases.History;

/// <summary>
/// List page for viewing E-Document Vendor Assignment History records.
/// This page allows users to browse historical vendor information from received e-documents
/// and see which posted purchase invoices they were matched to.
/// </summary>
page 6151 "E-Doc. Vendor Assignment Hist."
{
    PageType = List;
    ApplicationArea = Basic, Suite;
    UsageCategory = Lists;
    SourceTable = "E-Doc. Vendor Assign. History";
    Caption = 'E-Document Vendor Assignment History';
    Editable = false;
    Extensible = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry number of the vendor assignment history record.';
                }
                field("Vendor Company Name"; Rec."Vendor Company Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the company name of the vendor from the e-document.';
                }
                field("Vendor Address"; Rec."Vendor Address")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address of the vendor from the e-document.';
                }
                field("Vendor VAT Id"; Rec."Vendor VAT Id")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT identification number of the vendor from the e-document.';
                }
                field("Vendor GLN"; Rec."Vendor GLN")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Global Location Number (GLN) of the vendor from the e-document.';
                }
                field("Purch. Inv. Header SystemId"; Rec."Purch. Inv. Header SystemId")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the system ID of the posted purchase invoice header that this vendor information was matched to.';
                    Visible = false;
                }
                field("Vendor No From Purch. Header"; Rec."Vendor No From Purch. Header")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor number from the purchase header that this vendor information was matched to.';
                }
            }
        }
    }
    actions
    {
        area(Navigation)
        {
            action(OpenPurchaseInvoice)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Open Purchase Invoice';
                ToolTip = 'Open the posted purchase invoice that this vendor information was matched to.';
                Image = Invoice;

                trigger OnAction()
                var
                    PurchInvHeader: Record "Purch. Inv. Header";
                begin
                    if IsNullGuid(Rec."Purch. Inv. Header SystemId") then
                        exit;
                    PurchInvHeader.GetBySystemId(Rec."Purch. Inv. Header SystemId");
                    Page.Run(Page::"Posted Purchase Invoice", PurchInvHeader);
                end;
            }
        }
        area(Promoted)
        {
            actionref(OpenPurchaseInvoice_Promoted; OpenPurchaseInvoice)
            {
            }
        }
    }
}