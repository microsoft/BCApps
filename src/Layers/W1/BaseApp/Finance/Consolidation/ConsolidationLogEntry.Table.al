// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

using System.Reflection;

table 1834 "Consolidation Log Entry"
{
    Access = Internal;
    Caption = 'Consolidation Log Entry';
    DataClassification = SystemMetadata;
    ReplicateData = false;

    fields
    {
        field(1; "Entry No."; BigInteger)
        {
            AutoIncrement = true;
            DataClassification = SystemMetadata;
        }
        field(2; "Request URI"; Blob)
        {
            DataClassification = SystemMetadata;
        }
        field(3; Response; Blob)
        {
            DataClassification = SystemMetadata;
        }
        field(4; "Status Code"; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(5; "Request URI Preview"; Text[50])
        {
            DataClassification = SystemMetadata;
        }
    }
    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    internal procedure GetRequestAsText(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        Rec.CalcFields("Request URI");
        if not Rec."Request URI".HasValue then
            exit('');
        Rec."Request URI".CreateInStream(InStream, TextEncoding::UTF8);
        exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator()));
    end;

    internal procedure GetResponseAsText(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        Rec.CalcFields(Response);
        if not Rec.Response.HasValue then
            exit('');
        Rec.Response.CreateInStream(InStream, TextEncoding::UTF8);
        exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator()));
    end;

}
