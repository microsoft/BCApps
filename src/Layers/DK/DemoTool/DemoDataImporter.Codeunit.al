codeunit 101017 "Demo Data Importer"
{

    trigger OnRun()
    var
        DemoDataSetup: Record "Demo Data Setup";
        DemoDataFile: Record "Demo Data File";
        CreateGettingStartedData: Codeunit "Create Getting Started Data";
        TablesArray: JsonArray;
        TableToken: JsonToken;
    begin
        CreateGettingStartedData.ImportDemoDataFiles();

        if DemoDataSetup.Get() then
            LanguageCode := DemoDataSetup."Language Code"
        else
            LanguageCode := 'ENU';

        if not DemoDataFile.FindSet() then
            exit;

        Clear(CachedReferencesTable);

        repeat
            ReadDemoDataFile(DemoDataFile);

            JsonObject.ReadFrom(JsonTxt);
            TablesArray := JsonObject.GetArray('tables');
            Clear(OptionsTable);
            Clear(ReferencesTable);
            Clear(IndexedReferenceAddresses);
            foreach TableToken in TablesArray do
                ImportTable(TableToken.AsObject());
        until DemoDataFile.Next() = 0;
    end;

    var
        Json: Codeunit Json;
        OptionsTable: Dictionary of [Text, Integer];
        ReferencesTable: Dictionary of [Text, Text];
        CachedReferencesTable: Dictionary of [Text, Text];
        IndexedReferenceAddresses: List of [Text];
        JsonObject: JsonObject;
        JsonTxt: Text;
        LanguageCode: Code[10];
        OptionValueNotFoundErr: Label 'The option value mapping %1 was not found.', Comment = '%1 = Option value mapping key';

    local procedure ReadDemoDataFile(DemoDataFile: Record "Demo Data File")
    var
        InStrm: InStream;
    begin
        DemoDataFile.CalcFields("Json File");
        DemoDataFile."Json File".CreateInStream(InStrm, TEXTENCODING::UTF8);
        InStrm.Read(JsonTxt);
    end;

    local procedure InsertEntry(RowObj: JsonObject; TableId: Integer)
    var
        "Field": Record "Field";
        FRef: FieldRef;
        RecRef: RecordRef;
        TempVar: Variant;
        ValueToken: JsonToken;
        LocalizedValueToken: JsonToken;
        LocalizedValues: JsonObject;
        FieldName: Text;
        TempInt: Integer;
        TempBool: Boolean;
    begin
        RecRef.Open(TableId);

        foreach FieldName in RowObj.Keys() do begin
            RowObj.Get(FieldName, ValueToken);
            if ValueToken.IsObject() then begin
                LocalizedValues := ValueToken.AsObject();
                if LocalizedValues.Get(LanguageCode, LocalizedValueToken) then
                    TempVar := Json.GetTokenAsText(LocalizedValueToken)
                else
                    Clear(TempVar);
            end else
                TempVar := Json.GetTokenAsText(ValueToken);

            if ReferencesTable.ContainsKey(Format(TableId) + '/' + FieldName) then
                TempVar := GetReferencedValue(Format(TableId) + '/' + FieldName, Format(TempVar));

            FRef := RecRef.Field(GetFieldNo(TableId, FieldName, Field));
            case Field.Type of
                Field.Type::Option:
                    FRef.Validate(GetVal(Format(TableId) + '.' + Format(Field.FieldName) + '.' + Format(TempVar)));
                Field.Type::Boolean:
                    begin
                        TempBool := Format(TempVar) = 'Yes';
                        FRef.Validate(TempBool);
                    end;
                Field.Type::Integer:
                    begin
                        if Format(TempVar) = '' then
                            TempInt := 0
                        else
                            Evaluate(TempInt, Format(TempVar));
                        FRef.Validate(TempInt);
                    end;
                else
                    FRef.Validate(TempVar);
            end;
        end;

        if RecRef.Insert() then;
    end;

    local procedure GetFieldNo(TableId: Integer; FieldName: Text; var "Field": Record "Field"): Integer
    begin
        Clear(Field);
        Field.SetCurrentKey(TableNo, "No.");
        Field.SetRange(TableNo, TableId);
        Field.SetRange(FieldName, FieldName);
        if not Field.FindFirst() then
            exit(0);

        exit(Field."No.");
    end;

    local procedure ImportTable(TableJson: JsonObject)
    var
        RowsArray: JsonArray;
        MetadataToken: JsonToken;
        JsonToken: JsonToken;
        RowToken: JsonToken;
        TblID: Integer;
    begin
        TblID := TableJson.GetInteger('table');

        if TableJson.Get('FieldMetaData', MetadataToken) and MetadataToken.IsObject() then begin
            if MetadataToken.AsObject().Get('Options', JsonToken) and JsonToken.IsObject() then
                InitOptionsTable(JsonToken.AsObject(), TblID);

            if MetadataToken.AsObject().Get('Refrences', JsonToken) and JsonToken.IsObject() then
                InitReferencesTable(JsonToken.AsObject(), TblID);
        end;

        RowsArray := TableJson.GetArray('rows');
        foreach RowToken in RowsArray do
            InsertEntry(RowToken.AsObject(), TblID);
    end;

    local procedure InitOptionsTable(OptionsJson: JsonObject; TableId: Integer)
    var
        OptionName: Text;
    begin
        foreach OptionName in OptionsJson.Keys() do
            PopulateOptionsTbl(OptionsJson, OptionName, TableId);
    end;

    local procedure PopulateOptionsTbl(OptionsJson: JsonObject; OptionName: Text; TableID: Integer)
    var
        LanguagesToken: JsonToken;
        LanguageToken: JsonToken;
        LanguagesJson: JsonObject;
    begin
        if not OptionsJson.Get(OptionName, LanguagesToken) or not LanguagesToken.IsObject() then
            exit;
        LanguagesJson := LanguagesToken.AsObject();
        if LanguagesJson.Get('ENU', LanguageToken) then
            AddOptionsToDic(Json.GetTokenAsText(LanguageToken), TableID, OptionName);

        if LanguagesJson.Get(LanguageCode, LanguageToken) then
            AddOptionsToDic(Json.GetTokenAsText(LanguageToken), TableID, OptionName);
    end;

    local procedure InitReferencesTable(ReferencesJson: JsonObject; TableId: Integer)
    var
        ReferenceToken: JsonToken;
        FieldName: Text;
        KeyStr: Text;
    begin
        foreach FieldName in ReferencesJson.Keys() do begin
            ReferencesJson.Get(FieldName, ReferenceToken);
            KeyStr := Format(TableId) + '/' + FieldName;
            if not ReferencesTable.ContainsKey(KeyStr) then
                ReferencesTable.Add(KeyStr, Json.GetTokenAsText(ReferenceToken));
        end;
    end;

    local procedure AddOptionsToDic(OptionString: Text; TableID: Integer; OptionName: Text)
    var
        KeyStr: Text;
        I: Integer;
        OptText: Text;
    begin
        I := 0;
        foreach OptText in OptionString.Split(',') do begin
            KeyStr := Format(TableID) + '.' + Format(OptionName) + '.' + OptText;
            if not OptionsTable.ContainsKey(KeyStr) then
                OptionsTable.Add(KeyStr, I);
            I += 1;
        end;
    end;

    local procedure GetVal(KeyTxt: Text): Integer
    var
        ValInt: Integer;
    begin
        if not OptionsTable.Get(KeyTxt, ValInt) then
            Error(OptionValueNotFoundErr, KeyTxt);
        exit(ValInt);
    end;

    local procedure GetReferencedValue("Key": Text; RefValue: Text): Text
    var
        ReferenceAddress: Text;
        CacheKey: Text;
        Result: Text;
    begin
        if RefValue = '' then
            exit('');

        if LanguageCode = 'ENU' then
            exit(RefValue);

        ReferencesTable.Get(Key, ReferenceAddress);
        CacheKey := ReferenceAddress + '/' + RefValue;
        if CachedReferencesTable.Get(CacheKey, Result) then
            exit(Result);

        // Index each referenced table/field once per document instead of scanning it for every value.
        if IndexedReferenceAddresses.Contains(ReferenceAddress) then
            exit('');
        IndexReferenceAddress(ReferenceAddress);

        if CachedReferencesTable.Get(CacheKey, Result) then
            exit(Result);
        exit('');
    end;

    local procedure IndexReferenceAddress(ReferenceAddress: Text)
    var
        TablesToken: JsonToken;
        TableToken: JsonToken;
        ReferenceParts: List of [Text];
        ReferenceTableId: Integer;
    begin
        IndexedReferenceAddresses.Add(ReferenceAddress);

        ReferenceParts := ReferenceAddress.Split('/');
        Evaluate(ReferenceTableId, ReferenceParts.Get(1));

        if not JsonObject.Get('tables', TablesToken) or not TablesToken.IsArray() then
            exit;

        foreach TableToken in TablesToken.AsArray() do
            if TableToken.IsObject() then
                if TableToken.AsObject().GetInteger('table') = ReferenceTableId then
                    IndexReferenceRows(TableToken.AsObject(), ReferenceAddress, ReferenceParts.Get(2));
    end;

    local procedure IndexReferenceRows(TableObject: JsonObject; ReferenceAddress: Text; ReferenceFieldName: Text)
    var
        RowsToken: JsonToken;
        RowToken: JsonToken;
        FieldToken: JsonToken;
        CacheKey: Text;
        EnuValue: Text;
        LocalizedValue: Text;
    begin
        if not TableObject.Get('rows', RowsToken) or not RowsToken.IsArray() then
            exit;

        foreach RowToken in RowsToken.AsArray() do
            if RowToken.IsObject() then
                if RowToken.AsObject().Get(ReferenceFieldName, FieldToken) then
                    if FieldToken.IsObject() then
                        if TryGetLanguageValue(FieldToken.AsObject(), 'ENU', EnuValue) and
                           TryGetLanguageValue(FieldToken.AsObject(), LanguageCode, LocalizedValue)
                        then begin
                            CacheKey := ReferenceAddress + '/' + EnuValue;
                            if not CachedReferencesTable.ContainsKey(CacheKey) then
                                CachedReferencesTable.Add(CacheKey, LocalizedValue);
                        end;
    end;

    local procedure TryGetLanguageValue(FieldObject: JsonObject; Language: Text; var Value: Text): Boolean
    var
        LanguageToken: JsonToken;
    begin
        Clear(Value);
        if not FieldObject.Get(Language, LanguageToken) or not LanguageToken.IsValue() then
            exit(false);
        if LanguageToken.AsValue().IsNull() or LanguageToken.AsValue().IsUndefined() then
            exit(false);
        Value := LanguageToken.AsValue().AsText();
        exit(true);
    end;

}
