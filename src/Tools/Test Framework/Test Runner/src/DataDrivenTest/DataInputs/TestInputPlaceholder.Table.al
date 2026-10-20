// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

table 130455 "Test Input Placeholder"
{
    Access = Internal;
    DataClassification = CustomerContent;
    DataPerCompany = false;
    ReplicateData = false;

    fields
    {
        field(1; Name; Code[100])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the placeholder name.';
        }
        field(3; Company; Text[30])
        {
            Caption = 'Company';
            ToolTip = 'Specifies the company that uses the placeholder. A blank company makes the value available to all companies.';
        }
        field(4; Value; Blob)
        {
            Caption = 'Value';
            ToolTip = 'Specifies the replacement text.';
        }
    }

    keys
    {
        key(PK; Name, Company)
        {
            Clustered = true;
        }
    }

    internal procedure SetValue(NewValue: Text)
    var
        ValueOutStream: OutStream;
    begin
        Clear(Value);
        Value.CreateOutStream(ValueOutStream, TextEncoding::UTF8);
        ValueOutStream.Write(NewValue);
    end;

    internal procedure GetValue(): Text
    var
        ValueInStream: InStream;
        ValueText: Text;
    begin
        CalcFields(Value);
        if not Value.HasValue() then
            exit('');

        Value.CreateInStream(ValueInStream, TextEncoding::UTF8);
        ValueInStream.Read(ValueText);
        exit(ValueText);
    end;
}
