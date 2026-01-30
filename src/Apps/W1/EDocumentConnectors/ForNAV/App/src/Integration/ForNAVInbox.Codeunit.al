// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.ForNAV;

using Microsoft.EServices.EDocument;
using Microsoft.eServices.EDocument.Integration.Receive;
using Microsoft.eServices.EDocument.Integration.Send;
using System.Utilities;

codeunit 6417 "ForNAV Inbox"
{
    Access = Internal;

    internal procedure GetEvidence(EDocument: Record "E-Document"; SendContext: Codeunit SendContext): Boolean
    var
        Incoming: Record "ForNAV Incoming E-Document";
        EDocumentErrorHelper: Codeunit "E-Document Error Helper";
        Error: BigText;
        InStr: InStream;
    begin
        Incoming.SetRange(DocType, Incoming.DocType::Evidence);
        Incoming.SetRange(Incoming.ID, EDocument."ForNAV Edoc. ID");
        if Incoming.FindFirst() then begin
            if Incoming.Status = Incoming.Status::Send then
                exit(true);

            Incoming.CalcFields(Message);
            Incoming.Message.CreateInStream(InStr, TextEncoding::UTF8);
            Error.Read(InStr);
            EDocumentErrorHelper.LogSimpleErrorMessage(EDocument, Format(Error));
        end;
        exit(false);
    end;

    internal procedure DeleteDocs(var DocumentIds: JsonArray; SendContext: Codeunit SendContext): Boolean
    var
        Incoming: Record "ForNAV Incoming E-Document";
        DocumentIdToken: JsonToken;
    begin
        foreach DocumentIdToken in DocumentIds do begin
            Incoming.SetRange(ID, DocumentIdToken.AsValue().AsText());
            Incoming.SetFilter(Status, '%1|%2|%3', Incoming.Status::Received, Incoming.Status::Approved, Incoming.Status::Rejected);
            if Incoming.FindSet() then
                repeat
                    Incoming.Status := Incoming.Status::Processed;
                    Incoming.Modify();
                until Incoming.Next() <> 1;
        end;

        exit(true);
    end;

    local procedure GetForNAVIncomingEDocuments(var Incoming: Record "ForNAV Incoming E-Document"; DocumentsMetadata: Codeunit "Temp Blob List"): Boolean
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        Incoming.SetFilter(Status, '%1|%2|%3', Incoming.Status::Received, Incoming.Status::Approved, Incoming.Status::Rejected);
        if not Incoming.FindSet() then
            exit(false);

        repeat
            Clear(TempBlob);
            TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
            OutStr.WriteText(Incoming.ID);
            DocumentsMetadata.Add(TempBlob);
        until Incoming.Next() = 0;
        exit(true);
    end;

    internal procedure GetIncomingBussinessDocs(DocumentsMetadata: Codeunit "Temp Blob List"): Boolean
    var
        Incoming: Record "ForNAV Incoming E-Document";
    begin
        Incoming.SetFilter(Incoming.DocType, '%1|%2', Incoming.DocType::CreditNote, Incoming.DocType::Invoice);
        exit(GetForNAVIncomingEDocuments(Incoming, DocumentsMetadata));
    end;

    internal procedure GetIncomingAppResponseDocs(EDocument: Record "E-Document"; DocumentsMetadata: Codeunit "Temp Blob List"): Boolean
    var
        Incoming: Record "ForNAV Incoming E-Document";
    begin
        Incoming.SetRange(Incoming.DocType, Incoming.DocType::ApplicationResponse);
        exit(GetForNAVIncomingEDocuments(Incoming, DocumentsMetadata));
    end;

    internal procedure GetForNAVIncomingEDocument(DocumentId: Text; ReceiveContext: Codeunit ReceiveContext): Boolean
    var
        Incoming: Record "ForNAV Incoming E-Document";
        output: Text;
    begin
        Incoming.SetRange(Incoming.ID, DocumentId);
        if Incoming.FindFirst() then begin
            output := Incoming.GetDoc();
            ReceiveContext.Http().GetHttpResponseMessage().Content.WriteFrom(output);
        end;

        exit(ReceiveContext.Http().GetHttpResponseMessage().IsSuccessStatusCode);
    end;

    internal procedure GetApprovalStatus(EDocument: Record "E-Document"; var StatusDescription: Text) Status: Enum "ForNAV Incoming E-Doc Status"
    var
        Incoming: Record "ForNAV Incoming E-Document";
    begin
        Incoming.SetRange(DocType, Incoming.DocType::ApplicationResponse);
        Incoming.SetRange(Incoming.ID, EDocument."ForNAV Edoc. ID");

        if Incoming.FindFirst() then begin
            Status := Incoming.Status;
            StatusDescription := Incoming.GetComment();
        end;
    end;

    local procedure GetOptionValue(FieldRef: FieldRef; StringValue: Text): Integer
    var
        Index: Integer;
    begin
        for Index := 1 to FieldRef.EnumValueCount() do
            if FieldRef.GetEnumValueName(Index) = StringValue then
                exit(FieldRef.GetEnumValueOrdinal(Index))
    end;

    local procedure InsertDocFromJson(RecRef: RecordRef; RecordObject: JsonObject)
    var
        TempBlob: Codeunit "Temp Blob";
        BT: BigText;
        FieldRef: FieldRef;
        i: Integer;
        Token: JsonToken;
        Value: JsonValue;
        OutStr: OutStream;
    begin
        for i := 1 to RecRef.FieldCount do begin
            FieldRef := RecRef.Field(i);
            if RecordObject.Get(FieldRef.Name, Token) then begin
                Value := Token.AsValue();
                if not Value.IsNull then
                    case FieldRef.Type of
                        FieldType::Integer:
                            FieldRef.Value := Value.AsInteger();
                        FieldType::Text:
                            FieldRef.Value := Value.AsText();
                        FieldType::Option:
                            FieldRef.Value := GetOptionValue(FieldRef, Value.AsText());
                        FieldType::Blob:
                            begin
                                Clear(BT);
                                BT.AddText(Value.AsText());
                                TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
                                BT.Write(OutStr);
                                TempBlob.ToFieldRef(FieldRef);
                            end;
                    end;
            end;
        end;

        RecRef.SetRecFilter();
        if not RecRef.FindFirst() then
            RecRef.Insert();
    end;

    internal procedure GetDocsFromJson(var RecKeys: JsonArray; RecordObject: JsonObject) More: Boolean
    var
        RecRef: RecordRef;
        DocId: Text;
        Token: JsonToken;
    begin
        RecRef.Open(Database::"ForNAV Incoming E-Document");
        foreach DocId in RecordObject.Keys do
            if DocId = 'Next' then
                More := true
            else begin
                RecordObject.Get(DocId, Token);
                RecKeys.Add(DocId);
                InsertDocFromJson(RecRef, Token.AsObject());
            end;
    end;
}
