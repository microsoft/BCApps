// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Interaction;

page 5186 "Interaction Template Setup"
{
    ApplicationArea = RelationshipMgmt;
    Caption = 'Interaction Template Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Interaction Template Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("E-Mails"; Rec."E-Mails")
                {
                    ApplicationArea = Basic, Suite, RelationshipMgmt;
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the code of the interaction template to use when recording e-mails as interactions.';
                }
                field("E-Mail Draft"; Rec."E-Mail Draft")
                {
                    ApplicationArea = Basic, Suite, RelationshipMgmt;
                    ToolTip = 'Specifies the code of the interaction template to use when recording e-mail draft as interactions.';
                }
                field("Cover Sheets"; Rec."Cover Sheets")
                {
                    ApplicationArea = Basic, Suite, RelationshipMgmt;
                    ToolTip = 'Specifies the code of the interaction template to use when recording cover sheets as interactions.';
                }
                field("Outg. Calls"; Rec."Outg. Calls")
                {
                    ApplicationArea = Basic, Suite, RelationshipMgmt;
                    Caption = 'Outgoing Calls';
                    ToolTip = 'Specifies the code of the interaction template to use when recording outgoing phone calls as interactions.';
                }
                field("Meeting Invitation"; Rec."Meeting Invitation")
                {
                    ApplicationArea = Basic, Suite, RelationshipMgmt;
                    ToolTip = 'Specifies the code of the interaction template to use when recording meeting invitations as interactions.';
                }
            }
            group(Sales)
            {
                Caption = 'Sales';
                field("Sales Invoices"; Rec."Sales Invoices")
                {
                    ApplicationArea = Basic, Suite, RelationshipMgmt;
                    Caption = 'Invoices';
                    ToolTip = 'Specifies the code of the interaction template to use when recording sales invoices as interactions.';
                }
                field("Sales Cr. Memo"; Rec."Sales Cr. Memo")
                {
                    ApplicationArea = Basic, Suite, RelationshipMgmt;
                    Caption = 'Credit Memos';
                    ToolTip = 'Specifies the code of the interaction template to use when recording sales credit memos as interactions.';
                }
                field("Sales Ord. Cnfrmn."; Rec."Sales Ord. Cnfrmn.")
                {
                    ApplicationArea = Basic, Suite, RelationshipMgmt;
                    Caption = 'Order Confirmations';
                    ToolTip = 'Specifies the code of the interaction template to use when recording sales order confirmations as interactions.';
                }
                field("Sales Draft Invoices"; Rec."Sales Draft Invoices")
                {
                    ApplicationArea = Basic, Suite, RelationshipMgmt;
                    Caption = 'Draft Invoices';
                    ToolTip = 'Specifies the code of the interaction template to use when recording sales draft invoices as interactions.';
                }
                field("Sales Quotes"; Rec."Sales Quotes")
                {
                    ApplicationArea = Basic, Suite, RelationshipMgmt;
                    Caption = 'Quotes';
                    ToolTip = 'Specifies the code of the interaction template to use when recording sales quotes as interactions.';
                }
                field("Sales Blnkt. Ord"; Rec."Sales Blnkt. Ord")
                {
                    ApplicationArea = Suite, RelationshipMgmt;
                    Caption = 'Blanket Orders';
                    ToolTip = 'Specifies the code of the interaction template to use when recording sales blanket orders as interactions.';
                }
                field("Sales Shpt. Note"; Rec."Sales Shpt. Note")
                {
                    ApplicationArea = Suite;
                    Caption = 'Shipment Notes';
                    ToolTip = 'Specifies the code of the interaction template to use when recording sales shipment notes as interactions.';
                }
                field("Sales Statement"; Rec."Sales Statement")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Statements';
                    ToolTip = 'Specifies the code of the interaction template to use when recording sales statements as interactions.';
                }
                field("Sales Rmdr."; Rec."Sales Rmdr.")
                {
                    ApplicationArea = Suite;
                    Caption = 'Reminders';
                    ToolTip = 'Specifies the code of the interaction template to use when recording sales reminders as interactions.';
                }
                field("Sales Return Order"; Rec."Sales Return Order")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Return Orders';
                    ToolTip = 'Specifies the code of the interaction template to use when recording sales return orders as interactions.';
                }
                field("Sales Return Receipt"; Rec."Sales Return Receipt")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Return Receipts';
                    ToolTip = 'Specifies the code of the interaction template to use when recording sales return receipts as interactions.';
                }
                field("Sales Finance Charge Memo"; Rec."Sales Finance Charge Memo")
                {
                    ApplicationArea = Suite;
                    Caption = 'Finance Charge Memos';
                    ToolTip = 'Specifies the code of the interaction template to use when recording sales finance charge memos as interactions.';
                }
            }
            group(Purchases)
            {
                Caption = 'Purchases';
                field("Purch Invoices"; Rec."Purch Invoices")
                {
                    ApplicationArea = Basic, Suite, RelationshipMgmt;
                    Caption = 'Invoices';
                    ToolTip = 'Specifies the code of the interaction template to use when recording purchase invoices as interactions.';
                }
                field("Purch Cr Memos"; Rec."Purch Cr Memos")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Credit Memos';
                    ToolTip = 'Specifies the code of the interaction template to use when recording purchase credit memos as interactions.';
                }
                field("Purch. Orders"; Rec."Purch. Orders")
                {
                    ApplicationArea = Suite;
                    Caption = 'Orders';
                    ToolTip = 'Specifies the code of the interaction template to use when recording purchase orders as interactions.';
                }
                field("Purch. Quotes"; Rec."Purch. Quotes")
                {
                    ApplicationArea = Suite;
                    Caption = 'Quotes';
                    ToolTip = 'Specifies the code of the interaction template to use when recording purchase quotes as interactions.';
                }
                field("Purch Blnkt Ord"; Rec."Purch Blnkt Ord")
                {
                    ApplicationArea = Suite, RelationshipMgmt;
                    Caption = 'Blanket Orders';
                    ToolTip = 'Specifies the code of the interaction template to use when recording purchase blanket orders as interactions.';
                }
                field("Purch. Rcpt."; Rec."Purch. Rcpt.")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Receipts';
                    ToolTip = 'Specifies the code of the interaction template to use when recording purchase receipts as interactions.';
                }
                field("Purch. Return Shipment"; Rec."Purch. Return Shipment")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Return Shipments';
                    ToolTip = 'Specifies the code of the interaction template to use when recording purchase return shipments as interactions.';
                }
                field("Purch. Return Ord. Cnfrmn."; Rec."Purch. Return Ord. Cnfrmn.")
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Return Order Confirmations';
                    ToolTip = 'Specifies the code of the interaction template to use when recording purchase return order confirmations as interactions.';
                }
            }
            group(Service)
            {
                Caption = 'Service';
                field("Serv Ord Create"; Rec."Serv Ord Create")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Service Order Create';
                    ToolTip = 'Specifies the code of the interaction template to use when recording the creation of service orders as interactions.';
                }
                field("Service Contract"; Rec."Service Contract")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Contracts';
                    ToolTip = 'Specifies the code of the interaction template to use when recording service contracts as interactions.';
                }
                field("Service Contract Quote"; Rec."Service Contract Quote")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Contract Quotes';
                    ToolTip = 'Specifies the code of the interaction template to use when recording service contract quotes as interactions.';
                }
                field("Service Quote"; Rec."Service Quote")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Quotes';
                    ToolTip = 'Specifies the code of the interaction template to use when recording service quotes as interactions.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}

