#if not CLEANSCHEMA31
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Ledger;

using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Foundation.AuditCodes;

table 10551 "BACS Register"
{
    Caption = 'BACS Register';
    LookupPageID = "G/L Registers";
    DataClassification = CustomerContent;
    ObsoleteReason = 'No longer required';
#if not CLEAN28
    ObsoleteState = Pending;
    ObsoleteTag = '28.0';
#else
    ObsoleteState = Removed;
    ObsoleteTag = '31.0';
#endif

    fields
    {
        field(1; "No."; Integer)
        {
            Caption = 'No.';
        }
        field(2; "From BACS Entry No."; Integer)
        {
            Caption = 'From BACS Entry No.';
            TableRelation = "BACS Ledger Entry";
        }
        field(3; "To BACS Entry No."; Integer)
        {
            Caption = 'To BACS Entry No.';
            TableRelation = "BACS Ledger Entry";
        }
        field(4; "Creation Date"; Date)
        {
            Caption = 'Creation Date';
        }
        field(5; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
        }
        field(6; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(7; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
        }
        field(15; "BACS File"; BLOB)
        {
            Caption = 'BACS File';
        }
        field(20; "Ledger Entry Amount"; Decimal)
        {
            CalcFormula = sum("BACS Ledger Entry".Amount where("Register No." = field("No.")));
            Caption = 'Ledger Entry Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(21; Reconciled; Boolean)
        {
            CalcFormula = - exist("BACS Ledger Entry" where("Register No." = field("No."),
                                                            "Statement Status" = filter(<> Closed)));
            Caption = 'Reconciled';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Creation Date")
        {
        }
        key(Key3; "Source Code", "Journal Batch Name", "Creation Date")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "From BACS Entry No.", "To BACS Entry No.", "Creation Date", "Source Code")
        {
        }
    }

    var
        Text001: Label 'You must specify a file name.';
        Text002: Label 'Do you want to replace the existing file?';
        Text003: Label 'Import Cancelled.';
        Text005: Label 'There is no BACS file.';
        Text006: Label 'Do you want to delete this BACS file?';
        Text007: Label 'Delete cancelled.';
        BACSFile: File;
        NVInstream: InStream;
        NVOutStream: OutStream;

    [Scope('OnPrem')]
    procedure ImportBACSFile(FileName: Text; ShowCommonDialog: Boolean)
    begin
        if FileName = '' then
            if not ShowCommonDialog then
                Error(Text001);

        CalcFields("BACS File");
        if "BACS File".HasValue() then
            if not Confirm(Text002) then
                Error(Text003);

        "BACS File".CreateOutStream(NVOutStream);
        BACSFile.Open(FileName);
        BACSFile.CreateInStream(NVInstream);
        CopyStream(NVOutStream, NVInstream);
        BACSFile.Close();
    end;

    [Scope('OnPrem')]
    procedure DeleteBACSFile()
    begin
        CalcFields("BACS File");
        if not "BACS File".HasValue() then
            Error(Text005);

        if not Confirm(Text006) then
            Error(Text007);
        Clear("BACS File");
    end;
}
#endif

