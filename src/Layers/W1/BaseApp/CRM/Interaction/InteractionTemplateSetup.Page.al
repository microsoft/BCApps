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
                }
                field("E-Mail Draft"; Rec."E-Mail Draft")
                {
                    ApplicationArea = Basic, Suite, RelationshipMgmt;
                }
                field("Cover Sheets"; Rec."Cover Sheets")
                {
                    ApplicationArea = Basic, Suite, RelationshipMgmt;
                }
                field("Outg. Calls"; Rec."Outg. Calls")
                {
                    ApplicationArea = Basic, Suite, RelationshipMgmt;
                    Caption = 'Outgoing Calls';
                }
                field("Meeting Invitation"; Rec."Meeting Invitation")
                {
                    ApplicationArea = Basic, Suite, RelationshipMgmt;
                }
            }
            group(Sales)
            {
                Caption = 'Sales';
                field("Sales Invoices"; Rec."Sales Invoices")
                {
                    ApplicationArea = Basic, Suite, RelationshipMgmt;
                    Caption = 'Invoices';
                }
                field("Sales Cr. Memo"; Rec."Sales Cr. Memo")
                {
                    ApplicationArea = Basic, Suite, RelationshipMgmt;
                    Caption = 'Credit Memos';
                }
                field("Sales Ord. Cnfrmn."; Rec."Sales Ord. Cnfrmn.")
                {
                    ApplicationArea = Basic, Suite, RelationshipMgmt;
                    Caption = 'Order Confirmations';
                }
                field("Sales Draft Invoices"; Rec."Sales Draft Invoices")
                {
                    ApplicationArea = Basic, Suite, RelationshipMgmt;
                    Caption = 'Draft Invoices';
                }
                field("Sales Quotes"; Rec."Sales Quotes")
                {
                    ApplicationArea = Basic, Suite, RelationshipMgmt;
                    Caption = 'Quotes';
                }
                field("Sales Blnkt. Ord"; Rec."Sales Blnkt. Ord")
                {
                    ApplicationArea = Suite, RelationshipMgmt;
                    Caption = 'Blanket Orders';
                }
                field("Sales Shpt. Note"; Rec."Sales Shpt. Note")
                {
                    ApplicationArea = Suite;
                    Caption = 'Shipment Notes';
                }
                field("Sales Statement"; Rec."Sales Statement")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Statements';
                }
                field("Sales Rmdr."; Rec."Sales Rmdr.")
                {
                    ApplicationArea = Suite;
                    Caption = 'Reminders';
                }
                field("Sales Return Order"; Rec."Sales Return Order")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Return Orders';
                }
                field("Sales Return Receipt"; Rec."Sales Return Receipt")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Return Receipts';
                }
                field("Sales Finance Charge Memo"; Rec."Sales Finance Charge Memo")
                {
                    ApplicationArea = Suite;
                    Caption = 'Finance Charge Memos';
                }
            }
            group(Purchases)
            {
                Caption = 'Purchases';
                field("Purch Invoices"; Rec."Purch Invoices")
                {
                    ApplicationArea = Basic, Suite, RelationshipMgmt;
                    Caption = 'Invoices';
                }
                field("Purch Cr Memos"; Rec."Purch Cr Memos")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Credit Memos';
                }
                field("Purch. Orders"; Rec."Purch. Orders")
                {
                    ApplicationArea = Suite;
                    Caption = 'Orders';
                }
                field("Purch. Quotes"; Rec."Purch. Quotes")
                {
                    ApplicationArea = Suite;
                    Caption = 'Quotes';
                }
                field("Purch Blnkt Ord"; Rec."Purch Blnkt Ord")
                {
                    ApplicationArea = Suite, RelationshipMgmt;
                    Caption = 'Blanket Orders';
                }
                field("Purch. Rcpt."; Rec."Purch. Rcpt.")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Receipts';
                }
                field("Purch. Return Shipment"; Rec."Purch. Return Shipment")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Return Shipments';
                }
                field("Purch. Return Ord. Cnfrmn."; Rec."Purch. Return Ord. Cnfrmn.")
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Return Order Confirmations';
                }
            }
            group(Service)
            {
                Caption = 'Service';
                field("Serv Ord Create"; Rec."Serv Ord Create")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Service Order Create';
                }
                field("Service Contract"; Rec."Service Contract")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Contracts';
                }
                field("Service Contract Quote"; Rec."Service Contract Quote")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Contract Quotes';
                }
                field("Service Quote"; Rec."Service Quote")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Quotes';
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

