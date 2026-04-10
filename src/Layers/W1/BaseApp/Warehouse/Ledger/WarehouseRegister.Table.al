// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Ledger;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Journal;
using Microsoft.Utilities;
using System.Security.AccessControl;

table 7313 "Warehouse Register"
{
    Caption = 'Warehouse Register';
    LookupPageID = "Warehouse Registers";
    InherentPermissions = r;
    Permissions = TableData "Warehouse Register" = i;
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
            Caption = 'First Entry No.';
            ToolTip = 'Specifies the first item entry number in the register.';
            TableRelation = "Warehouse Entry";
        }
        field(3; "To Entry No."; Integer)
        {
            Caption = 'Last Entry No.';
            ToolTip = 'Specifies the last warehouse entry number in the register.';
            TableRelation = "Warehouse Entry";
        }
        field(4; "Creation Date"; Date)
        {
            Caption = 'Creation Date';
            ToolTip = 'Specifies the date on which the entries in the register were posted.';
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
            TableRelation = "Item Journal Batch".Name;
        }
        field(9; "Creation Time"; Time)
        {
            Caption = 'Creation Time';
            ToolTip = 'Specifies the time on which the entries in the register were posted.';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Source Code")
        {
        }
    }

    fieldgroups
    {
    }

 #if not CLEAN27
   [Obsolete('This function is deprecated. Concurrent warehouse posting is always on.', '27.0')]
   procedure InsertRecord(UseLegacyPosting: Boolean)
    begin
        InsertRecord();
    end;
#endif    

    [InherentPermissions(PermissionObjectType::TableData, Database::"Warehouse Register", 'r')]
    procedure InsertRecord()
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        if not Rec.Insert() then begin
            SequenceNoMgt.RebaseSeqNo(Database::"Warehouse Register");
            "No." := SequenceNoMgt.GetNextSeqNo(Database::"Warehouse Register");
            Rec.Insert();
        end;
    end;

    procedure GetNextEntryNo(UseLegacyPosting: Boolean): Integer
    begin
        if not UseLegacyPosting then
            exit(GetNextEntryNo());
        Rec.LockTable();
        exit(GetLastEntryNo() + 1);
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Warehouse Register", 'r')]
    procedure GetNextEntryNo(): Integer
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        exit(SequenceNoMgt.GetNextSeqNo(Database::"Warehouse Register"));
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Warehouse Register", 'r')]
    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("No.")))
    end;

    procedure Lock()
    begin
        LockTable();
        if FindLast() then;
    end;
}

