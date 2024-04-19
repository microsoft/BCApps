codeunit 336 "No. Series Cop. Tools Impl."
{
    Access = Internal;

    var
        CustomPatternsPlaceholderLbl: label '{custom_patterns}', Locked = true;

    procedure GetUserSpecifiedOrExistingNumberPatternsGuidelines(var Arguments: JsonObject; var CustomPatternsPromptList: List of [Text]; var ExistingNoSeriesToChangeList: List of [Text]; CustomGuidelinesPrompt: Text)
    begin
        if CheckIfPatternSpecified(Arguments) then
            CustomPatternsPromptList.Add(CustomGuidelinesPrompt.Replace(CustomPatternsPlaceholderLbl, ''))
        else
            CustomPatternsPromptList.Add(CustomGuidelinesPrompt.Replace(CustomPatternsPlaceholderLbl, BuildExistingPatternIfExist(ExistingNoSeriesToChangeList)));
    end;

    procedure CheckIfTablesSpecified(var Arguments: JsonObject): Boolean
    begin
        exit(GetEntities(Arguments).Count > 0);
    end;

    procedure GetEntities(var Arguments: JsonObject): List of [Text]
    var
        EntitiesToken: JsonToken;
        XpathLbl: Label '$.entities', Locked = true;
    begin
        if not Arguments.SelectToken(XpathLbl, EntitiesToken) then
            exit;

        exit(EntitiesToken.AsValue().AsText().Split(',')); // split the text by commas into a list of entities
    end;

    local procedure CheckIfPatternSpecified(var Arguments: JsonObject): Boolean
    begin
        exit(GetPattern(Arguments) <> '');
    end;

    local procedure GetPattern(var Arguments: JsonObject): Text
    var
        PatternToken: JsonToken;
        XpathLbl: Label '$.pattern', Locked = true;
    begin
        if not Arguments.SelectToken(XpathLbl, PatternToken) then
            exit;

        exit(PatternToken.AsValue().AsText());
    end;

    local procedure BuildExistingPatternIfExist(var ExistingNoSeriesToChangeList: List of [Text]) CustomPatterns: Text
    begin
        if BuildExistingPatternFromNoSeriesToChangeList(CustomPatterns, ExistingNoSeriesToChangeList) then
            exit;

        if BuildExistingPatternFromNoSeries(CustomPatterns) then
            exit;
    end;

    local procedure BuildExistingPatternFromNoSeriesToChangeList(var CustomPatterns: text; var ExistingNoSeriesToChangeList: List of [Text]): Boolean
    var
        NoSeries: Record "No. Series";
        NoSeriesCode: Text;
        NoSeriesCodeFilter: Text;
    begin
        if ExistingNoSeriesToChangeList.Count = 0 then
            exit(false);

        foreach NoSeriesCode in ExistingNoSeriesToChangeList do
            NoSeriesCodeFilter += NoSeriesCode + '|';

        NoSeriesCodeFilter := DelStr(NoSeriesCodeFilter, StrLen(NoSeriesCodeFilter), 1); // remove the last '|'
        NoSeries.SetFilter(Code, NoSeriesCodeFilter);
        BuildExistingPattern(CustomPatterns, NoSeries);
        exit(true);
    end;

    local procedure BuildExistingPatternFromNoSeries(var CustomPatterns: text): Boolean
    var
        NoSeries: Record "No. Series";
    begin
        if not CheckIfNumberSeriesExists() then
            exit(false);

        BuildExistingPattern(CustomPatterns, NoSeries);
        exit(true);
    end;

    local procedure CheckIfNumberSeriesExists(): Boolean
    var
        NoSeries: Record "No. Series";
    begin
        exit(not NoSeries.IsEmpty);
    end;

    local procedure BuildExistingPattern(var CustomPatterns: Text; var NoSeries: Record "No. Series")
    var
        JsonObj: JsonObject;
        JsonArr: JsonArray;
        i: Integer;
    begin
        // show first 5 existing number series as example
        if NoSeries.FindSet() then
            repeat
                JsonArr.Add(BuildNoSeriesLineJson(NoSeries));
                if i > 5 then
                    break;
                i += 1;
            until NoSeries.Next() = 0;

        if JsonArr.Count = 0 then
            exit;

        JsonObj.Add('noSeries', JsonArr);
        JsonObj.WriteTo(CustomPatterns);
    end;

    local procedure BuildNoSeriesLineJson(var NoSeries: Record "No. Series") JsonObj: JsonObject
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeriesManagement: Codeunit "No. Series";
    begin
        NoSeriesManagement.GetNoSeriesLine(NoSeriesLine, NoSeries.Code, Today(), false);
        JsonObj.Add('seriesCode', NoSeries.Code);
        JsonObj.Add('description', NoSeries.Description);
        JsonObj.Add('startingNo', NoSeriesLine."Starting No.");
        JsonObj.Add('endingNo', NoSeriesLine."Ending No.");
        JsonObj.Add('warningNo', NoSeriesLine."Warning No.");
        JsonObj.Add('incrementByNo', NoSeriesLine."Increment-by No.");
    end;

    procedure SetFilterOnSetupTables(var TableMetadata: Record "Table Metadata")
    begin
        TableMetadata.SetFilter(Name, '* Setup');
        TableMetadata.SetRange(ObsoleteState, TableMetadata.ObsoleteState::No); //TODO: Check if 'Pending' should be included
        TableMetadata.SetRange(TableType, TableMetadata.TableType::Normal);
    end;

    procedure SetFilterOnNoSeriesFields(var TableMetadata: Record "Table Metadata"; var Field: Record "Field")
    begin
        Field.SetRange(TableNo, TableMetadata.ID);
        Field.SetRange(Class, Field.Class::Normal);
        Field.SetFilter(ObsoleteState, '<>%1', Field.ObsoleteState::Removed);
        Field.SetRange(Type, Field.Type::Code);
        Field.SetRange(Len, 20);
        Field.SetRange(RelationTableNo, Database::"No. Series");
    end;

    procedure IsRelevant(TableMetadata: Record "Table Metadata"; Field: Record "Field"; Entities: List of [Text]): Boolean
    var
        Entity: Text;
        String1: Text[250];
        String2: Text[250];
        Score: Decimal;
        RecordMatchMgtCopy: Codeunit "Record Match Mgt. Copy"; //TODO: Replace with system app module when available
    begin
        //TODO: Replace this with embeddings, when Business Central supports it
        foreach Entity in Entities do begin
            String1 := RecordMatchMgtCopy.RemoveShortWords(RemoveTextPart(TableMetadata.Caption, ' Setup') + ' ' + RemoveTextPart(Field.FieldName, ' Nos.'));
            String2 := RecordMatchMgtCopy.RemoveShortWords(Entity);
            Score := RecordMatchMgtCopy.CalculateStringNearness(String1, String2, 1, 100) / 100;
            if Score >= RequiredNearness() then
                exit(true);
        end;
        exit(false);
    end;

    local procedure RequiredNearness(): Decimal
    begin
        exit(0.9)
    end;

    procedure AddChunkedTablesPrompt(var FinalPrompt: List of [Text]; var TablesPromptList: List of [Text]; var AddedCount: Integer)
    var
        TablePrompt: Text;
        IncludedTablePrompts: List of [Text];
    begin
        // we add by chunks of 10 tables, not to exceed the token limit, as more than 10 tables can lead to hallucinations
        foreach TablePrompt in TablesPromptList do
            if (AddedCount < GetTablesChunkSize()) then begin
                IncludedTablePrompts.Add(TablePrompt);
                AddedCount += 1;
            end;

        foreach TablePrompt in IncludedTablePrompts do begin
            FinalPrompt.Add(TablePrompt);
            TablesPromptList.Remove(TablePrompt);
        end;
    end;

    procedure RemoveTextPart(Text: Text; PartToRemove: Text): Text
    begin
        if StrPos(Text, PartToRemove) = 0 then
            exit(Text);

        exit(DelStr(Text, StrPos(Text, PartToRemove), StrLen(PartToRemove)));
    end;

    procedure ExtractAreaWithPrefix(Text: Text): Text
    var
        AreaLbl: Label 'Area: ', Locked = true;
        PrefixLbl: Label 'for ';
    begin
        if StrPos(Text, AreaLbl) = 0 then
            exit('');

        Text := CopyStr(Text, StrPos(Text, AreaLbl) + StrLen(AreaLbl));

        if StrPos(Text, ',') = 0 then
            exit('');

        Text := CopyStr(Text, 1, StrPos(Text, ',') - 1);
        exit(PrefixLbl + Text);
    end;

    procedure ConvertListToText(MyList: List of [Text]): Text
    var
        Element: Text;
        Result: TextBuilder;
    begin
        foreach Element in MyList do
            Result.AppendLine(Element);

        exit(Result.ToText());
    end;

    procedure GetTablesChunkSize(): Integer
    begin
        exit(10);
    end;
}