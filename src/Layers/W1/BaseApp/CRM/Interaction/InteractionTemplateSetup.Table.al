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
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(3; "Sales Cr. Memo"; Code[10])
        {
            Caption = 'Sales Cr. Memo';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(4; "Sales Ord. Cnfrmn."; Code[10])
        {
            Caption = 'Sales Ord. Cnfrmn.';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(5; "Sales Quotes"; Code[10])
        {
            Caption = 'Sales Quotes';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(6; "Purch Invoices"; Code[10])
        {
            Caption = 'Purch Invoices';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(7; "Purch Cr Memos"; Code[10])
        {
            Caption = 'Purch Cr Memos';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(8; "Purch. Orders"; Code[10])
        {
            Caption = 'Purch. Orders';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(9; "Purch. Quotes"; Code[10])
        {
            Caption = 'Purch. Quotes';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(10; "E-Mails"; Code[10])
        {
            Caption = 'Emails';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(11; "Cover Sheets"; Code[10])
        {
            Caption = 'Cover Sheets';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(12; "Outg. Calls"; Code[10])
        {
            Caption = 'Outg. Calls';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(13; "Sales Blnkt. Ord"; Code[10])
        {
            Caption = 'Sales Blnkt. Ord';
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
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(16; "Sales Statement"; Code[10])
        {
            Caption = 'Sales Statement';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(17; "Sales Rmdr."; Code[10])
        {
            Caption = 'Sales Rmdr.';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(18; "Serv Ord Create"; Code[10])
        {
            Caption = 'Serv Ord Create';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(19; "Purch Blnkt Ord"; Code[10])
        {
            Caption = 'Purch Blnkt Ord';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(20; "Purch. Rcpt."; Code[10])
        {
            Caption = 'Purch. Rcpt.';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(21; "Sales Return Order"; Code[10])
        {
            Caption = 'Sales Return Order';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(22; "Sales Return Receipt"; Code[10])
        {
            Caption = 'Sales Return Receipt';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(23; "Sales Finance Charge Memo"; Code[10])
        {
            Caption = 'Sales Finance Charge Memo';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(24; "Purch. Return Shipment"; Code[10])
        {
            Caption = 'Purch. Return Shipment';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(25; "Purch. Return Ord. Cnfrmn."; Code[10])
        {
            Caption = 'Purch. Return Ord. Cnfrmn.';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(27; "Service Contract"; Code[10])
        {
            Caption = 'Service Contract';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(28; "Service Contract Quote"; Code[10])
        {
            Caption = 'Service Contract Quote';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(29; "Service Quote"; Code[10])
        {
            Caption = 'Service Quote';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(30; "Meeting Invitation"; Code[10])
        {
            Caption = 'Meeting Invitation';
            TableRelation = "Interaction Template";
        }
        field(35; "E-Mail Draft"; Code[10])
        {
            Caption = 'E-Mail Draft';
            TableRelation = "Interaction Template" where("Attachment No." = const(0));
        }
        field(40; "Sales Draft Invoices"; Code[10])
        {
            Caption = 'Sales Draft Invoices';
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

