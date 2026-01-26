codeunit 101017 "Demo Data Importer"
{

    trigger OnRun()
    var
        DemoDataSetup: Record "Demo Data Setup";
        DemoDataFile: Record "Demo Data File";
        CreateGettingStartedData: Codeunit "Create Getting Started Data";
        TblsArray: DotNet JArray;
        TblObj: DotNet JObject;
    begin
        CreateGettingStartedData.ImportDemoDataFiles();

        if DemoDataSetup.Get() then
            LanguageCode := DemoDataSetup."Language Code"
        else
            LanguageCode := 'ENU';

        if not DemoDataFile.FindSet() then
            exit;

        CachedRefrencesTable := CachedRefrencesTable.Hashtable();

        repeat
            ReadDemoDataFile(DemoDataFile);

            JSONManagement.InitializeObject(JsonTxt);
            JSONManagement.GetJSONObject(JsonObject);
            TblsArray := JsonObject.Item('tables');
            OptionsTable := OptionsTable.Hashtable();
            RefrencesTable := RefrencesTable.Hashtable();
            foreach TblObj in TblsArray do
                ImportTable(TblObj);
        until DemoDataFile.Next() = 0;
    end;

    var
        JSONManagement: Codeunit "JSON Management";
        OptionsTable: DotNet Hashtable;
        RefrencesTable: DotNet Hashtable;
        CachedRefrencesTable: DotNet Hashtable;
        JsonObject: DotNet JObject;
        JsonTxt: Text;
        LanguageCode: Code[10];

    local procedure ReadDemoDataFile(DemoDataFile: Record "Demo Data File")
    var
        InStrm: InStream;
    begin
        DemoDataFile.CalcFields("Json File");
        DemoDataFile."Json File".CreateInStream(InStrm, TEXTENCODING::UTF8);
        InStrm.Read(JsonTxt);
    end;

    local procedure InsertEntry(RowObj: DotNet JObject; TableId: Integer)
    var
        "Field": Record "Field";
        IEnumerable: DotNet GenericIEnumerable1;
        IEnumerator: DotNet GenericIEnumerator1;
        JProp: DotNet JProperty;
        FRef: FieldRef;
        RecRef: RecordRef;
        TempVar: Variant;
        ValToken: DotNet JToken;
        TempInt: Integer;
        TempBool: Boolean;
    begin
        RecRef.Open(TableId);

        IEnumerable := RowObj.Properties();
        IEnumerator := IEnumerable.GetEnumerator();

        while IEnumerator.MoveNext() do begin
            JProp := IEnumerator.Current;
            if not IsNull(JProp.SelectToken('$..@')) then begin
                ValToken := JProp.SelectToken('$..' + LanguageCode);
                TempVar := ValToken.ToString();
            end else
                TempVar := JProp.Value();

            if RefrencesTable.Contains(Format(TableId) + '/' + Format(JProp.Name)) then
                TempVar := GetRefrencedValue(Format(TableId) + '/' + Format(JProp.Name), Format(TempVar));

            FRef := RecRef.Field(GetFieldNo(TableId, JProp.Name, Field));
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

    local procedure ImportTable(TblJObj: DotNet JObject)
    var
        RowsArray: DotNet JArray;
        MetadataJTok: DotNet JToken;
        JTok: DotNet JToken;
        RowObj: DotNet JObject;
        TempVar: Variant;
        TblID: Integer;
    begin
        JSONManagement.GetPropertyValueFromJObjectByName(TblJObj, 'table', TempVar);
        Evaluate(TblID, Format(TempVar));

        if TblJObj.TryGetValue('FieldMetaData', MetadataJTok) then begin
            JSONManagement.GetObjectPropertyValueFromJObjectByName(MetadataJTok, 'Options', JTok);
            if not IsNull(JTok) then
                InitOptionsTable(OptionsTable, JTok, TblID);

            JSONManagement.GetObjectPropertyValueFromJObjectByName(MetadataJTok, 'Refrences', JTok);
            if not IsNull(JTok) then
                InitRefrencesTable(JTok, TblID);
        end;

        JSONManagement.GetArrayPropertyValueFromJObjectByName(TblJObj, 'rows', RowsArray);
        foreach RowObj in RowsArray do
            InsertEntry(RowObj, TblID);
    end;

    local procedure InitOptionsTable(OptionsTable: DotNet Hashtable; OptionsJObj: DotNet JObject; TableId: Integer)
    var
        IEnumerable: DotNet GenericIEnumerable1;
        IEnumerator: DotNet GenericIEnumerator1;
        OptJObj: DotNet JProperty;
    begin
        IEnumerable := OptionsJObj.Properties();
        IEnumerator := IEnumerable.GetEnumerator();

        while IEnumerator.MoveNext() do begin
            OptJObj := IEnumerator.Current;
            PopulateOptionsTbl(OptionsTable, OptJObj, TableId);
        end;
    end;

    local procedure PopulateOptionsTbl(OptionsTable: DotNet Hashtable; OptionsJProperty: DotNet JProperty; TableID: Integer)
    var
        JTok: DotNet JToken;
        LocJTok: DotNet JToken;
        TempVar: Variant;
    begin
        TempVar := OptionsJProperty.Name;
        JTok := OptionsJProperty.SelectToken('$..ENU');
        if not IsNull(JTok) then
            AddOptionsToDic(OptionsTable, JTok.ToString(), TableID, Format(TempVar));

        LocJTok := OptionsJProperty.SelectToken('$..' + LanguageCode);
        if not IsNull(LocJTok) then
            AddOptionsToDic(OptionsTable, LocJTok.ToString(), TableID, Format(TempVar));
    end;

    local procedure InitRefrencesTable(RefJObj: DotNet JObject; TableId: Integer)
    var
        IEnumerable: DotNet GenericIEnumerable1;
        IEnumerator: DotNet GenericIEnumerator1;
        JProp: DotNet JProperty;
        KeyStr: Text;
    begin
        IEnumerable := RefJObj.Properties();
        IEnumerator := IEnumerable.GetEnumerator();

        while IEnumerator.MoveNext() do begin
            JProp := IEnumerator.Current;
            KeyStr := Format(TableId) + '/' + Format(JProp.Name);
            if not RefrencesTable.ContainsKey(KeyStr) then
                RefrencesTable.Add(KeyStr, Format(JProp.Value));
        end;
    end;

    local procedure AddOptionsToDic(OptionsTable: DotNet Hashtable; OptionString: DotNet String; TableID: Integer; OptionName: Text)
    var
        CommaChar: DotNet String;
        Arr: DotNet Array;
        KeyStr: Text;
        I: Integer;
        OptText: Text;
    begin
        CommaChar := ',';
        Arr := OptionString.Split(CommaChar.ToCharArray());
        I := 0;
        foreach OptText in Arr do begin
            KeyStr := Format(TableID) + '.' + Format(OptionName) + '.' + OptText;
            if not OptionsTable.ContainsKey(KeyStr) then
                OptionsTable.Add(KeyStr, I);
            I += 1;
        end;
    end;

    local procedure GetVal(KeyTxt: Text): Integer
    var
        ValVar: Variant;
        ValInt: Integer;
    begin
        ValVar := OptionsTable.Item(KeyTxt);
        Evaluate(ValInt, Format(ValVar));
        exit(ValInt);
    end;

    local procedure GetRefrencedValue("Key": Text; RefValue: Text): Text
    var
        CommaChar: DotNet String;
        Arr: DotNet Array;
        RefAdd: DotNet String;
        TempVar: Variant;
        JsonPath: Text;
    begin
        if RefValue = '' then
            exit('');

        if LanguageCode = 'ENU' then
            exit(RefValue);

        RefAdd := RefrencesTable.Item(Key);
        if CachedRefrencesTable.Contains(RefAdd.ToString() + '/' + RefValue) then
            exit(Format(CachedRefrencesTable.Item(RefAdd.ToString() + '/' + RefValue)));

        CommaChar := '/';
        Arr := RefAdd.Split(CommaChar.ToCharArray());
        JsonPath := StrSubstNo('$..tables[?(@.table == %1)].rows[?(@.%2.ENU == ''%3'')].%2.%4',
            Arr.GetValue(0), Arr.GetValue(1), RefValue, LanguageCode);
        TempVar := JsonObject.SelectToken(JsonPath);
        if not IsNull(TempVar) then
            CachedRefrencesTable.Add(RefAdd.ToString() + '/' + RefValue, Format(TempVar));

        exit(Format(TempVar));
    end;
}

