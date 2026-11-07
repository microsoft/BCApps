// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Utilities;

table 9160 TempStack
{
    Caption = 'TempStack';
    DataClassification = CustomerContent;

    fields
    {
        field(1; StackOrder; Integer)
        {
            Caption = 'StackOrder';
        }
        field(2; Value; RecordID)
        {
            Caption = 'Value';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; StackOrder)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        LastIndex: Integer;

    procedure Push(NewValue: RecordID)
    begin
        Validate(StackOrder, LastIndex);
        Validate(Value, NewValue);
        Insert();
        LastIndex := LastIndex + 1;
    end;

    procedure Pop(var TopValue: RecordID): Boolean
    begin
        if FindLast() then begin
            TopValue := Value;
            Delete();
            LastIndex := LastIndex - 1;
            exit(true);
        end;
        exit(false);
    end;

    procedure Peek(var TopValue: RecordID): Boolean
    begin
        if FindLast() then begin
            TopValue := Value;
            exit(true);
        end;
        exit(false);
    end;
}

