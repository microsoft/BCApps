// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Finance.Currency;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Purchases.Vendor;
using System.Globalization;

table 5005272 "Issued Deliv. Reminder Header"
{
    Caption = 'Issued Deliv. Reminder Header';
    DataCaptionFields = "No.", Name;
    DrillDownPageID = "Issued Delivery Reminders List";
    LookupPageID = "Issued Delivery Reminders List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(2; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;
        }
        field(3; Name; Text[100])
        {
            Caption = 'Name';
        }
        field(4; "Name 2"; Text[50])
        {
            Caption = 'Name 2';
        }
        field(5; Address; Text[100])
        {
            Caption = 'Address';
        }
        field(6; "Address 2"; Text[50])
        {
            Caption = 'Address 2';
        }
        field(7; "Post Code"; Code[20])
        {
            Caption = 'Post Code';
            TableRelation = "Post Code";
            ValidateTableRelation = false;
        }
        field(8; City; Text[30])
        {
            Caption = 'City';
        }
        field(9; County; Text[30])
        {
            Caption = 'County';
        }
        field(10; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(11; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        field(12; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        field(13; Contact; Text[100])
        {
            Caption = 'Contact';
        }
        field(14; "Your Reference"; Text[35])
        {
            Caption = 'Your Reference';
        }
        field(21; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(22; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(24; "Reminder Terms Code"; Code[10])
        {
            Caption = 'Reminder Terms Code';
            TableRelation = "Delivery Reminder Term";
        }
        field(27; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(28; "Reminder Level"; Integer)
        {
            Caption = 'Reminder Level';
        }
        field(29; "Posting Description"; Text[100])
        {
            Caption = 'Posting Description';
        }
        field(30; Comment; Boolean)
        {
            CalcFormula = exist("Delivery Reminder Comment Line" where("Document Type" = const("Issued Delivery Reminder"),
                                                                        "No." = field("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31; "No. Printed"; Integer)
        {
            Caption = 'No. Printed';
            Editable = false;
        }
        field(32; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(37; "Pre-Assigned No. Series"; Code[20])
        {
            Caption = 'Pre-Assigned No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(38; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(39; "Pre-Assigned No."; Code[20])
        {
            Caption = 'Pre-Assigned No.';
        }
        field(40; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Vendor No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Name)
        {
        }
    }

    trigger OnDelete()
    begin
        TestField("No. Printed");
        LockTable();
        DelivReminderIssue.DeleteIssuedDelivReminderLines(Rec);

        DeliveryReminderCommentLine.Reset();
        DeliveryReminderCommentLine.SetRange("Document Type", DeliveryReminderCommentLine."Document Type"::"Issued Delivery Reminder");
        DeliveryReminderCommentLine.SetRange("No.", "No.");
        DeliveryReminderCommentLine.DeleteAll();
    end;

    var
        DeliveryReminderCommentLine: Record "Delivery Reminder Comment Line";
        DelivReminderIssue: Codeunit "Issue Delivery Reminder";
}

