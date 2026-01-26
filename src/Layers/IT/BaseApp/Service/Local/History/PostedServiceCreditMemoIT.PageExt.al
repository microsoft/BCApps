// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

using Microsoft.Foundation.PaymentTerms;

pageextension 12454 "Posted Service Credit Memo IT" extends "Posted Service Credit Memo"
{
    layout
    {
        addafter("Bill-to Customer No.")
        {
            field("Fattura Document Type"; Rec."Fattura Document Type")
            {
                ApplicationArea = Service;
                Editable = false;
                ToolTip = 'Specifies the value to export into the TipoDocument XML node of the Fattura document.';
            }
        }
        addafter("Customer Posting Group")
        {
            field("Payment Method Code"; Rec."Payment Method Code")
            {
                ApplicationArea = Service;
                Editable = false;
                ToolTip = 'Specifies the payment method code for the document.';
            }
            field("Refers to Period"; Rec."Refers to Period")
            {
                ApplicationArea = Service;
                Editable = false;
                ToolTip = 'Specifies the period of time that is used to group and filter the transaction.';
            }
        }
        addafter("EU 3-Party Trade")
        {
            field("Service Tariff No."; Rec."Service Tariff No.")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies the ID of the service tariff that is associated with the service credit memo.';
            }
            field("Transport Method"; Rec."Transport Method")
            {
                ApplicationArea = Service;
                Editable = false;
                ToolTip = 'Specifies the code for the transport method used for the item on this line.';
            }
        }
        addafter("Foreign Trade")
        {
            group(Individual)
            {
                Caption = 'Individual';
                field("Individual Person"; Rec."Individual Person")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies if the customer is an individual person.';
                }
                field(Resident; Rec.Resident)
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies if the individual is a resident or non-resident of Italy.';
                }
                field("First Name"; Rec."First Name")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the first name of the individual person.';
                }
                field("Last Name"; Rec."Last Name")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the last name of the individual person.';
                }
                field("Date of Birth"; Rec."Date of Birth")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the date of birth of the individual person.';
                }
                field("Fiscal Code"; Rec."Fiscal Code")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the fiscal identification code that is assigned by the government to interact with state and public offices and tax authorities.';
                }
            }
        }
        modify("VAT Reporting Date")
        {
            Enabled = false;
            Visible = false;
        }
    }
    actions
    {
        addafter("Service Document Lo&g")
        {
            separator(Action1130001)
            {
            }
            action("Pa&yments")
            {
                ApplicationArea = Service;
                Caption = 'Pa&yments';
                Image = Payment;
                RunObject = Page "Posted Payments";
                RunPageLink = "Sales/Purchase" = const(Service),
                                Type = const("Credit Memo"),
                                Code = field("No.");
                ToolTip = 'View the related payments.';
            }
        }
        addafter(ActivityLog)
        {
            action("Update Document")
            {
                ApplicationArea = Service;
                Caption = 'Update Document';
                Image = Edit;
                ToolTip = 'Add new information that is relevant to the document. You can only edit a few fields because the document has already been posted.';

                trigger OnAction()
                var
                    PostedServCrMemoUpdate: Page "Posted Serv. Cr. Memo - Update";
                begin
                    PostedServCrMemoUpdate.LookupMode := true;
                    PostedServCrMemoUpdate.SetRec(Rec);
                    PostedServCrMemoUpdate.RunModal();
                end;
            }
        }
        addbefore(Category_CategoryPrint)
        {
            actionref("Update Document_Promoted"; "Update Document")
            {
            }
        }
    }
}
