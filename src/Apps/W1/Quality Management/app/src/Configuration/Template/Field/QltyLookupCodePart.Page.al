// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Template.Field;

using Microsoft.Foundation.AuditCodes;
using Microsoft.QualityManagement.Configuration.Result;
using Microsoft.QualityManagement.Utilities;

/// <summary>
/// A part that can be used to help configure manual lookups/choices.
/// </summary>
page 20435 "Qlty. Lookup Code Part"
{
    Caption = 'Quality Lookup Code Part';
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = "Qlty. Lookup Code";
    SourceTableView = sorting("Group Code", Code);
    UsageCategory = Administration;
    ApplicationArea = QualityManagement;

    layout
    {
        area(Content)
        {
            group(SettingsForGeneralConfig)
            {
                ShowCaption = false;
                Caption = ' ';

                field(ChooseNewField; NewLookup)
                {
                    Caption = 'A simple list of values';
                    ToolTip = 'Specifies a simple list of values';

                    trigger OnValidate()
                    begin
                        HandleOnValidateSimpleOrComplex(true);
                    end;
                }
                field(ChooseIsExistingTable; ExistingTable)
                {
                    Caption = 'An existing table';
                    ToolTip = 'Specifies a table in Business Central. Base Business Central tables and custom tables can be used here.';

                    trigger OnValidate()
                    begin
                        HandleOnValidateSimpleOrComplex(false);
                    end;
                }
                field("Default Value"; DefaultValue)
                {
                    Caption = 'Default Value';
                    ToolTip = 'Specifies a default value to set on the test.';
                    AboutTitle = 'Default Value';
                    AboutText = 'A default value to set on the test.';

                    trigger OnValidate()
                    begin
                        ValidateDefaultValue();
                    end;

                    trigger OnAssistEdit()
                    begin
                        AssistEditDefaultValue();
                    end;
                }
                group(SettingsForExistingTable)
                {
                    Caption = 'Existing Table';
                    Visible = ExistingTable;

                    field(ChooseExistingTable; CaptionOfTable)
                    {
                        Caption = 'Which Table?';
                        ToolTip = 'Specifies what table this refers to. You can use any Base Business Central tables and any custom table. A common example would be "Reason Code".';
                        Editable = false;

                        trigger OnDrillDown()
                        begin
                            ChooseLookupTable();
                        end;
                    }
                    field(ChooseExistingField; CaptionOfField)
                    {
                        Caption = 'Which Field?';
                        ToolTip = 'Specifies what field this refers to. For example, if your table is "Reason Code" then you could use the "Code" field.';
                        Editable = false;

                        trigger OnDrillDown()
                        begin
                            ChooseLookupField();
                        end;
                    }
                    field(ChooseExistingFilter; TableFilter)
                    {
                        Caption = 'Any Filter?';
                        ToolTip = 'Specifies whether to limit which fields from this table to use. For example, if your table is "Reason Code", then you could restrict to reason codes that start with "R" by having the filter where(Code=FILTER(R*))';
                        Editable = false;

                        trigger OnDrillDown()
                        begin
                            ChooseLookupFilter();
                        end;
                    }
                }
            }
            repeater(GroupLookupCodes)
            {
                ShowCaption = false;
                Visible = NewLookup;

                field(ChooseIsAcceptableForResult1; IsAcceptableValuesForThisRow[1])
                {
                    CaptionClass = '3,' + MatrixArrayCaptionSet[1];
                    ToolTip = 'Specifies if this value should be used as a pass value.';
                    Visible = Visible1;

                    trigger OnValidate()
                    begin
                        if Rec.Code = '' then
                            exit;
                        if Rec.SystemId = NullGuid then
                            Rec.Insert();
                        SetAddOptionToResultCondition(Rec.Code, 1);
                        CurrPage.Update();
                    end;
                }
                field(ChooseIsAcceptableForResult2; IsAcceptableValuesForThisRow[2])
                {
                    CaptionClass = '3,' + MatrixArrayCaptionSet[2];
                    ToolTip = 'Specifies if this value should be used as a pass value.';
                    Visible = Visible2;

                    trigger OnValidate()
                    begin
                        if Rec.Code = '' then
                            exit;
                        if Rec.SystemId = NullGuid then
                            Rec.Insert();
                        SetAddOptionToResultCondition(Rec.Code, 2);
                        CurrPage.Update();
                    end;
                }
                field(ChooseIsAcceptableForResult3; IsAcceptableValuesForThisRow[3])
                {
                    CaptionClass = '3,' + MatrixArrayCaptionSet[3];
                    ToolTip = 'Specifies if this value should be used as a pass value.';
                    Visible = Visible3;

                    trigger OnValidate()
                    begin
                        if Rec.Code = '' then
                            exit;
                        if Rec.SystemId = NullGuid then
                            Rec.Insert();
                        SetAddOptionToResultCondition(Rec.Code, 3);
                        CurrPage.Update();
                    end;
                }
                field(ChooseIsAcceptableForResult4; IsAcceptableValuesForThisRow[4])
                {
                    CaptionClass = '3,' + MatrixArrayCaptionSet[4];
                    ToolTip = 'Specifies if this value should be used as a pass value.';
                    Visible = Visible4;

                    trigger OnValidate()
                    begin
                        if Rec.Code = '' then
                            exit;
                        if Rec.SystemId = NullGuid then
                            Rec.Insert();
                        SetAddOptionToResultCondition(Rec.Code, 4);
                        CurrPage.Update();
                    end;
                }
                field(ChooseIsAcceptableForResult5; IsAcceptableValuesForThisRow[5])
                {
                    CaptionClass = '3,' + MatrixArrayCaptionSet[5];
                    ToolTip = 'Specifies if this value should be used as a pass value.';
                    Visible = Visible5;

                    trigger OnValidate()
                    begin
                        if Rec.Code = '' then
                            exit;
                        if Rec.SystemId = NullGuid then
                            Rec.Insert();
                        SetAddOptionToResultCondition(Rec.Code, 5);
                        CurrPage.Update();
                    end;
                }
                field(ChooseIsAcceptableForResult6; IsAcceptableValuesForThisRow[6])
                {
                    CaptionClass = '3,' + MatrixArrayCaptionSet[6];
                    ToolTip = 'Specifies if this value should be used as a pass value.';
                    Visible = Visible6;

                    trigger OnValidate()
                    begin
                        if Rec.Code = '' then
                            exit;
                        if Rec.SystemId = NullGuid then
                            Rec.Insert();
                        SetAddOptionToResultCondition(Rec.Code, 6);
                        CurrPage.Update();
                    end;
                }
                field(ChooseIsAcceptableForResult7; IsAcceptableValuesForThisRow[7])
                {
                    CaptionClass = '3,' + MatrixArrayCaptionSet[7];
                    ToolTip = 'Specifies if this value should be used as a pass value.';
                    Visible = Visible7;

                    trigger OnValidate()
                    begin
                        if Rec.Code = '' then
                            exit;
                        if Rec.SystemId = NullGuid then
                            Rec.Insert();
                        SetAddOptionToResultCondition(Rec.Code, 7);
                        CurrPage.Update();
                    end;
                }
                field(ChooseIsAcceptableForResult8; IsAcceptableValuesForThisRow[8])
                {
                    CaptionClass = '3,' + MatrixArrayCaptionSet[8];
                    ToolTip = 'Specifies if this value should be used as a pass value.';
                    Visible = Visible8;

                    trigger OnValidate()
                    begin
                        if Rec.Code = '' then
                            exit;
                        if Rec.SystemId = NullGuid then
                            Rec.Insert();
                        SetAddOptionToResultCondition(Rec.Code, 8);
                        CurrPage.Update();
                    end;
                }
                field(ChooseIsAcceptableForResult9; IsAcceptableValuesForThisRow[9])
                {
                    CaptionClass = '3,' + MatrixArrayCaptionSet[9];
                    ToolTip = 'Specifies if this value should be used as a pass value.';
                    Visible = Visible9;

                    trigger OnValidate()
                    begin
                        if Rec.Code = '' then
                            exit;
                        if Rec.SystemId = NullGuid then
                            Rec.Insert();
                        SetAddOptionToResultCondition(Rec.Code, 9);
                        CurrPage.Update();
                    end;
                }
                field(ChooseIsAcceptableForResult10; IsAcceptableValuesForThisRow[10])
                {
                    CaptionClass = '3,' + MatrixArrayCaptionSet[10];
                    ToolTip = 'Specifies if this value should be used as a pass value.';
                    Visible = Visible10;

                    trigger OnValidate()
                    begin
                        if Rec.Code = '' then
                            exit;
                        if Rec.SystemId = NullGuid then
                            Rec.Insert();
                        SetAddOptionToResultCondition(Rec.Code, 10);
                        CurrPage.Update();
                    end;
                }
                field("Group Code"; Rec."Group Code")
                {
                    Visible = false;
                }
                field("Code"; Rec.Code)
                {
                }
                field(Description; Rec.Description)
                {
                }
                field("Custom 1"; Rec."Custom 1")
                {
                    Visible = false;
                }
                field("Custom 2"; Rec."Custom 2")
                {
                    Visible = false;
                }
                field("Custom 3"; Rec."Custom 3")
                {
                    Visible = false;
                }
                field("Custom 4"; Rec."Custom 4")
                {
                    Visible = false;
                }
            }
        }
    }

    var
        QltyField: Record "Qlty. Field";
        QltyResultConditionMgmt: Codeunit "Qlty. Result Condition Mgmt.";
        MatrixSourceRecordId: array[10] of RecordId;
        NewLookup: Boolean;
        ExistingTable: Boolean;
        Visible1: Boolean;
        Visible2: Boolean;
        Visible3: Boolean;
        Visible4: Boolean;
        Visible5: Boolean;
        Visible6: Boolean;
        Visible7: Boolean;
        Visible8: Boolean;
        Visible9: Boolean;
        Visible10: Boolean;
        MatrixArrayConditionCellData: array[10] of Text;
        MatrixArrayConditionDescriptionCellData: array[10] of Text;
        MatrixArrayCaptionSet: array[10] of Text;
        MatrixVisibleState: array[10] of Boolean;
        DictionaryOptionsThatAreDefaults: Dictionary of [Text, Boolean];
        IsAcceptableValuesForThisRow: array[10] of Boolean;
        KeySeparatorTok: Label '~~~', Locked = true;
        WhereTok: Label 'WHERE', Locked = true;
        CaptionOfTable: Text;
        CaptionOfField: Text;
        TableFilter: Text;
        DefaultValue: Text[250];
        OldField: Code[20];
        NullGuid: Guid;

    trigger OnInit()
    begin
        NewLookup := true;
    end;

    trigger OnOpenPage()
    begin
        UpdateRowResultInformation();
    end;

    trigger OnAfterGetRecord()
    var
        Iterator: Integer;
    begin
        for Iterator := 1 to ArrayLen(IsAcceptableValuesForThisRow) do
            if not DictionaryOptionsThatAreDefaults.Get(GetKey(Rec.Code, Iterator), IsAcceptableValuesForThisRow[Iterator]) then
                IsAcceptableValuesForThisRow[Iterator] := false;
    end;

    procedure HandleOnValidateSimpleOrComplex(ShowSimple: Boolean)
    var
        MostCommonTableReasonCode: Record "Reason Code";
        OldConfigQltyField: Record "Qlty. Field";
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
    begin
        OldConfigQltyField := QltyField;
        NewLookup := ShowSimple;
        ExistingTable := not ShowSimple;
        if ExistingTable and (QltyField."Lookup Table No." = 0) then begin
            QltyField.Validate("Lookup Table No.", Database::"Reason Code");
            QltyField.Validate("Lookup Field No.", MostCommonTableReasonCode.FieldNo(Code));
        end else
            if not ExistingTable then begin
                QltyField.Validate("Lookup Table No.", Database::"Qlty. Lookup Code");
                QltyField.Validate("Lookup Field No.", Rec.FieldNo(Code));
                if QltyField."Lookup Table Filter" = '' then begin
                    Rec.SetRange("Group Code", QltyField.Code);
                    TableFilter := Rec.GetView(true);
                    TableFilter := QltyFilterHelpers.CleanUpWhereClause(TableFilter);

                    QltyField.Validate("Lookup Table Filter", TableFilter);
                end;
            end;
        QltyField.Modify(true);
        CurrPage.Update(false);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        QltyField.CalcFields("Lookup Table Caption");
        CaptionOfTable := QltyField."Lookup Table Caption";
        QltyField.CalcFields("Lookup Field Caption");
        CaptionOfField := QltyField."Lookup Field Caption";
        TableFilter := QltyField."Lookup Table Filter";
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Group Code" := GetGroupCodeFromRecordOrFilter(false);
        if Rec."Group Code" = '' then
            Rec."Group Code" := QltyField.Code;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if QltyField.Code <> '' then
            if QltyField.Modify(true) then;

        UpdateResultOptions();
        CurrPage.Update(false);
    end;

    procedure GetGroupCodeFromRecordOrFilter(OnlyFilters: Boolean) GroupCode: Code[20]
    var
        FilterGroupIterator: Integer;
    begin
        if (not OnlyFilters) and (Rec."Group Code" <> '') then
            exit(Rec."Group Code");
        FilterGroupIterator := 4;
        repeat
            Rec.FilterGroup(FilterGroupIterator);
            if Rec.GetFilter("Group Code") <> '' then
                GroupCode := Rec.GetRangeMin("Group Code");

            FilterGroupIterator -= 1;
        until (FilterGroupIterator < 0) or (GroupCode <> '');
        Rec.FilterGroup(0);
    end;

    /// <summary>
    /// Introduced to allow setting values implicitly when creating new records.
    /// </summary>
    local procedure UpdateResultOptions()
    var
        Iterator: Integer;
    begin
        for Iterator := 1 to 10 do
            if IsAcceptableValuesForThisRow[Iterator] then
                SetAddOptionToResultCondition(Rec.Code, Iterator);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        if QltyField.Code <> '' then begin
            QltyField.UpdateAllowedValuesFromTableLookup();
            QltyField.Modify(true);
        end;
        CurrPage.Update(false);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        if QltyField.Code <> '' then begin
            QltyField.UpdateAllowedValuesFromTableLookup();
            QltyField.Modify(true);
        end;
    end;

    procedure ChooseLookupTable()
    begin
        QltyField.AssistEditLookupTable();
        QltyField.Modify(true);
        QltyField.CalcFields("Lookup Table Caption", "Lookup Field Caption");
        CaptionOfTable := QltyField."Lookup Table Caption";
        CaptionOfField := QltyField."Lookup Field Caption";
        TableFilter := QltyField."Lookup Table Filter";
        CurrPage.Update(false);
    end;

    procedure ChooseLookupField()
    begin
        QltyField.AssistEditLookupField();
        QltyField.UpdateAllowedValuesFromTableLookup();
        QltyField.Modify(true);
        QltyField.CalcFields("Lookup Table Caption", "Lookup Field Caption");
        CaptionOfTable := QltyField."Lookup Table Caption";
        CaptionOfField := QltyField."Lookup Field Caption";
        TableFilter := QltyField."Lookup Table Filter";
        QltyField.Modify(true);
        CurrPage.Update(false);
    end;

    procedure ChooseLookupFilter()
    begin
        QltyField.AssistEditLookupTableFilter();
        QltyField.UpdateAllowedValuesFromTableLookup();
        QltyField.Modify(true);
        QltyField.CalcFields("Lookup Table Caption", "Lookup Field Caption");
        CaptionOfTable := QltyField."Lookup Table Caption";
        CaptionOfField := QltyField."Lookup Field Caption";
        TableFilter := QltyField."Lookup Table Filter";
        CurrPage.Update(false);
    end;

    procedure LoadExistingField(CurrentField: Code[20])
    var
        FindWhere: Integer;
    begin
        if CurrentField = '' then
            exit;

        Rec.SetRange("Group Code", CurrentField);
        if Rec.Find('-') then;

        if not QltyField.Get(CurrentField) then begin
            QltyField.Init();
            QltyField.Code := CurrentField;
            QltyField.Insert();
        end;
        QltyField.SetRecFilter();
        DefaultValue := QltyField."Default Value";
        if QltyField."Lookup Table No." = Database::"Qlty. Lookup Code" then begin
            if QltyField."Lookup Table Filter" <> '' then
                Rec.SetView(QltyField."Lookup Table Filter")
            else
                Rec.SetRange("Group Code", QltyField.Code);

            if OldField <> CurrentField then begin
                NewLookup := true;
                ExistingTable := false;
            end;
            TableFilter := Rec.GetView(true);
            FindWhere := StrPos(TableFilter, WhereTok);
            if FindWhere > 1 then
                TableFilter := CopyStr(TableFilter, FindWhere);
        end else begin
            NewLookup := false;
            ExistingTable := true;
            TableFilter := QltyField."Lookup Table Filter";
        end;

        UpdateRowResultInformation();

        LoadExistingResultSelections();
        CurrPage.Update(false);
        OldField := CurrentField;
    end;

    local procedure UpdateRowResultInformation()
    begin
        if QltyField.Code = '' then
            exit;

        QltyResultConditionMgmt.GetPromotedResultsForField(QltyField, MatrixSourceRecordId, MatrixArrayConditionCellData, MatrixArrayConditionDescriptionCellData, MatrixArrayCaptionSet, MatrixVisibleState);

        Visible1 := MatrixVisibleState[1];
        Visible2 := MatrixVisibleState[2];
        Visible3 := MatrixVisibleState[3];
        Visible4 := MatrixVisibleState[4];
        Visible5 := MatrixVisibleState[5];
        Visible6 := MatrixVisibleState[6];
        Visible7 := MatrixVisibleState[7];
        Visible8 := MatrixVisibleState[8];
        Visible9 := MatrixVisibleState[9];
        Visible10 := MatrixVisibleState[10];
    end;

    local procedure GetKey(Option: Code[100]; Position: Integer): Text
    begin
        exit(Option + KeySeparatorTok + Format(Position, 0, 9));
    end;

    procedure SetAddOptionToResultCondition(Option: Code[100]; ResultPosition: Integer)
    var
        QltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        ResultConditionRecordRef: RecordRef;
        IgnorePreviousValue: Boolean;
        InAcceptable: Boolean;
        AllResultConditions: Text;
    begin
        InAcceptable := IsAcceptableValuesForThisRow[ResultPosition];
        if DictionaryOptionsThatAreDefaults.Set(GetKey(Option, ResultPosition), InAcceptable, IgnorePreviousValue) then;
        if not InAcceptable then
            if DictionaryOptionsThatAreDefaults.Remove(GetKey(Option, ResultPosition)) then;

        if QltyField.Code <> '' then begin
            if InAcceptable then
                AllResultConditions := CollectAllResultConditionsWithAddedOption(ResultPosition, Option)
            else
                AllResultConditions := CollectAllResultConditions(ResultPosition);

            ResultConditionRecordRef := MatrixSourceRecordId[ResultPosition].GetRecord();
            ResultConditionRecordRef.SetTable(QltyIResultConditConf);
            QltyIResultConditConf.SetRecFilter();
            QltyIResultConditConf.FindFirst();
            QltyIResultConditConf.Condition := CopyStr(AllResultConditions, 1, MaxStrLen(QltyIResultConditConf.Condition));
            QltyIResultConditConf.Modify(true);
        end;
    end;

    procedure LoadExistingResultSelections()
    var
        QltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        ResultConditionRecordRef: RecordRef;
        Iterator: Integer;
        AllAllowedForCondition: List of [Text];
        AllowedForCondition: Text;
        IgnorePreviousValue: Boolean;
    begin
        Clear(DictionaryOptionsThatAreDefaults);
        Clear(IsAcceptableValuesForThisRow);
        for Iterator := 1 to ArrayLen(MatrixSourceRecordId) do
            if MatrixArrayCaptionSet[Iterator] <> '' then
                if MatrixSourceRecordId[Iterator].TableNo() <> 0 then begin
                    ResultConditionRecordRef := MatrixSourceRecordId[Iterator].GetRecord();
                    ResultConditionRecordRef.SetTable(QltyIResultConditConf);
                    QltyIResultConditConf.SetRecFilter();
                    if QltyIResultConditConf.FindFirst() then begin
                        AllAllowedForCondition := QltyIResultConditConf.Condition.Split('|');
                        foreach AllowedForCondition in AllAllowedForCondition do
                            if DictionaryOptionsThatAreDefaults.Set(GetKey(CopyStr(AllowedForCondition, 1, 100), Iterator), true, IgnorePreviousValue) then;
                    end;
                end;
    end;

    procedure CollectAllResultConditions(ResultPosition: Integer): Text;
    begin
        exit(CollectAllResultConditionsWithAddedOption(ResultPosition, ''));
    end;

    local procedure CollectAllResultConditionsWithAddedOption(ResultPosition: Integer; EnsureOption: Code[100]) AllConditions: Text;
    var
        QltyLookupCode: Record "Qlty. Lookup Code";
        AtLeastOne: Boolean;
        IsSet: Boolean;
    begin
        QltyLookupCode.CopyFilters(Rec);
        if QltyLookupCode.FindSet() then
            repeat
                if DictionaryOptionsThatAreDefaults.Get(GetKey(QltyLookupCode.Code, ResultPosition), IsSet) then
                    if IsSet then begin
                        if AtLeastOne then
                            AllConditions += '|';
                        AllConditions += QltyLookupCode.Code;
                        AtLeastOne := true;
                    end;
            until QltyLookupCode.Next() = 0;

        if EnsureOption <> '' then begin
            QltyLookupCode.SetRange(Code, EnsureOption);
            if QltyLookupCode.IsEmpty() then begin
                if AtLeastOne then
                    AllConditions += '|';
                AllConditions += EnsureOption;
                AtLeastOne := true;
            end;
        end;
    end;

    /// <summary>
    /// Validates the default value.
    /// </summary>
    protected procedure ValidateDefaultValue()
    begin
        QltyField.Validate("Default Value", DefaultValue);
        QltyField.Modify();
    end;

    /// <summary>
    /// Assist-Edits the default value.
    /// </summary>
    protected procedure AssistEditDefaultValue()
    begin
        QltyField.AssistEditDefaultValue();
        QltyField.Modify();
        LoadExistingField(QltyField.Code);
    end;
}
