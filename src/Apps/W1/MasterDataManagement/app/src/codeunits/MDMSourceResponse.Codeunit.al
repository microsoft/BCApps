namespace Microsoft.Integration.MDM;

/// <summary>
/// Parses a GetRecords/LastModifiedAtPerTable JSON response from the source and materializes records into a
/// temporary RecordRef, so the existing synchronization engine can read them as if they were local. Also
/// exposes the response's control fields (tableAvailable / indexed / unavailableFields / hasMore / nextCursor)
/// so the caller can raise the right synchronization error.
/// </summary>
codeunit 7248 "MDM Source Response"
{
    Access = Internal;

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
        if RecordObject.Get('fields', FieldsToken) then begin
            FieldsObject := FieldsToken.AsObject();
            foreach FieldName in FieldsObject.Keys() do
                if Evaluate(FieldNo, FieldName) then
                    if TempSourceRecordRef.FieldExist(FieldNo) then begin
                        FieldsObject.Get(FieldName, ValueToken);
                        DestField := TempSourceRecordRef.Field(FieldNo);
                        SetFieldFromText(DestField, ValueToken.AsValue().AsText());
                    end;
        end;
        if GetGuid(RecordObject, 'systemId', SystemIdValue) then
            TempSourceRecordRef.Field(TempSourceRecordRef.SystemIdNo()).Value := SystemIdValue;
        TempSourceRecordRef.Insert(false);
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
