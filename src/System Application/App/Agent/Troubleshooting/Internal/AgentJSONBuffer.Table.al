// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents.Troubleshooting;

table 4300 "Agent JSON Buffer"
{
    TableType = Temporary;
    Access = Internal;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;

    fields
    {
        field(1; Id; Integer)
        {
        }
        field(2; Json; Blob)
        {
        }
    }

    keys
    {
        key(PrimaryKey; Id)
        {
        }
    }

    procedure GetJsonText(): Text
    var
        JsonTextBuilder: TextBuilder;
        JsonTextInStream: InStream;
        JsonTextLine: Text;
    begin
        Rec.CalcFields(Rec.Json);
        Rec.Json.CreateInStream(JsonTextInStream, GetDefaultEncoding());
        while not JsonTextInStream.EOS do begin
            JsonTextInStream.ReadText(JsonTextLine);
            JsonTextBuilder.AppendLine(JsonTextLine);
        end;
        exit(JsonTextBuilder.ToText().Trim());
    end;

    procedure SetJsonText(NewJsonText: Text)
    var
        JsonTextOutstream: OutStream;
    begin
        Clear(Rec.Json);
        Rec.Json.CreateOutStream(JsonTextOutstream, GetDefaultEncoding());
        JsonTextOutstream.WriteText(NewJsonText);
        Rec.Modify(true);
    end;

    procedure SetJson(NewJson: JsonObject)
    var
        JsonText: Text;
    begin
        NewJson.WriteTo(JsonText);
        this.SetJsonText(JsonText);
    end;

    local procedure GetDefaultEncoding(): TextEncoding
    begin
        exit(TextEncoding::UTF8);
    end;
}