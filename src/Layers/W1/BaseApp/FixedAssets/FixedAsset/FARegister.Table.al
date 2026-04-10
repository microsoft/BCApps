// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Ledger;

using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Utilities;
using System.Security.AccessControl;

table 5617 "FA Register"
{
    Caption = 'FA Register';
    LookupPageID = "FA Registers";
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
            TableRelation = "FA Ledger Entry";
        }
        field(3; "To Entry No."; Integer)
        {
            Caption = 'To Entry No.';
            ToolTip = 'Specifies the last FA entry number in the register.';
            TableRelation = "FA Ledger Entry";
        }
        /// <summary>
        /// The Creation Date field has been replaced with the SystemCreateAt field but needs to be kept for historical audit purposes.
        /// </summary>
        field(4; "Creation Date"; Date)
        {
            Caption = 'Creation Date';
        }
        field(5; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            ToolTip = 'Specifies the source code that specifies where the entry was created.';
            TableRelation = "Source Code";
        }
        field(6; "User ID"; Code[50])
        {
            Caption = 'User ID';
            ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(7; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            ToolTip = 'Specifies the name of the journal batch, a personalized journal layout, that the entries were posted from.';
        }
        field(8; "Journal Type"; Enum "FA Journal Type")
        {
            Caption = 'Journal Type';
            ToolTip = 'Specifies the type of journal (G/L or Fixed Asset) that the entries were posted from.';
        }
        field(9; "G/L Register No."; Integer)
        {
            BlankZero = true;
            Caption = 'G/L Register No.';
            ToolTip = 'Specifies the number of the G/L register that was created when the entries were posted.';
            TableRelation = "G/L Register";
        }
        field(10; "From Maintenance Entry No."; Integer)
        {
            Caption = 'From Maintenance Entry No.';
            ToolTip = 'Specifies the first maintenance entry number in the register.';
            TableRelation = "Maintenance Ledger Entry";
        }
        field(11; "To Maintenance Entry No."; Integer)
        {
            Caption = 'To Maintenance Entry No.';
            ToolTip = 'Specifies the last maintenance entry number in the register.';
            TableRelation = "Maintenance Ledger Entry";
        }
#if not CLEANSCHEMA27
        field(13; "Creation Time"; Time)
        {
            Caption = 'Creation Time';
            ObsoleteState = Removed;
            ObsoleteTag = '27.0';
            ObsoleteReason = 'Use the system audit field "System Created at" instead.';
        }
#endif
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key3; "Source Code", "Journal Batch Name")
        {
        }
    }

    fieldgroups
    {
    }

    [InherentPermissions(PermissionObjectType::TableData, Database::"FA Register", 'r')]
    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("No.")))
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"FA Register", 'r')]
    procedure GetLastGLRegisterNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("G/L Register No.")))
    end;

}
