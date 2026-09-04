namespace Microsoft.Integration.MDM;

using System.Text;
using System.Utilities;

/// <summary>
/// Parses a GetRecords/LastModifiedAtPerTable JSON response from the source and materializes records into a
/// temporary RecordRef, so the existing synchronization engine can read them as if they were local. Also
/// exposes the response's control fields (tableAvailable / indexed / unavailableFields / hasMore / nextCursor)
/// so the caller can raise the right synchronization error.
/// </summary>
codeunit 7248 "MDM Source Response"
{
    Access = Internal;

    var
        SourceWatermark: Codeunit "MDM Source Watermark";
        SkippedFieldTxt: Label 'Cross-environment media or blob field exceeds the inline size cap and was not synchronized.', Locked = true;
        BadFieldValueErr: Label 'The source returned a value for field %1 that could not be converted to the expected type %2.', Comment = '%1 - a field caption, %2 - a field type';
        MalformedControlFieldErr: Label 'The source returned a malformed value for the response control field ''%1''.', Comment = '%1 = response control field name';
        MalformedRecordErr: Label 'The source returned a malformed record entry.', Locked = true;

    procedure TryParse(ResponseText: Text; var Response: JsonObject): Boolean
    begin
        exit(Response.ReadFrom(ResponseText));
    end;

    procedure TableAvailable(var Response: JsonObject): Boolean
    begin
        exit(ReadControlBoolean(Response, 'tableAvailable', true));
    end;

    procedure Indexed(var Response: JsonObject): Boolean
    begin
        // 'indexed' is only emitted when false (a too-large unindexed/keyless table).
        exit(ReadControlBoolean(Response, 'indexed', true));
    end;

    procedure GetUnavailableFields(var Response: JsonObject; var UnavailableFields: JsonArray): Boolean
    var
        Token: JsonToken;
    begin
        if not Response.Get('unavailableFields', Token) then
            exit(false);
        if not Token.IsArray() then
            exit(false);
        UnavailableFields := Token.AsArray();
        exit(UnavailableFields.Count() > 0);
    end;

    procedure HasMore(var Response: JsonObject): Boolean
    begin
        exit(ReadControlBoolean(Response, 'hasMore', false));
    end;

    // True when the source declined to share because its cross-environment privacy notice isn't approved.
    procedure ConsentRequired(var Response: JsonObject): Boolean
    begin
        exit(ReadControlBoolean(Response, 'consentRequired', false));
    end;

    // Control fields (tableAvailable/indexed/hasMore) are always booleans in the contract; a present-but-malformed
    // token is an internal contract failure, so surface it as an internal diagnostic instead of a raw runtime throw.
    local procedure ReadControlBoolean(var Response: JsonObject; PropertyName: Text; DefaultValue: Boolean): Boolean
    var
        Token: JsonToken;
        Value: Boolean;
    begin
        if not Response.Get(PropertyName, Token) then
            exit(DefaultValue);
        if not (Token.IsValue() and TryReadBoolean(Token, Value)) then
            Error(MalformedControlField(PropertyName));
        exit(Value);
    end;

    [TryFunction]
    local procedure TryReadBoolean(Token: JsonToken; var Value: Boolean)
    begin
        Value := Token.AsValue().AsBoolean();
    end;

    [TryFunction]
    local procedure TryFromBase64(ContentBase64: Text; ContentOutStream: OutStream)
    var
        Base64Convert: Codeunit "Base64 Convert";
    begin
        Base64Convert.FromBase64(ContentBase64, ContentOutStream);
    end;

    local procedure MalformedControlField(PropertyName: Text): ErrorInfo
    var
        ErrInfo: ErrorInfo;
    begin
        ErrInfo.Message := StrSubstNo(MalformedControlFieldErr, PropertyName);
        ErrInfo.DataClassification := DataClassification::SystemMetadata; // Message is emitted to telemetry
        ErrInfo.ErrorType := ErrorType::Internal;
        exit(ErrInfo);
    end;

    local procedure MalformedRecordEntry(): ErrorInfo
    var
        ErrInfo: ErrorInfo;
    begin
        ErrInfo.Message := MalformedRecordErr;
        ErrInfo.DataClassification := DataClassification::SystemMetadata; // Message is emitted to telemetry
        ErrInfo.ErrorType := ErrorType::Internal;
        exit(ErrInfo);
    end;

    // The nextCursor object, re-serialized so the caller can pass it straight back as the next Selector.
    procedure GetNextCursor(var Response: JsonObject): Text
    var
        Token: JsonToken;
        CursorText: Text;
    begin
        if not Response.Get('nextCursor', Token) then
            exit('');
        if not Token.IsObject() then // a non-object cursor is malformed; report "no cursor" so the caller fails the response instead of replaying from the start
            exit('');
        Token.WriteTo(CursorText);
        exit(CursorText);
    end;

    // Inserts the response's records into TempSourceRecordRef (already opened temporary on the table).
    // Returns the number inserted. Requires the caller to have requested the primary-key fields so the
    // temporary inserts don't collide.
    procedure InsertRecords(var Response: JsonObject; var TempSourceRecordRef: RecordRef): Integer
    var
        RecordsToken: JsonToken;
        RecordToken: JsonToken;
        RecordsArray: JsonArray;
        Count: Integer;
    begin
        if not Response.Get('records', RecordsToken) then // available+indexed responses always carry a records array; absence is a broken contract
            Error(MalformedRecordEntry());
        if not RecordsToken.IsArray() then
            Error(MalformedRecordEntry());
        RecordsArray := RecordsToken.AsArray();
        foreach RecordToken in RecordsArray do begin
            if not RecordToken.IsObject() then
                Error(MalformedRecordEntry());
            InsertRecord(RecordToken.AsObject(), TempSourceRecordRef);
            Count += 1;
        end;
        exit(Count);
    end;

    local procedure InsertRecord(RecordObject: JsonObject; var TempSourceRecordRef: RecordRef)
    var
        DestField: FieldRef;
        FieldsToken: JsonToken;
        ValueToken: JsonToken;
        FieldsObject: JsonObject;
        FieldName: Text;
        SystemIdValue: Guid;
        SystemModifiedAtValue: DateTime;
        FieldNo: Integer;
    begin
        TempSourceRecordRef.Init();
        if not GetGuid(RecordObject, 'systemId', SystemIdValue) then // systemId is the record identity and dedup key; a missing/unparsable one is a broken record
            Error(MalformedRecordEntry());
        if RecordObject.Get('fields', FieldsToken) then begin
            if not FieldsToken.IsObject() then // a non-object 'fields' is a broken contract, routed as an internal error
                Error(MalformedRecordEntry());
            FieldsObject := FieldsToken.AsObject();
            foreach FieldName in FieldsObject.Keys() do
                if Evaluate(FieldNo, FieldName) then
                    if TempSourceRecordRef.FieldExist(FieldNo) then begin
                        FieldsObject.Get(FieldName, ValueToken);
                        DestField := TempSourceRecordRef.Field(FieldNo);
                        case DestField.Type() of
                            FieldType::Media:
                                ApplyInlineMedia(SystemIdValue, FieldNo, TempSourceRecordRef.Number(), ValueToken);
                            FieldType::Blob:
                                ApplyInlineBlob(DestField, FieldNo, TempSourceRecordRef.Number(), ValueToken);
                            else begin
                                if not ValueToken.IsValue() then // an object/array for a scalar field is a broken contract
                                    Error(MalformedRecordEntry());
                                SetFieldFromText(DestField, ValueToken.AsValue().AsText());
                            end;
                        end;
                    end;
        end;
        if not IsNullGuid(SystemIdValue) then
            TempSourceRecordRef.Field(TempSourceRecordRef.SystemIdNo()).Value := SystemIdValue;
        // A record re-modified between page fetches can arrive on two pages under the advancing cursor; keep the
        // newest copy instead of aborting the whole batch on the duplicate primary key.
        if not TryInsertTempRecord(TempSourceRecordRef) then
            TempSourceRecordRef.Modify(false);
        // The temp row can't hold SystemModifiedAt (the platform ignores the write), so stash the source watermark
        // in a side cache the sync loop reads back via GetRowLastModifiedOn.
        if GetDateTime(RecordObject, 'systemModifiedAt', SystemModifiedAtValue) then
            SourceWatermark.Put(SystemIdValue, SystemModifiedAtValue);
    end;

    [TryFunction]
    local procedure TryInsertTempRecord(var TempSourceRecordRef: RecordRef)
    begin
        TempSourceRecordRef.Insert(false);
    end;

    // Media bytes travel in a per-batch cache keyed by (SystemId, fieldNo); the temp record's Media field only
    // holds a GUID that is meaningless in the subsidiary. UpdateMedia (cross-env) reads the cache during transfer.
    local procedure ApplyInlineMedia(SystemId: Guid; FieldNo: Integer; TableId: Integer; ValueToken: JsonToken)
    var
        InlineMedia: Codeunit "MDM Inline Media";
        MediaObject: JsonObject;
        ContentToken: JsonToken;
        NameToken: JsonToken;
        MimeToken: JsonToken;
        FileName: Text;
        MimeType: Text;
    begin
        if not ValueToken.IsObject() then
            exit;
        MediaObject := ValueToken.AsObject();
        if IsSkipped(MediaObject) then begin
            LogSkippedField(TableId, FieldNo, MediaObject);
            exit;
        end;
        if IsEmptyField(MediaObject) then begin
            InlineMedia.PutCleared(SystemId, FieldNo); // source cleared the picture: mirror it on the destination
            exit;
        end;
        if not MediaObject.Get('content', ContentToken) then
            exit; // no content and not flagged empty: leave the destination picture untouched
        if not ContentToken.IsValue() then // a non-scalar content payload is a broken record entry
            Error(MalformedRecordEntry());
        if MediaObject.Get('name', NameToken) and NameToken.IsValue() then
            FileName := NameToken.AsValue().AsText();
        if MediaObject.Get('mimeType', MimeToken) and MimeToken.IsValue() then
            MimeType := MimeToken.AsValue().AsText();
        InlineMedia.Put(SystemId, FieldNo, FileName, MimeType, ContentToken.AsValue().AsText());
    end;

    // Blob bytes are placed directly on the temp source record; the framework's record transfer carries them to
    // the destination (the same path same-env uses for mapped blobs), so no destination-side apply is needed.
    local procedure ApplyInlineBlob(var DestField: FieldRef; FieldNo: Integer; TableId: Integer; ValueToken: JsonToken)
    var
        TempBlob: Codeunit "Temp Blob";
        BlobObject: JsonObject;
        ContentToken: JsonToken;
        ContentOutStream: OutStream;
    begin
        if not ValueToken.IsObject() then
            exit;
        BlobObject := ValueToken.AsObject();
        if IsSkipped(BlobObject) then begin
            LogSkippedField(TableId, FieldNo, BlobObject);
            exit;
        end;
        if IsEmptyField(BlobObject) then begin
            Clear(TempBlob);
            TempBlob.ToFieldRef(DestField); // source cleared the blob: write empty so the transfer clears the destination
            exit;
        end;
        if not BlobObject.Get('content', ContentToken) then
            exit; // no content and not flagged empty: leave the destination untouched
        if not ContentToken.IsValue() then // a non-scalar content payload is a broken record entry
            Error(MalformedRecordEntry());
        TempBlob.CreateOutStream(ContentOutStream);
        if not TryFromBase64(ContentToken.AsValue().AsText(), ContentOutStream) then // undecodable content is a broken record entry
            Error(MalformedRecordEntry());
        TempBlob.ToFieldRef(DestField);
    end;

    local procedure IsSkipped(FieldObject: JsonObject): Boolean
    begin
        exit(ReadRecordBoolean(FieldObject, 'skipped'));
    end;

    local procedure IsEmptyField(FieldObject: JsonObject): Boolean
    begin
        exit(ReadRecordBoolean(FieldObject, 'empty'));
    end;

    // Per-record media/blob flags are booleans in the contract; a present-but-malformed token is a broken record
    // entry, so route it through the same internal malformed-record path as the rest of record materialization.
    local procedure ReadRecordBoolean(FieldObject: JsonObject; PropertyName: Text): Boolean
    var
        Token: JsonToken;
        Value: Boolean;
    begin
        if not FieldObject.Get(PropertyName, Token) then
            exit(false);
        if not (Token.IsValue() and TryReadBoolean(Token, Value)) then
            Error(MalformedRecordEntry());
        exit(Value);
    end;

    // Over-cap media/blob is not synchronized (v1). We can't error (it would retry the record every run) and MDM
    // surfaces no synch warnings, so the skip is emitted as telemetry only; the record's other fields still sync.
    local procedure LogSkippedField(TableId: Integer; FieldNo: Integer; FieldObject: JsonObject)
    var
        MasterDataManagement: Codeunit "Master Data Management";
        Dimensions: Dictionary of [Text, Text];
        LengthToken: JsonToken;
    begin
        // The source record identifier (systemId) is customer data, so it is not emitted; only the table, field,
        // and length (non-identifying diagnostics) are logged.
        Dimensions.Add('Category', MasterDataManagement.GetTelemetryCategory());
        Dimensions.Add('TableId', Format(TableId));
        Dimensions.Add('FieldNo', Format(FieldNo));
        if FieldObject.Get('length', LengthToken) and LengthToken.IsValue() then
            Dimensions.Add('Length', Format(LengthToken.AsValue().AsBigInteger()));
        Session.LogMessage('0000VAW', SkippedFieldTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All, Dimensions);
    end;

    // Round-trips a value serialized with Format(v, 0, 9) on the source back into the destination field's type. A
    // failed conversion means a drifted/malformed source value; error rather than silently syncing a defaulted one.
    local procedure SetFieldFromText(var DestField: FieldRef; ValueText: Text)
    var
        DateFormulaValue: DateFormula;
        IntegerValue: Integer;
        BigIntegerValue: BigInteger;
        DecimalValue: Decimal;
        BooleanValue: Boolean;
        DateValue: Date;
        TimeValue: Time;
        DateTimeValue: DateTime;
        DurationValue: Duration;
        GuidValue: Guid;
        Converted: Boolean;
        ErrInfo: ErrorInfo;
    begin
        Converted := true;
        case DestField.Type() of
            FieldType::Text, FieldType::Code:
                DestField.Value := CopyStr(ValueText, 1, DestField.Length());
            FieldType::Integer, FieldType::Option:
                if Evaluate(IntegerValue, ValueText, 9) then
                    DestField.Value := IntegerValue
                else
                    Converted := false;
            FieldType::BigInteger:
                if Evaluate(BigIntegerValue, ValueText, 9) then
                    DestField.Value := BigIntegerValue
                else
                    Converted := false;
            FieldType::Decimal:
                if Evaluate(DecimalValue, ValueText, 9) then
                    DestField.Value := DecimalValue
                else
                    Converted := false;
            FieldType::Boolean:
                if Evaluate(BooleanValue, ValueText, 9) then
                    DestField.Value := BooleanValue
                else
                    Converted := false;
            FieldType::Date:
                if Evaluate(DateValue, ValueText, 9) then
                    DestField.Value := DateValue
                else
                    Converted := false;
            FieldType::Time:
                if Evaluate(TimeValue, ValueText, 9) then
                    DestField.Value := TimeValue
                else
                    Converted := false;
            FieldType::DateTime:
                if Evaluate(DateTimeValue, ValueText, 9) then
                    DestField.Value := DateTimeValue
                else
                    Converted := false;
            FieldType::Duration:
                if Evaluate(DurationValue, ValueText, 9) then
                    DestField.Value := DurationValue
                else
                    Converted := false;
            FieldType::DateFormula:
                if Evaluate(DateFormulaValue, ValueText, 9) then
                    DestField.Value := DateFormulaValue
                else
                    Converted := false;
            FieldType::Guid:
                if Evaluate(GuidValue, ValueText) then
                    DestField.Value := GuidValue
                else
                    Converted := false;
        end;
        if not Converted then begin
            // Internal contract failure the user can't fix: detail goes to telemetry, user sees a generic dialog.
            ErrInfo.Message := StrSubstNo(BadFieldValueErr, DestField.Caption(), Format(DestField.Type()));
            ErrInfo.DataClassification := DataClassification::SystemMetadata; // Message is emitted to telemetry
            ErrInfo.ErrorType := ErrorType::Internal;
            Error(ErrInfo);
        end;
    end;

    local procedure GetGuid(var Container: JsonObject; PropertyName: Text; var Value: Guid): Boolean
    var
        Token: JsonToken;
    begin
        if not Container.Get(PropertyName, Token) then
            exit(false);
        if not Token.IsValue() then
            exit(false);
        exit(Evaluate(Value, Token.AsValue().AsText()));
    end;

    local procedure GetDateTime(var Container: JsonObject; PropertyName: Text; var Value: DateTime): Boolean
    var
        Token: JsonToken;
    begin
        if not Container.Get(PropertyName, Token) then
            exit(false);
        if not Token.IsValue() then
            exit(false);
        exit(Evaluate(Value, Token.AsValue().AsText(), 9));
    end;
}
