// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

table 130455 "Test Input Placeholder"
{
    Access = Internal;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;
    DataClassification = CustomerContent;
    DataPerCompany = false;
    ReplicateData = false;

    fields
    {
        field(1; Name; Code[250])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the placeholder name.';
        }
        field(3; Company; Text[30])
        {
            Caption = 'Company';
            ToolTip = 'Specifies the company that uses the placeholder. A blank company makes the value available to all companies.';
        }
        field(4; "Placeholder Value"; Blob)
        {
            Caption = 'Placeholder Value';
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
        Clear("Placeholder Value");
        "Placeholder Value".CreateOutStream(ValueOutStream, TextEncoding::UTF8);
        // The terminator lets the line reader retain trailing empty lines.
        ValueOutStream.Write(NewValue);
    end;

    internal procedure GetValue(): Text
    var
        ValueBuilder: TextBuilder;
        ValueInStream: InStream;
        ValueLine: Text;
        FirstLine: Boolean;
    begin
        CalcFields("Placeholder Value");
        if not "Placeholder Value".HasValue() then
            exit('');

        "Placeholder Value".CreateInStream(ValueInStream, TextEncoding::UTF8);
        FirstLine := true;
        while not ValueInStream.EOS() do begin
            ValueInStream.ReadText(ValueLine);
            if not FirstLine then
                ValueBuilder.AppendLine();
            ValueBuilder.Append(ValueLine);
            FirstLine := false;
        end;
        exit(ValueBuilder.ToText());
    end;
}
