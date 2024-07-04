// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

using System.Reflection;

codeunit 336 "No. Series Cop. Tools Impl."
{
    Access = Internal;

    var
        CustomPatternsPlaceholderLbl: label '{custom_patterns}', Locked = true;
        PrefixLbl: Label 'for ';

    procedure GetUserSpecifiedOrExistingNumberPatternsGuidelines(var Arguments: JsonObject; var CustomPatternsPromptList: List of [Text]; var ExistingNoSeriesToChangeList: List of [Text])
    begin
        if CheckIfPatternSpecified(Arguments) then
            CustomPatternsPromptList.Add('')
        else
            CustomPatternsPromptList.Add(BuildExistingPatternIfExist(ExistingNoSeriesToChangeList));
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
        i := 0;
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
        RecordMatchMgtCopy: Codeunit "Record Match Mgt. Copy"; //TODO: Replace with system app module when available
        Entity: Text[250];
        String1: Text[250];
        String2: Text[250];
        Score: Decimal;
    begin
        //TODO: Replace this with embeddings, when Business Central supports it
        foreach Entity in Entities do begin
            String1 := RecordMatchMgtCopy.RemoveShortWords(RemoveTextPart(TableMetadata.Caption, ' Setup') + ' ' + RemoveTextParts(Field.FieldName, GetNoSeriesAbbreviations()));
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

    procedure GenerateChunkedTablesListInYamlFormat(var TablesYamlList: List of [Text]; var TempSetupTable: Record "Table Metadata" temporary; var TempNoSeriesField: Record "Field" temporary; var NumberOfAddedTables: Integer)
    begin
        Clear(TablesYamlList);
        TablesYamlList.Add('');
        TablesYamlList.Add('```yaml');
        TablesYamlList.Add('');

        TempSetupTable.Reset();
        if TempSetupTable.FindSet() then
            repeat
                AddAreaYamlBlock(TablesYamlList, TempSetupTable, TempNoSeriesField, NumberOfAddedTables);
            until TempSetupTable.Next() = 0;

        TablesYamlList.Add('```');
    end;

    local procedure AddAreaYamlBlock(var FinalPrompt: List of [Text]; var TempSetupTable: Record "Table Metadata" temporary; var TempNoSeriesField: Record "Field" temporary; var NumberOfAddedTables: Integer)
    var
        Identation: Integer;
    begin
        TempNoSeriesField.Reset();
        TempNoSeriesField.SetRange(TableNo, TempSetupTable.ID);
        if TempNoSeriesField.IsEmpty then
            exit;

        TempNoSeriesField.FindSet(true);
        repeat
            AddFieldYamlBlock(FinalPrompt, TempSetupTable, TempNoSeriesField, NumberOfAddedTables, Identation);
        until TempNoSeriesField.Next() = 0;
    end;

    local procedure AddFieldYamlBlock(var FinalPrompt: List of [Text]; var TempSetupTable: Record "Table Metadata" temporary; var TempNoSeriesField: Record "Field" temporary; var NumberOfAddedTables: Integer; var Identation: Integer)
    var
        FieldName: Text;
    begin
        if (NumberOfAddedTables >= GetMaxNumberOfTablesInOneChunk()) then
            exit;

        FieldName := RemoveTextParts(TempNoSeriesField.FieldName, GetNoSeriesAbbreviations()).Replace('-', ' ');
        if FieldName = '' then
            exit;

        AddAreaTag(FinalPrompt, TempSetupTable, Identation);
        FinalPrompt.Add(GetYAMLIdentationText(Identation) + '- FieldId: ' + Format(TempNoSeriesField."No."));
        FinalPrompt.Add(GetYAMLIdentationText(Identation) + '  FieldName: ' + FieldName);
        AddNoSeriesInfo(FinalPrompt, TempNoSeriesField, Identation);

        Identation -= 2;
        NumberOfAddedTables += 1;
        TempNoSeriesField.Delete();
    end;

    local procedure AddAreaTag(var YamlLines: List of [Text]; var TempSetupTable: Record "Table Metadata" temporary; var Identation: Integer)
    begin
        if Identation = 0 then begin
            YamlLines.Add(RemoveTextPart(TempSetupTable.Caption, ' Setup') + ':');
            Identation += 2;
        end;

        YamlLines.Add(GetYAMLIdentationText(Identation) + Format(TempSetupTable.ID) + ':');
        Identation += 2;
    end;

    local procedure GetYAMLIdentationText(var Identation: Integer): Text
    var
        NewIdentationText: Text;
        EmptyText: Text;
    begin
        NewIdentationText := EmptyText.PadLeft(Identation, ' ');
        exit(NewIdentationText);
    end;

    local procedure AddNoSeriesInfo(var YamlLines: List of [Text]; var TempNoSeriesField: Record "Field" temporary; var Identation: Integer)
    var
        NoSeries: Record "No. Series";
    begin
        if TempNoSeriesField.ExternalName = '' then
            exit;

        if not NoSeries.Get(CopyStr(TempNoSeriesField.ExternalName, 1, MaxStrLen(NoSeries.Code))) then
            exit;

        YamlLines.Add(GetYAMLIdentationText(Identation) + '  seriesCode: ' + NoSeries.Code);
        YamlLines.Add(GetYAMLIdentationText(Identation) + '  description: ' + NoSeries.Description);
    end;


    procedure RemoveTextParts(Text: Text; PartsToRemove: List of [Text]): Text
    var
        Part: Text;
    begin
        foreach Part in PartsToRemove do
            Text := RemoveTextPart(Text, Part);
        exit(Text);
    end;

    procedure RemoveTextPart(Text: Text; Part: Text): Text
    begin
        if StrPos(Text, Part) = 0 then
            exit(Text);

        exit(DelStr(Text, StrPos(Text, Part), StrLen(Part)));
    end;

    procedure ExtractAreaWithPrefix(Prompt: Text): Text
    var
        YamlStartBlockLbl: Label '```yaml', Locked = true;
        YamlTextEndLbl: Label '```', Locked = true;
        YamlText: Text;
        YamlLinesList: List of [Text];
        YamlLine: Text;
        Areas: TextBuilder;
        AreasText: Text;
    begin
        if StrPos(Prompt, YamlStartBlockLbl) = 0 then
            exit('');

        if StrPos(Prompt, YamlTextEndLbl) = 0 then
            exit('');

        YamlText := CopyStr(Prompt, StrPos(Prompt, YamlStartBlockLbl) + StrLen(YamlStartBlockLbl), StrLen(Prompt));
        YamlText := CopyStr(YamlText, 1, StrPos(YamlText, YamlTextEndLbl) - StrLen(YamlTextEndLbl) - 1);

        YamlLinesList := YamlText.Split(CRLFSeparator);
        foreach YamlLine in YamlLinesList do
            if (CopyStr(YamlLine, 1, 2) <> '  ') and (CopyStr(YamlLine, 1, 1) <> '') then
                Areas.Append(YamlLine.Replace(':', ', '));

        AreasText := Areas.ToText();
        AreasText := DelStr(AreasText, StrLen(AreasText) - 2, 2); // remove the last ', '
        exit(PrefixLbl + AreasText);
    end;

    // This is a cpoy from TypeHelper.CRLFSeparator() as it's a part of a Base App, not accessible from Business Foundation
    local procedure CRLFSeparator(): Text[2]
    var
        CRLF: Text[2];
    begin
        CRLF[1] := 13; // Carriage return, '\r'
        CRLF[2] := 10; // Line feed, '\n'
        exit(CRLF);
    end;

    procedure GetNoSeriesAbbreviations() NoSeriesAbbreviations: List of [Text]
    begin
        NoSeriesAbbreviations.Add('Nos.');
        NoSeriesAbbreviations.Add('No. Series');
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

    procedure GetMaxNumberOfTablesInOneChunk(): Integer
    begin
        exit(40);
    end;
}