// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Interaction;

table 5122 "Interaction Template Setup"
{
    Caption = 'Interaction Template Setup';
    DataClassification = CustomerContent;
    DrillDownPageID = "Interaction Template Setup";
    LookupPageID = "Interaction Template Setup";    
    ReplicateData = true;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        field(2; "Sales Invoices"; Code[10])
        {
            Caption = 'Sales Invoices';
            ToolTip = 'Specifies the code of the interaction template to use when recording sales invoices as interactions.';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(3; "Sales Cr. Memo"; Code[10])
        {
            Caption = 'Sales Cr. Memo';
            ToolTip = 'Specifies the code of the interaction template to use when recording sales credit memos as interactions.';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(4; "Sales Ord. Cnfrmn."; Code[10])
        {
            Caption = 'Sales Ord. Cnfrmn.';
            ToolTip = 'Specifies the code of the interaction template to use when recording sales order confirmations as interactions.';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(5; "Sales Quotes"; Code[10])
        {
            Caption = 'Sales Quotes';
            ToolTip = 'Specifies the code of the interaction template to use when recording sales quotes as interactions.';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(6; "Purch Invoices"; Code[10])
        {
            Caption = 'Purch Invoices';
            ToolTip = 'Specifies the code of the interaction template to use when recording purchase invoices as interactions.';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(7; "Purch Cr Memos"; Code[10])
        {
            Caption = 'Purch Cr Memos';
            ToolTip = 'Specifies the code of the interaction template to use when recording purchase credit memos as interactions.';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(8; "Purch. Orders"; Code[10])
        {
            Caption = 'Purch. Orders';
            ToolTip = 'Specifies the code of the interaction template to use when recording purchase orders as interactions.';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(9; "Purch. Quotes"; Code[10])
        {
            Caption = 'Purch. Quotes';
            ToolTip = 'Specifies the code of the interaction template to use when recording purchase quotes as interactions.';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(10; "E-Mails"; Code[10])
        {
            Caption = 'Emails';
            ToolTip = 'Specifies the code of the interaction template to use when recording e-mails as interactions.';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(11; "Cover Sheets"; Code[10])
        {
            Caption = 'Cover Sheets';
            ToolTip = 'Specifies the code of the interaction template to use when recording cover sheets as interactions.';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(12; "Outg. Calls"; Code[10])
        {
            Caption = 'Outg. Calls';
            ToolTip = 'Specifies the code of the interaction template to use when recording outgoing phone calls as interactions.';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(13; "Sales Blnkt. Ord"; Code[10])
        {
            Caption = 'Sales Blnkt. Ord';
            ToolTip = 'Specifies the code of the interaction template to use when recording sales blanket orders as interactions.';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(14; "Serv Ord Post"; Code[10])
        {
            Caption = 'Serv Ord Post';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(15; "Sales Shpt. Note"; Code[10])
        {
            Caption = 'Sales Shpt. Note';
            ToolTip = 'Specifies the code of the interaction template to use when recording sales shipment notes as interactions.';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(16; "Sales Statement"; Code[10])
        {
            Caption = 'Sales Statement';
            ToolTip = 'Specifies the code of the interaction template to use when recording sales statements as interactions.';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(17; "Sales Rmdr."; Code[10])
        {
            Caption = 'Sales Rmdr.';
            ToolTip = 'Specifies the code of the interaction template to use when recording sales reminders as interactions.';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(18; "Serv Ord Create"; Code[10])
        {
            Caption = 'Serv Ord Create';
            ToolTip = 'Specifies the code of the interaction template to use when recording the creation of service orders as interactions.';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(19; "Purch Blnkt Ord"; Code[10])
        {
            Caption = 'Purch Blnkt Ord';
            ToolTip = 'Specifies the code of the interaction template to use when recording purchase blanket orders as interactions.';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(20; "Purch. Rcpt."; Code[10])
        {
            Caption = 'Purch. Rcpt.';
            ToolTip = 'Specifies the code of the interaction template to use when recording purchase receipts as interactions.';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(21; "Sales Return Order"; Code[10])
        {
            Caption = 'Sales Return Order';
            ToolTip = 'Specifies the code of the interaction template to use when recording sales return orders as interactions.';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(22; "Sales Return Receipt"; Code[10])
        {
            Caption = 'Sales Return Receipt';
            ToolTip = 'Specifies the code of the interaction template to use when recording sales return receipts as interactions.';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(23; "Sales Finance Charge Memo"; Code[10])
        {
            Caption = 'Sales Finance Charge Memo';
            ToolTip = 'Specifies the code of the interaction template to use when recording sales finance charge memos as interactions.';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(24; "Purch. Return Shipment"; Code[10])
        {
            Caption = 'Purch. Return Shipment';
            ToolTip = 'Specifies the code of the interaction template to use when recording purchase return shipments as interactions.';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(25; "Purch. Return Ord. Cnfrmn."; Code[10])
        {
            Caption = 'Purch. Return Ord. Cnfrmn.';
            ToolTip = 'Specifies the code of the interaction template to use when recording purchase return order confirmations as interactions.';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(27; "Service Contract"; Code[10])
        {
            Caption = 'Service Contract';
            ToolTip = 'Specifies the code of the interaction template to use when recording service contracts as interactions.';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(28; "Service Contract Quote"; Code[10])
        {
            Caption = 'Service Contract Quote';
            ToolTip = 'Specifies the code of the interaction template to use when recording service contract quotes as interactions.';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(29; "Service Quote"; Code[10])
        {
            Caption = 'Service Quote';
            ToolTip = 'Specifies the code of the interaction template to use when recording service quotes as interactions.';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(30; "Meeting Invitation"; Code[10])
        {
            Caption = 'Meeting Invitation';
            ToolTip = 'Specifies the code of the interaction template to use when recording meeting invitations as interactions.';
            TableRelation = "Interaction Template";
        }
        field(35; "E-Mail Draft"; Code[10])
        {
            Caption = 'E-Mail Draft';
            ToolTip = 'Specifies the code of the interaction template to use when recording e-mail draft as interactions.';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(40; "Sales Draft Invoices"; Code[10])
        {
            Caption = 'Sales Draft Invoices';
            ToolTip = 'Specifies the code of the interaction template to use when recording sales draft invoices as interactions.';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

