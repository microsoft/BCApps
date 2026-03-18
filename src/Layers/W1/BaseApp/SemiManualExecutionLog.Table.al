// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.TestTools;

table 130416 "Semi-Manual Execution Log"
{
    Caption = 'Semi-Manual Execution Log';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Time stamp"; DateTime)
        {
            Caption = 'Time stamp';
        }
        field(2; "Step description 1"; Text[250])
        {
            Caption = 'Step description 1';
        }
        field(3; "Step description 2"; Text[250])
        {
            Caption = 'Step description 2';
        }
        field(4; "Step description 3"; Text[250])
        {
            Caption = 'Step description 3';
        }
        field(5; "Step description 4"; Text[250])
        {
            Caption = 'Step description 4';
        }
        field(6; Id; Integer)
        {
            AutoIncrement = true;
            Caption = 'Id';
        }
    }

    keys
    {
        key(Key1; Id)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure Log(Message: Text[1000])
    begin
        Init();
        Id := 0;
        "Time stamp" := CurrentDateTime;
        "Step description 1" := CopyStr(Message, 1, 250);
        "Step description 2" := CopyStr(Message, 251, 250);
        "Step description 3" := CopyStr(Message, 501, 250);
        "Step description 4" := CopyStr(Message, 751, 250);
        Insert();
        Commit();
    end;

    [Scope('OnPrem')]
    procedure GetMessage(): Text[1000]
    begin
        exit("Step description 1" + "Step description 2" + "Step description 3" + "Step description 4");
    end;
}

