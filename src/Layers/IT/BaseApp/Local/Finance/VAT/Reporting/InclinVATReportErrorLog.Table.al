// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

table 12196 "Incl. in VAT Report Error Log"
{
    Caption = 'Incl. in VAT Report Error Log';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(21; "Record No."; Integer)
        {
            Caption = 'Record No.';
        }
        field(22; "Field No."; Integer)
        {
            Caption = 'Field No.';
        }
        field(23; "Error Message"; Text[250])
        {
            Caption = 'Error Message';
        }
        field(24; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure InsertError(RecordNo: Integer; FieldNo: Integer; ErrorText: Text[250]; LineNo: Integer)
    begin
        if not FindLast() then;
        "Entry No." += 1;
        "Record No." := RecordNo;
        "Field No." := FieldNo;
        "Error Message" := ErrorText;
        "Line No." := LineNo;
        Insert();
    end;
}


