// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

table 391 "No. Series Generation"
{
    TableType = Temporary;
    InherentEntitlements = X;
    InherentPermissions = X;

    fields
    {
        field(1; "No."; Integer)
        {
        }
        field(10; "Input Text"; Blob)
        {
        }
    }

    keys
    {
        key(PK; "No.")
        {
        }
    }

    procedure SetInputText(NewText: Text)
    var
        OutStr: OutStream;
    begin
        Rec."Input Text".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(NewText);
    end;

    procedure GetInputText(): Text
    var
        InStr: InStream;
        Result: Text;
    begin
        Rec.CalcFields("Input Text");
        Rec."Input Text".CreateInStream(InStr, TextEncoding::UTF8);
        InStr.ReadText(Result);

        exit(Result);
    end;


}