// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Loaner;

using Microsoft.Sales.Customer;
using Microsoft.Service.Document;
using Microsoft.Service.Item;
using Microsoft.Utilities;

table 5914 "Loaner Entry"
{
    Caption = 'Loaner Entry';
    DrillDownPageID = "Loaner Entries";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
        }
        field(2; "Loaner No."; Code[20])
        {
            Caption = 'Loaner No.';
            ToolTip = 'Specifies the number of the loaner.';
            TableRelation = Loaner;
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies the number of the service document specifying the service item you have replaced with the loaner.';
        }
        field(4; "Service Item Line No."; Integer)
        {
            Caption = 'Service Item Line No.';
            ToolTip = 'Specifies the number of the service item line for which you have lent the loaner.';
        }
        field(5; "Service Item No."; Code[20])
        {
            Caption = 'Service Item No.';
            ToolTip = 'Specifies the number of the service item that you have replaced with the loaner.';
            TableRelation = "Service Item";
        }
        field(6; "Service Item Group Code"; Code[10])
        {
            Caption = 'Service Item Group Code';
            ToolTip = 'Specifies the service item group code of the service item that you have replaced with the loaner.';
            TableRelation = "Service Item Group";
        }
        field(7; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            ToolTip = 'Specifies the number of the customer to whom you have lent the loaner.';
            TableRelation = Customer;
        }
        field(8; "Date Lent"; Date)
        {
            Caption = 'Date Lent';
            ToolTip = 'Specifies the date when you lent the loaner.';
        }
        field(9; "Time Lent"; Time)
        {
            Caption = 'Time Lent';
            ToolTip = 'Specifies the time when you lent the loaner.';
        }
        field(10; "Date Received"; Date)
        {
            Caption = 'Date Received';
            ToolTip = 'Specifies the date when you received the loaner.';
        }
        field(11; "Time Received"; Time)
        {
            Caption = 'Time Received';
            ToolTip = 'Specifies the time when you received the loaner.';
        }
        field(12; Lent; Boolean)
        {
            Caption = 'Lent';
            ToolTip = 'Specifies that the loaner is lent.';
        }
        field(14; "Document Type"; Enum "Service Loaner Document Type")
        {
            Caption = 'Document Type';
            ToolTip = 'Specifies whether the document type of the entry is a quote or order.';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Loaner No.", "Document Type", "Document No.")
        {
        }
        key(Key3; "Document Type", "Document No.", "Loaner No.", Lent)
        {
        }
        key(Key4; "Loaner No.", "Date Lent", "Time Lent", "Date Received", "Time Received")
        {
        }
    }

    fieldgroups
    {
    }

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    procedure GetNextEntryNo(): Integer
    begin
        exit(GetLastEntryNo() + 1);
    end;

    procedure GetDocTypeFromServDocType(ServDocType: Enum "Service Document Type"): Enum "Service Loaner Document Type"
    begin
        case ServDocType of
            "Service Document Type"::Quote:
                exit("Service Loaner Document Type"::Quote);
            "Service Document Type"::Order:
                exit("Service Loaner Document Type"::Order);
        end;
    end;

    procedure GetServDocTypeFromDocType(): Enum "Service Document Type"
    begin
        case "Document Type" of
            "Service Loaner Document Type"::Quote:
                exit("Service Document Type"::Quote);
            "Service Loaner Document Type"::Order:
                exit("Service Document Type"::Order);
        end;
    end;
}

