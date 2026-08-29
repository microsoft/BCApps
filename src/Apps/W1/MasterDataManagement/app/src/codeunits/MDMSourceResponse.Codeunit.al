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
        SkippedFieldTxt: Label 'Cross-environment media or blob field exceeds the inline size cap and was not synchronized.', Locked = true;

    [TryFunction]
    procedure TryParse(ResponseText: Text; var Response: JsonObject)
    begin
        Response.ReadFrom(ResponseText);
    end;

    procedure TableAvailable(var Response: JsonObject): Boolean
    var
        Token: JsonToken;
    begin
        if Response.Get('tableAvailable', Token) then
            exit(Token.AsValue().AsBoolean());
        exit(true);
    end;

    procedure Indexed(var Response: JsonObject): Boolean
    var
        Token: JsonToken;
    begin
        // 'indexed' is only emitted when false (a too-large unindexed/keyless table).
        if Response.Get('indexed', Token) then
            exit(Token.AsValue().AsBoolean());
        exit(true);
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
    var
        Token: JsonToken;
    begin
        if Response.Get('hasMore', Token) then
            exit(Token.AsValue().AsBoolean());
        exit(false);
    end;

    // The nextCursor object, re-serialized so the caller can pass it straight back as the next Selector.
    procedure GetNextCursor(var Response: JsonObject): Text
    var
        Token: JsonToken;
        CursorText: Text;
    begin
        if not Response.Get('nextCursor', Token) then
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
        if not Response.Get('records', RecordsToken) then
            exit(0);
        if not RecordsToken.IsArray() then
            exit(0);
        RecordsArray := RecordsToken.AsArray();
        foreach RecordToken in RecordsArray do begin
            InsertRecord(RecordToken.AsObject(), TempSourceRecordRef);
            Count += 1;
        end;
        exit(Count);
    end;

    local procedure InsertRecord(RecordObject: JsonObject; var TempSourceRecordRef: RecordRef)
    var
        FieldsToken: JsonToken;
        ValueToken: JsonToken;
        FieldsObject: JsonObject;
        DestField: FieldRef;
        FieldName: Text;
        SystemIdValue: Guid;
        FieldNo: Integer;
    begin
        TempSourceRecordRef.Init();
        GetGuid(RecordObject, 'systemId', SystemIdValue);
        if RecordObject.Get('fields', FieldsToken) then begin
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
                            else
                                SetFieldFromText(DestField, ValueToken.AsValue().AsText());
                        end;
                    end;
        end;
        if not IsNullGuid(SystemIdValue) then
            TempSourceRecordRef.Field(TempSourceRecordRef.SystemIdNo()).Value := SystemIdValue;
        // A record re-modified between page fetches can arrive on two pages under the advancing cursor; keep the
        // newest copy instead of aborting the whole batch on the duplicate primary key.
        if not TryInsertTempRecord(TempSourceRecordRef) then
            TempSourceRecordRef.Modify(false);
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
        if not MediaObject.Get('content', ContentToken) then
            exit; // empty source media: leave the destination picture untouched
        if MediaObject.Get('name', NameToken) then
            FileName := NameToken.AsValue().AsText();
        if MediaObject.Get('mimeType', MimeToken) then
            MimeType := MimeToken.AsValue().AsText();
        InlineMedia.Put(SystemId, FieldNo, FileName, MimeType, ContentToken.AsValue().AsText());
    end;

    // Blob bytes are placed directly on the temp source record; the framework's record transfer carries them to
    // the destination (the same path same-env uses for mapped blobs), so no destination-side apply is needed.
    local procedure ApplyInlineBlob(var DestField: FieldRef; FieldNo: Integer; TableId: Integer; ValueToken: JsonToken)
    var
        Base64Convert: Codeunit "Base64 Convert";
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
        if not BlobObject.Get('content', ContentToken) then
            exit; // empty source blob: leave the destination untouched
        TempBlob.CreateOutStream(ContentOutStream);
        Base64Convert.FromBase64(ContentToken.AsValue().AsText(), ContentOutStream);
        TempBlob.ToFieldRef(DestField);
    end;

    local procedure IsSkipped(FieldObject: JsonObject): Boolean
    var
        Token: JsonToken;
    begin
        if FieldObject.Get('skipped', Token) then
            exit(Token.AsValue().AsBoolean());
        exit(false);
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
        Dimensions.Add('tableId', Format(TableId));
        Dimensions.Add('fieldNo', Format(FieldNo));
        if FieldObject.Get('length', LengthToken) then
            Dimensions.Add('length', Format(LengthToken.AsValue().AsBigInteger()));
        Session.LogMessage('0000QF2', SkippedFieldTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All, Dimensions);
    end;

    // Round-trips a value serialized with Format(v, 0, 9) on the source back into the destination field's type.
    local procedure SetFieldFromText(var DestField: FieldRef; ValueText: Text)
    var
        IntegerValue: Integer;
        BigIntegerValue: BigInteger;
        DecimalValue: Decimal;
        BooleanValue: Boolean;
        DateValue: Date;
        TimeValue: Time;
        DateTimeValue: DateTime;
        DurationValue: Duration;
        DateFormulaValue: DateFormula;
        GuidValue: Guid;
    begin
        case DestField.Type() of
            FieldType::Text, FieldType::Code:
                DestField.Value := CopyStr(ValueText, 1, DestField.Length());
            FieldType::Integer, FieldType::Option:
                if Evaluate(IntegerValue, ValueText, 9) then
                    DestField.Value := IntegerValue;
            FieldType::BigInteger:
                if Evaluate(BigIntegerValue, ValueText, 9) then
                    DestField.Value := BigIntegerValue;
            FieldType::Decimal:
                if Evaluate(DecimalValue, ValueText, 9) then
                    DestField.Value := DecimalValue;
            FieldType::Boolean:
                if Evaluate(BooleanValue, ValueText, 9) then
                    DestField.Value := BooleanValue;
            FieldType::Date:
                if Evaluate(DateValue, ValueText, 9) then
                    DestField.Value := DateValue;
            FieldType::Time:
                if Evaluate(TimeValue, ValueText, 9) then
                    DestField.Value := TimeValue;
            FieldType::DateTime:
                if Evaluate(DateTimeValue, ValueText, 9) then
                    DestField.Value := DateTimeValue;
            FieldType::Duration:
                if Evaluate(DurationValue, ValueText, 9) then
                    DestField.Value := DurationValue;
            FieldType::DateFormula:
                if Evaluate(DateFormulaValue, ValueText, 9) then
                    DestField.Value := DateFormulaValue;
            FieldType::Guid:
                if Evaluate(GuidValue, ValueText) then
                    DestField.Value := GuidValue;
        end;
    end;

    local procedure GetGuid(var Container: JsonObject; PropertyName: Text; var Value: Guid): Boolean
    var
        Token: JsonToken;
    begin
        if not Container.Get(PropertyName, Token) then
            exit(false);
        exit(Evaluate(Value, Token.AsValue().AsText()));
    end;
}
