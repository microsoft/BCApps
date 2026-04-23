// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

using System.Integration;
using System.Reflection;

/// <summary>
/// Two-section scenario picker. The top section has rough filters (target page, scenario
/// type); the bottom section shows the resulting scenarios. Call <c>LoadFromPage</c> before
/// running the page.
/// </summary>
page 8432 "Perf. Analysis Control Lookup"
{
    Caption = 'Scenarios';
    PageType = List;
    ApplicationArea = All;
    SourceTable = "Perf. Analysis Control Buf";
    SourceTableTemporary = true;
    SourceTableView = sorting("Sort Group", "Scenario");
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Extensible = false;
    LinksAllowed = false;
    Permissions = tabledata AllObjWithCaption = r,
                  tabledata Field = r,
                  tabledata "Page Action" = r,
                  tabledata "Page Metadata" = r;

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                Caption = 'Filter';
                field(PageFilterName; TargetPageNameFilter)
                {
                    Caption = 'Page';
                    ApplicationArea = All;
                    ToolTip = 'Specifies which page the scenario targets. The main page is selected by default; switch to a subpage such as the lines to narrow down the list below.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupTargetPage(Text));
                    end;

                    trigger OnValidate()
                    begin
                        ResolveTargetPage();
                        ApplyFilters();
                    end;
                }
                field(ScenarioTypeFilter; ScenarioTypeFilterOpt)
                {
                    Caption = 'Scenario type';
                    OptionCaption = 'Invoke an action,Change a field value';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the kind of scenario to show.';

                    trigger OnValidate()
                    begin
                        ApplyFilters();
                    end;
                }
            }
            repeater(Group)
            {
                Caption = 'Scenarios';
                Editable = false;
                field(Scenario; Rec."Scenario")
                {
                    Caption = 'Scenario';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the scenario. Pick the one that best matches what you were doing.';
                }
            }
        }
    }

    var
        ChangeFieldFmtLbl: Label 'Change the value of the ''%1'' field', Comment = '%1 = field caption';
        ChangeFieldOnSubpageFmtLbl: Label 'Change the value of the ''%1'' field of the %2', Comment = '%1 = field caption, %2 = subpage name';
        InvokeActionFmtLbl: Label 'Invoke the ''%1'' action', Comment = '%1 = action caption';
        InvokeActionOnSubpageFmtLbl: Label 'Invoke the ''%1'' action on the %2', Comment = '%1 = action caption, %2 = subpage name';
        CloseActionLbl: Label 'Close the page';
        MainPageName: Text[250];
        MainPageId: Integer;
        TargetPageNameFilter: Text[250];
        TargetPageIdFilter: Integer;
        ScenarioTypeFilterOpt: Option Action,Field;

    /// <summary>
    /// Populate the lookup from the given root page. Scenarios include actions and fields
    /// from the page itself, fields and actions from any detectable subpages (pages whose
    /// source table has a foreign key to the root page's source table), and a standard
    /// "Close the page" entry. Every row carries a <c>Target Page Id</c> and a
    /// <c>Scenario Type</c> so the lookup page can filter on them.
    /// </summary>
    internal procedure LoadFromPage(RootPageId: Integer)
    var
        RootPage: Record "Page Metadata";
        SubPageIds: List of [Integer];
        SubPageId: Integer;
    begin
        Rec.Reset();
        Rec.DeleteAll();
        MainPageId := RootPageId;
        if RootPage.Get(RootPageId) then
            MainPageName := GetPageDisplayName(RootPage)
        else
            MainPageName := '';
        if MainPageName <> '' then begin
            AddActionScenarios(RootPage.ID, MainPageName, MainPageName, 10);
            AddFieldScenarios(RootPage.SourceTable, RootPage.ID, MainPageName, MainPageName, 20, false);
            FindSubpages(RootPage.SourceTable, RootPage.ID, SubPageIds);
            foreach SubPageId in SubPageIds do
                AddSubpageScenarios(SubPageId);
        end;
        AddScenarioEx(100, CloseActionLbl, MainPageId, MainPageName, Rec."Scenario Type"::Action, 'Close');
    end;

    trigger OnOpenPage()
    begin
        TargetPageNameFilter := MainPageName;
        TargetPageIdFilter := MainPageId;
        ScenarioTypeFilterOpt := ScenarioTypeFilterOpt::Action;
        ApplyFilters();
    end;

    local procedure ApplyFilters()
    begin
        Rec.Reset();
        Rec.SetCurrentKey("Sort Group", "Scenario");
        if TargetPageIdFilter <> 0 then
            Rec.SetRange("Target Page Id", TargetPageIdFilter);
        case ScenarioTypeFilterOpt of
            ScenarioTypeFilterOpt::Field:
                Rec.SetRange("Scenario Type", Rec."Scenario Type"::Field);
            ScenarioTypeFilterOpt::Action:
                Rec.SetRange("Scenario Type", Rec."Scenario Type"::Action);
        end;
        CurrPage.Update(false);
    end;

    local procedure LookupTargetPage(var Text: Text): Boolean
    var
        Ids: List of [Integer];
        Names: List of [Text[250]];
        Choices: Text;
        i: Integer;
        SelectedIdx: Integer;
        PickPromptLbl: Label 'Filter scenarios by page';
    begin
        BuildTargetPageChoiceLists(Ids, Names);
        if Ids.Count() = 0 then
            exit(false);
        for i := 1 to Names.Count() do begin
            if i > 1 then
                Choices += ',';
            Choices += Names.Get(i);
        end;
        SelectedIdx := Dialog.StrMenu(Choices, 1, PickPromptLbl);
        if SelectedIdx = 0 then
            exit(false);
        TargetPageIdFilter := Ids.Get(SelectedIdx);
        TargetPageNameFilter := Names.Get(SelectedIdx);
        Text := TargetPageNameFilter;
        ApplyFilters();
        exit(true);
    end;

    local procedure BuildTargetPageChoiceLists(var Ids: List of [Integer]; var Names: List of [Text[250]])
    var
        Seen: List of [Integer];
    begin
        Rec.Reset();
        // Main page first, then subpages in the order they appear.
        if Rec.FindSet() then
            repeat
                if (Rec."Target Page Id" <> 0) and (not Seen.Contains(Rec."Target Page Id")) then begin
                    Seen.Add(Rec."Target Page Id");
                    if Rec."Target Page Id" = MainPageId then begin
                        Ids.Insert(1, Rec."Target Page Id");
                        Names.Insert(1, Rec."Target Page Name");
                    end else begin
                        Ids.Add(Rec."Target Page Id");
                        Names.Add(Rec."Target Page Name");
                    end;
                end;
            until Rec.Next() = 0;
        Rec.Reset();
    end;

    local procedure ResolveTargetPage()
    begin
        // When the user types a name instead of picking from the lookup, match the buffer case-insensitively.
        if TargetPageNameFilter = '' then begin
            TargetPageIdFilter := 0;
            exit;
        end;
        Rec.Reset();
        Rec.SetFilter("Target Page Name", '@' + TargetPageNameFilter);
        if Rec.FindFirst() then begin
            TargetPageIdFilter := Rec."Target Page Id";
            TargetPageNameFilter := Rec."Target Page Name";
        end else
            TargetPageIdFilter := 0;
        Rec.Reset();
    end;

    local procedure AddSubpageScenarios(SubPageId: Integer)
    var
        SubPage: Record "Page Metadata";
        SubPageName: Text[250];
    begin
        if not SubPage.Get(SubPageId) then
            exit;
        SubPageName := GetPageDisplayName(SubPage);
        if SubPageName = '' then
            exit;
        AddActionScenarios(SubPage.ID, SubPageName, SubPageName, 30);
        AddFieldScenarios(SubPage.SourceTable, SubPage.ID, SubPageName, SubPageName, 40, true);
    end;

    local procedure AddFieldScenarios(TableNo: Integer; TargetPageId: Integer; TargetPageName: Text[250]; SubpageName: Text[250]; SortGroup: Integer; IsSubpage: Boolean)
    var
        "Field": Record "Field";
        Caption: Text[250];
        ScenarioText: Text[500];
    begin
        if TableNo = 0 then
            exit;
        Field.SetRange(TableNo, TableNo);
        Field.SetFilter(Class, '%1|%2', Field.Class::Normal, Field.Class::FlowField);
        Field.SetRange(ObsoleteState, Field.ObsoleteState::No);
        if Field.FindSet() then
            repeat
                if Field."Field Caption" <> '' then
                    Caption := CopyStr(Field."Field Caption", 1, 250)
                else
                    Caption := CopyStr(Field.FieldName, 1, 250);
                if IsSubpage then
                    ScenarioText := CopyStr(StrSubstNo(ChangeFieldOnSubpageFmtLbl, Caption, SubpageName), 1, 500)
                else
                    ScenarioText := CopyStr(StrSubstNo(ChangeFieldFmtLbl, Caption), 1, 500);
                AddScenarioEx(SortGroup, ScenarioText, TargetPageId, TargetPageName, Rec."Scenario Type"::Field, CopyStr(Field.FieldName, 1, 250));
            until Field.Next() = 0;
    end;

    local procedure AddActionScenarios(PageId: Integer; TargetPageName: Text[250]; SubpageName: Text[250]; SortGroup: Integer)
    var
        CaptionsAndNames: Dictionary of [Text[250], Text[250]];
        Caption: Text[250];
        SystemName: Text[250];
        ScenarioText: Text[500];
    begin
        if not TryCollectActionCaptions(PageId, CaptionsAndNames) then
            exit;
        foreach Caption in CaptionsAndNames.Keys() do begin
            SystemName := CaptionsAndNames.Get(Caption);
            if SubpageName = MainPageName then
                ScenarioText := CopyStr(StrSubstNo(InvokeActionFmtLbl, Caption), 1, 500)
            else
                ScenarioText := CopyStr(StrSubstNo(InvokeActionOnSubpageFmtLbl, Caption, SubpageName), 1, 500);
            AddScenarioEx(SortGroup, ScenarioText, PageId, TargetPageName, Rec."Scenario Type"::Action, SystemName);
        end;
    end;

    [TryFunction]
    local procedure TryCollectActionCaptions(PageId: Integer; var CaptionsAndNames: Dictionary of [Text[250], Text[250]])
    var
        PageAction: Record "Page Action";
        Caption: Text[250];
        SystemName: Text[250];
    begin
        // Read the Page Action virtual table directly. Unlike NavPageActionALFunctions.GetActions,
        // it does not apply a static Visible filter - which is important because extension-added
        // actions often have conditional Visible properties that evaluate to false without a
        // record context, causing them to be hidden from the wizard.
        PageAction.SetRange("Page ID", PageId);
        PageAction.SetFilter("Action Type", '%1|%2|%3',
            PageAction."Action Type"::Action,
            PageAction."Action Type"::CustomAction,
            PageAction."Action Type"::FileUploadAction);
        if PageAction.FindSet() then
            repeat
                Caption := CopyStr(PageAction.Caption, 1, 250);
                Caption := StripAmpersand(Caption);
                SystemName := CopyStr(PageAction.Name, 1, 250);
                if (Caption <> '') and (SystemName <> '') and (not CaptionsAndNames.ContainsKey(Caption)) then
                    CaptionsAndNames.Add(Caption, SystemName);
            until PageAction.Next() = 0;
    end;

    local procedure StripAmpersand(Input: Text[250]): Text[250]
    var
        OutTxt: Text[250];
        i: Integer;
        Len: Integer;
    begin
        // Action captions carry Windows mnemonics such as "P&ost". Strip single '&'
        // but preserve escaped '&&' (which displays as a literal '&').
        Len := StrLen(Input);
        i := 1;
        while i <= Len do
            if Input[i] = '&' then begin
                if (i < Len) and (Input[i + 1] = '&') then begin
                    OutTxt += '&';
                    i += 2;
                end else
                    i += 1;
            end else begin
                OutTxt += Format(Input[i]);
                i += 1;
            end;
        exit(OutTxt);
    end;

    local procedure FindSubpages(RootSourceTable: Integer; RootPageId: Integer; var SubPageIds: List of [Integer])
    var
        RelField: Record "Field";
        LineNoProbe: Record "Field";
        PkProbe: Record "Field";
        SubPage: Record "Page Metadata";
        DetailTables: List of [Integer];
        DetailTable: Integer;
    begin
        Clear(SubPageIds);
        if RootSourceTable = 0 then
            exit;
        // Collect candidate detail tables: tables that declare a FK to the root source
        // table. This is a superset of actual subpages (e.g. archive tables, comment
        // lines) so we tighten further below.
        RelField.SetRange(RelationTableNo, RootSourceTable);
        RelField.SetRange(Class, RelField.Class::Normal);
        RelField.SetRange(ObsoleteState, RelField.ObsoleteState::No);
        if RelField.FindSet() then
            repeat
                if (RelField.TableNo <> RootSourceTable) and (not DetailTables.Contains(RelField.TableNo)) then
                    DetailTables.Add(RelField.TableNo);
            until RelField.Next() = 0;

        foreach DetailTable in DetailTables do begin
            // Heuristic: a real subpage table is one whose primary key includes a field
            // referencing the root source table AND that has a "Line No." field. This
            // matches Sales Line / Purchase Line / Prod. Order Line and excludes things
            // like Sales Header Archive, Approval Entry, or comment/reminder tables.
            PkProbe.Reset();
            PkProbe.SetRange(TableNo, DetailTable);
            PkProbe.SetRange(IsPartOfPrimaryKey, true);
            PkProbe.SetRange(RelationTableNo, RootSourceTable);
            if PkProbe.IsEmpty() then
                continue;
            LineNoProbe.Reset();
            LineNoProbe.SetRange(TableNo, DetailTable);
            LineNoProbe.SetRange(FieldName, 'Line No.');
            if LineNoProbe.IsEmpty() then
                continue;

            // Prefer a ListPart page on that detail table. Factboxes are typically
            // CardParts and must not be included here.
            SubPage.Reset();
            SubPage.SetRange(SourceTable, DetailTable);
            SubPage.SetRange(PageType, SubPage.PageType::ListPart);
            if SubPage.FindFirst() then
                if (SubPage.ID <> RootPageId) and (not SubPageIds.Contains(SubPage.ID)) then
                    SubPageIds.Add(SubPage.ID);
        end;
    end;

    local procedure GetPageDisplayName(var PageMeta: Record "Page Metadata"): Text[250]
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        if AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Page, PageMeta.ID) and (AllObjWithCaption."Object Caption" <> '') then
            exit(CopyStr(AllObjWithCaption."Object Caption", 1, 250));
        exit(PageMeta.Name);
    end;

    local procedure AddScenarioEx(SortGroup: Integer; Text: Text[500]; TargetPageId: Integer; TargetPageName: Text[250]; ScenarioType: Option Field,Action; SystemName: Text[250])
    var
        NextLineNo: Integer;
    begin
        if Text = '' then
            exit;
        // Skip duplicates within the same target page.
        Rec.Reset();
        Rec.SetRange("Target Page Id", TargetPageId);
        Rec.SetRange("Scenario", Text);
        if not Rec.IsEmpty() then begin
            Rec.Reset();
            exit;
        end;
        Rec.Reset();
        NextLineNo := 10000;
        if Rec.FindLast() then
            NextLineNo := Rec."Line No." + 10000;
        Rec.Init();
        Rec."Line No." := NextLineNo;
        Rec."Sort Group" := SortGroup;
        Rec."Scenario" := Text;
        Rec."Target Page Id" := TargetPageId;
        Rec."Target Page Name" := TargetPageName;
        Rec."Scenario Type" := ScenarioType;
        Rec.Name := SystemName;
        Rec.Insert();
    end;
}
