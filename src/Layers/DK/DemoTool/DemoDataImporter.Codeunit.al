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

        Clear(CachedRefrencesTable);

        repeat
            ReadDemoDataFile(DemoDataFile);

            JsonObject.ReadFrom(JsonTxt);
            TablesArray := JsonObject.GetArray('tables');
            Clear(OptionsTable);
            Clear(RefrencesTable);
            foreach TableToken in TablesArray do
                ImportTable(TableToken.AsObject());
        until DemoDataFile.Next() = 0;
    end;

    var
        OptionsTable: Dictionary of [Text, Integer];
        RefrencesTable: Dictionary of [Text, Text];
        CachedRefrencesTable: Dictionary of [Text, Text];
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
                    TempVar := GetJsonValueAsText(LocalizedValueToken)
                else
                    Clear(TempVar);
            end else
                TempVar := GetJsonValueAsText(ValueToken);

            if RefrencesTable.ContainsKey(Format(TableId) + '/' + FieldName) then
                TempVar := GetRefrencedValue(Format(TableId) + '/' + FieldName, Format(TempVar));

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
                InitRefrencesTable(JsonToken.AsObject(), TblID);
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
            AddOptionsToDic(GetJsonValueAsText(LanguageToken), TableID, OptionName);

        if LanguagesJson.Get(LanguageCode, LanguageToken) then
            AddOptionsToDic(GetJsonValueAsText(LanguageToken), TableID, OptionName);
    end;

    local procedure InitRefrencesTable(ReferencesJson: JsonObject; TableId: Integer)
    var
        ReferenceToken: JsonToken;
        FieldName: Text;
        KeyStr: Text;
    begin
        foreach FieldName in ReferencesJson.Keys() do begin
            ReferencesJson.Get(FieldName, ReferenceToken);
            KeyStr := Format(TableId) + '/' + FieldName;
            if not RefrencesTable.ContainsKey(KeyStr) then
                RefrencesTable.Add(KeyStr, GetJsonValueAsText(ReferenceToken));
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

    local procedure GetRefrencedValue("Key": Text; RefValue: Text): Text
    var
        TablesToken: JsonToken;
        TableToken: JsonToken;
        RowsToken: JsonToken;
        RowToken: JsonToken;
        FieldToken: JsonToken;
        LanguageToken: JsonToken;
        TableObject: JsonObject;
        RowObject: JsonObject;
        FieldObject: JsonObject;
        ReferenceParts: List of [Text];
        ReferenceAddress: Text;
        CacheKey: Text;
        Result: Text;
        ReferenceTableId: Integer;
        ReferenceFieldName: Text;
    begin
        if RefValue = '' then
            exit('');

        if LanguageCode = 'ENU' then
            exit(RefValue);

        RefrencesTable.Get(Key, ReferenceAddress);
        CacheKey := ReferenceAddress + '/' + RefValue;
        if CachedRefrencesTable.Get(CacheKey, Result) then
            exit(Result);

        ReferenceParts := ReferenceAddress.Split('/');
        Evaluate(ReferenceTableId, ReferenceParts.Get(1));
        ReferenceFieldName := ReferenceParts.Get(2);

        if not JsonObject.Get('tables', TablesToken) then
            exit('');
        if not TablesToken.IsArray() then
            exit('');
        foreach TableToken in TablesToken.AsArray() do
            if TableToken.IsObject() then begin
                TableObject := TableToken.AsObject();
                if TableObject.GetInteger('table') = ReferenceTableId then
                    if TableObject.Get('rows', RowsToken) then
                        if RowsToken.IsArray() then
                            foreach RowToken in RowsToken.AsArray() do
                                if RowToken.IsObject() then begin
                                    RowObject := RowToken.AsObject();
                                    if RowObject.Get(ReferenceFieldName, FieldToken) then
                                        if FieldToken.IsObject() then begin
                                            FieldObject := FieldToken.AsObject();
                                            if FieldObject.Get('ENU', LanguageToken) then
                                                if LanguageToken.IsValue() then
                                                    if not LanguageToken.AsValue().IsNull() then
                                                        if not LanguageToken.AsValue().IsUndefined() then
                                                            if LanguageToken.AsValue().AsText() = RefValue then
                                                                if FieldObject.Get(LanguageCode, LanguageToken) then
                                                                    if LanguageToken.IsValue() then
                                                                        if not LanguageToken.AsValue().IsNull() then
                                                                            if not LanguageToken.AsValue().IsUndefined() then begin
                                                                                Result := LanguageToken.AsValue().AsText();
                                                                                CachedRefrencesTable.Add(CacheKey, Result);
                                                                                exit(Result);
                                                                            end;
                                        end;
                                end;
            end;
    end;

    local procedure GetJsonValueAsText(JsonToken: JsonToken): Text
    var
        JsonText: Text;
    begin
        if JsonToken.IsValue() then begin
            if JsonToken.AsValue().IsNull() or JsonToken.AsValue().IsUndefined() then
                exit('');
            exit(JsonToken.AsValue().AsText());
        end;
        JsonToken.WriteTo(JsonText);
        exit(JsonText);
    end;
}
