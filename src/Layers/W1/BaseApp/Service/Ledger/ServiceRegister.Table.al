// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Ledger;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Utilities;
using System.Security.AccessControl;

table 5934 "Service Register"
{
    Caption = 'Service Register';
    LookupPageID = "Service Register";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Integer)
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
        }
        field(2; "From Entry No."; Integer)
        {
            Caption = 'From Entry No.';
            ToolTip = 'Specifies the first item entry number in the register.';
            TableRelation = "Service Ledger Entry";
        }
        field(3; "To Entry No."; Integer)
        {
            Caption = 'To Entry No.';
            ToolTip = 'Specifies the last sequence number from the range of service ledger entries created for this register line.';
            TableRelation = "Service Ledger Entry";
        }
        field(4; "From Warranty Entry No."; Integer)
        {
            Caption = 'From Warranty Entry No.';
            ToolTip = 'Specifies the first sequence number from the range of warranty ledger entries created for this register line.';
            TableRelation = "Warranty Ledger Entry";
        }
        field(5; "To Warranty Entry No."; Integer)
        {
            Caption = 'To Warranty Entry No.';
            ToolTip = 'Specifies the last sequence number from the range of warranty ledger entries created for this register line.';
            TableRelation = "Warranty Ledger Entry";
        }
        field(6; "Creation Date"; Date)
        {
            Caption = 'Creation Date';
            ToolTip = 'Specifies the date when the entries in the register were created.';
        }
        field(7; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
        }
        field(8; "User ID"; Code[50])
        {
            Caption = 'User ID';
            ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(9; "Creation Time"; Time)
        {
            Caption = 'Creation Time';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    [InherentPermissions(PermissionObjectType::TableData, Database::"Service Register", 'r')]
    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("No.")))
    end;
}

