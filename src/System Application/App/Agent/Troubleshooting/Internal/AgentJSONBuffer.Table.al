// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents.Troubleshooting;

using System.Agents;

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
        AgentTaskImpl: Codeunit "Agent Task Impl.";
        JsonTextInStream: InStream;
    begin
        Rec.CalcFields(Rec.Json);
        Rec.Json.CreateInStream(JsonTextInStream, GetDefaultEncoding());
        exit(AgentTaskImpl.ReadStreamToEnd(JsonTextInStream).Trim());
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