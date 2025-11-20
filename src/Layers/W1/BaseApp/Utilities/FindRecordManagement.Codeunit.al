// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Resources.Resource;
using System.Reflection;
using System.Text;
using Microsoft.Finance.AllocationAccount;

codeunit 703 "Find Record Management"
{
    Permissions = tabledata "G/L Entry" = r;

    trigger OnRun()
    begin
    end;

    var
        WrongParameterTypeErr: Label 'Parameter type must be Record or RecordRef.';

    procedure FindLastEntryIgnoringSecurityFilter(var RecRef: RecordRef) Found: Boolean;
    var
        IsHandled: Boolean;
        xSecurityFilter: SecurityFilter;
    begin
        OnBeforeFindLastEntryIgnoringSecurityFilter(RecRef, Found, IsHandled);
        if IsHandled then
            exit(Found);

        xSecurityFilter := RecRef.SecurityFiltering;
        RecRef.SecurityFiltering(RecRef.SecurityFiltering::Ignored);
        Found := RecRef.FindLast();
        if RecRef.SecurityFiltering <> xSecurityFilter then
            RecRef.SecurityFiltering(xSecurityFilter)
    end;

    [Scope('OnPrem')]
    procedure GetIntFieldValue(RecRef: RecordRef; FieldNo: Integer): Integer;
    var
        IntFields: list of [Integer];
    begin
        IntFields.Add(FieldNo);
        GetIntFieldValues(RecRef, IntFields);
        exit(IntFields.Get(1));
    end;

    [Scope('OnPrem')]
    procedure GetIntFieldValues(RecRef: RecordRef; var IntFields: list of [Integer])
    var
        FieldNos: list of [Integer];
        FieldNo: Integer;
        FieldValue: Variant;
    begin
        FieldNos := IntFields;
        clear(IntFields);
        foreach FieldNo in FieldNos do
            if IsFieldValid(RecRef, FieldNo, FieldType::Integer, FieldValue) then
                IntFields.Add(FieldValue)
            else
                IntFields.Add(0);
    end;

    procedure GetLastEntryIntFieldValue(SourceRec: Variant; FieldNo: Integer): Integer;
    var
        IntFields: list of [Integer];
    begin
        IntFields.Add(FieldNo);
        GetLastEntryIntFieldValues(SourceRec, IntFields);
        exit(IntFields.Get(1));
    end;

    procedure GetLastEntryIntFieldValues(SourceRec: Variant; var FieldNoValues: List of [Integer])
    var
        RecRef: RecordRef;
        FieldNo: Integer;
        FirstIteration: Boolean;
    begin
        ConvertVariantToRecordRef(SourceRec, RecRef);
        RecRef.Reset();
        FirstIteration := true;
        foreach FieldNo in FieldNoValues do
            if RecRef.FieldExist(FieldNo) then
                if FirstIteration then begin
                    RecRef.SetLoadFields(FieldNo);
                    FirstIteration := false;
                end else
                    RecRef.AddLoadFields(FieldNo);

        FindLastEntryIgnoringSecurityFilter(RecRef);
        GetIntFieldValues(RecRef, FieldNoValues);
    end;

    local procedure ConvertVariantToRecordRef(SourceRec: Variant; var RecRef: RecordRef)
    begin
        case true of
            SourceRec.IsRecordRef:
                RecRef := SourceRec;
            SourceRec.IsRecord:
                RecRef.GetTable(SourceRec);
            else
                Error(WrongParameterTypeErr);
        end;
    end;

    local procedure IsFieldValid(RecRef: RecordRef; FieldNo: Integer; ExpectedFieldType: FieldType; var Value: Variant): Boolean
    var
        FldRef: FieldRef;
    begin
        Clear(Value);
        if RecRef.FieldExist(FieldNo) then begin
            FldRef := RecRef.Field(FieldNo);
            if FldRef.Type = ExpectedFieldType then begin
                if FldRef.Class = FieldClass::FlowField then
                    FldRef.CalcField();
                Value := FldRef.Value();
                exit(true);
            end;
        end;
    end;

    procedure FindNoFromTypedValue(Type: Option " ","G/L Account",Item,Resource,"Fixed Asset","Charge (Item)",,,,,"Allocation Account"; Value: Code[20]; UseDefaultTableRelationFilters: Boolean): Code[20]
    var
        Item: Record Item;
        FoundNo: Code[20];
    begin
        OnBeforeFindNoFromTypedValue(Type, Value, FoundNo);
        if FoundNo <> '' then
            exit(FoundNo);

        if Type = Type::Item then
            exit(Item.GetItemNo(Value));

        FoundNo := FindNoByDescription(Type, Value, UseDefaultTableRelationFilters);
        if FoundNo <> '' then
            exit(FoundNo);
        exit(Value);
    end;

    [Scope('OnPrem')]
    procedure FindNoByDescription(Type: Option " ","G/L Account",Item,Resource,"Fixed Asset","Charge (Item)",,,,,"Allocation Account"; Description: Text; UseDefaultTableRelationFilters: Boolean): Code[20]
    var
        GLAccount: Record "G/L Account";
        ResultValue: Text;
        RecordView: Text;
    begin
        if UseDefaultTableRelationFilters and (Type = Type::"G/L Account") then
            RecordView := GetGLAccountTableRelationView();

        if FindRecordByDescriptionAndView(ResultValue, Type, Description, RecordView) = 1 then
            exit(CopyStr(ResultValue, 1, MaxStrLen(GLAccount."No.")));

        exit('');
    end;

    procedure FindRecordByDescription(var Result: Text; Type: Option " ","G/L Account",Item,Resource,"Fixed Asset","Charge (Item)",,,,,"Allocation Account"; SearchText: Text): Integer
    begin
        exit(FindRecordByDescriptionAndView(Result, Type, SearchText, ''));
    end;

    [Scope('OnPrem')]
    procedure FindRecordByDescriptionAndView(var Result: Text; Type: Option " ","G/L Account",Item,Resource,"Fixed Asset","Charge (Item)",,,,,"Allocation Account"; SearchText: Text; RecordView: Text) RecordsCount: Integer
    var
        RecRef: RecordRef;
        SearchFieldRef: array[4] of FieldRef;
        SearchFieldNo: array[4] of Integer;
        KeyNoMaxStrLen: Integer;
        RecWithoutQuote: Text;
        RecFilterFromStart: Text;
        RecFilterContains: Text;
        MatchCount: Integer;
        IsHandled: Boolean;
    begin
        // Try to find a record by SearchText looking into "No." OR "Description" fields
        // SearchFieldNo[1] - "No."/Code
        // SearchFieldNo[2] - "Description"/"Name"
        // SearchFieldNo[3] - "Base Unit of Measure" (used for items)
        Result := '';

        if SearchText = '' then
            exit(0);

        GetRecRefAndFieldsNoByType(RecRef, Type, SearchFieldNo);
        RecRef.SetView(RecordView);

        SearchFieldRef[1] := RecRef.Field(SearchFieldNo[1]);
        SearchFieldRef[2] := RecRef.Field(SearchFieldNo[2]);
        if SearchFieldNo[3] <> 0 then
            SearchFieldRef[3] := RecRef.Field(SearchFieldNo[3]);

        IsHandled := false;
        MatchCount := 0;
        OnBeforeFindRecordByDescriptionAndView(Result, Type, RecRef, SearchFieldRef, SearchText, RecordView, MatchCount, IsHandled);
        if IsHandled then
            exit(MatchCount);

        // Try GET(SearchText)
        KeyNoMaxStrLen := SearchFieldRef[1].Length;
        if StrLen(SearchText) <= KeyNoMaxStrLen then begin
            SearchFieldRef[1].SetRange(CopyStr(SearchText, 1, KeyNoMaxStrLen));
            RecRef.SetLoadFields(SearchFieldRef[1].Number);
            if RecRef.FindFirst() then begin
                Result := SearchFieldRef[1].Value();
                exit(1);
            end;
        end;
        SearchFieldRef[1].SetRange();
        ClearLastError();

        RecWithoutQuote := ConvertStr(SearchText, '''()&|', '?????');

        // Try FINDFIRST "No." by mask "Search string *"
        if TrySetFilterOnFieldRef(SearchFieldRef[1], RecWithoutQuote + '*') then begin
            RecRef.SetLoadFields(SearchFieldRef[1].Number);
            if RecRef.FindFirst() then begin
                Result := SearchFieldRef[1].Value();
                exit(1);
            end;
        end;
        SearchFieldRef[1].SetRange();
        ClearLastError();

        // Two items with descrptions = "aaa" and "AAA";
        // Try FINDFIRST by exact "Description" = "AAA"
        SearchFieldRef[2].SetRange(CopyStr(SearchText, 1, SearchFieldRef[2].Length));
        RecRef.SetLoadFields(SearchFieldRef[1].Number);
        if RecRef.FindFirst() then begin
            Result := SearchFieldRef[1].Value();
            exit(1);
        end;
        SearchFieldRef[2].SetRange();

        // Example of SearchText = "Search string ''";
        // Try FINDFIRST "Description" by mask "@Search string ?"
        SearchFieldRef[2].SetFilter('''@' + RecWithoutQuote + '''');
        RecRef.SetLoadFields(SearchFieldRef[1].Number);
        if RecRef.FindFirst() then begin
            Result := SearchFieldRef[1].Value();
            exit(1);
        end;
        SearchFieldRef[2].SetRange();

        // Try FINDSET "No." OR "Description" by mask "@Search string ?*"
        RecFilterFromStart := '''@' + RecWithoutQuote + '*''';
        if SearchFieldRef[1].Type <> SearchFieldRef[1].Type::Code then begin //already processed with Try FINDFIRST "No." by mask "Search string *"            
            SearchFieldRef[1].SetFilter(RecFilterFromStart);
            GetRecordsSearchResult(RecRef, SearchFieldRef[1].Number, Result, RecordsCount);
            SearchFieldRef[1].SetRange();
        end;

        SearchFieldRef[2].SetFilter(RecFilterFromStart);
        OnBeforeFindRecordStartingWithSearchString(Type, RecRef, RecFilterFromStart);
        GetRecordsSearchResult(RecRef, SearchFieldRef[1].Number, Result, RecordsCount);
        SearchFieldRef[2].SetRange();

        if RecordsCount > 0 then
            exit(RecordsCount);

        // Try FINDSET "No." OR "Description" OR additional field by mask "@*Search string ?*"
        RecFilterContains := '''@*' + RecWithoutQuote + '*''';
        RecRef.FilterGroup := -1;
        SearchFieldRef[1].SetFilter(RecFilterContains);
        SearchFieldRef[2].SetFilter(RecFilterContains);
        if SearchFieldNo[3] <> 0 then
            SearchFieldRef[3].SetFilter(RecFilterContains);
        OnBeforeFindRecordContainingSearchString(Type, RecRef, RecFilterContains);
        GetRecordsSearchResult(RecRef, SearchFieldRef[1].Number, Result, RecordsCount);

        if RecordsCount > 0 then
            exit(RecordsCount);

        // Try FINDLAST record with similar "Description"
        IsHandled := false;
        OnFindRecordByDescriptionAndViewOnBeforeFindRecordWithSimilarName(RecRef, SearchText, SearchFieldNo, IsHandled);
        if not IsHandled then begin
            RecRef.SetLoadFields(SearchFieldRef[1].Number);
            if FindRecordWithSimilarName(RecRef, SearchText, SearchFieldNo[2]) then begin
                Result := SearchFieldRef[1].Value();
                exit(1);
            end;
        end;

        // Try find for extension
        MatchCount := 0;
        OnAfterFindRecordByDescriptionAndView(Result, Type, RecRef, SearchFieldRef, SearchFieldNo, SearchText, MatchCount);
        if MatchCount <> 0 then
            exit(MatchCount);

        // Not found
        exit(0);
    end;

    local procedure GetRecordsSearchResult(var RecRef: RecordRef; SearchFieldOneId: Integer; var Result: Text; var RecordsCount: Integer)
    begin
        RecRef.SetLoadFields(SearchFieldOneId);
        if not RecRef.IsEmpty() then
            UpdateResultFilter(Result, RecordsCount, RecRef, SearchFieldOneId);
    end;

    local procedure UpdateResultFilter(var Result: Text; var RecordsCount: Integer; var RecRef: RecordRef; SelectionFieldID: Integer)
    var
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
        FieldRef: FieldRef;
        TextBuilder: TextBuilder;
    begin
        Result := DelChr(Result, '<>', '|');
        if RecRef.FindSet() then
            repeat
                FieldRef := RecRef.Field(SelectionFieldID);
                TextBuilder.Append('|' + SelectionFilterManagement.AddQuotes(Format(FieldRef.Value)));
                RecordsCount += 1;
            until ((RecRef.Next() = 0) or (RecordsCount > GetMaxRecordCountToReturn()));

        if RecordsCount = 1 then begin //to avoid adding single quotes
            Result := Format(FieldRef.Value);
            exit;
        end;

        Result += TextBuilder.ToText();
        Result := DelChr(Result, '<>', '|');
    end;

    internal procedure GetMaxRecordCountToReturn() Result: Integer
    begin
        Result := 30;
        OnGetMaxRecordCountToReturnOnBeforeExit(Result);
        exit(Result);
    end;

    procedure FindRecordWithSimilarName(RecRef: RecordRef; SearchText: Text; DescriptionFieldNo: Integer): Boolean
    var
        TypeHelper: Codeunit "Type Helper";
        Description: Text;
        RecCount: Integer;
        TextLength: Integer;
        Treshold: Integer;
    begin
        if SearchText = '' then
            exit(false);

        TextLength := StrLen(SearchText);
        if TextLength > RecRef.Field(DescriptionFieldNo).Length then
            exit(false);

        Treshold := TextLength div 5;
        if Treshold = 0 then
            exit(false);

        RecRef.Reset();
        RecRef."SecurityFiltering" := SECURITYFILTER::Filtered;
        RecRef.Ascending(false); // most likely to search for newest records
        RecRef.AddLoadFields(DescriptionFieldNo);
        if RecRef.FindSet() then
            repeat
                RecCount += 1;
                Description := RecRef.Field(DescriptionFieldNo).Value();
                if Abs(TextLength - StrLen(Description)) <= Treshold then
                    if TypeHelper.TextDistance(UpperCase(SearchText), UpperCase(Description)) <= Treshold then
                        exit(true);
            until (RecRef.Next() = 0) or (RecCount > 1000);

        exit(false);
    end;

    local procedure GetRecRefAndFieldsNoByType(RecRef: RecordRef; Type: Option " ","G/L Account",Item,Resource,"Fixed Asset","Charge (Item)",,,,,"Allocation Account"; var SearchFieldNo: array[4] of Integer)
    var
        GLAccount: Record "G/L Account";
        Item: Record Item;
        FixedAsset: Record "Fixed Asset";
        Resource: Record Resource;
        ItemCharge: Record "Item Charge";
        StandardText: Record "Standard Text";
        AllocationAccount: Record "Allocation Account";
    begin
        OnBeforeGetRecRefAndFieldsNoByType(RecRef, Type, SearchFieldNo);
        case Type of
            Type::"G/L Account":
                begin
                    RecRef.Open(DATABASE::"G/L Account");
                    SearchFieldNo[1] := GLAccount.FieldNo("No.");
                    SearchFieldNo[2] := GLAccount.FieldNo(Name);
                    SearchFieldNo[3] := 0;
                end;
            Type::Item:
                begin
                    RecRef.Open(DATABASE::Item);
                    SearchFieldNo[1] := Item.FieldNo("No.");
                    SearchFieldNo[2] := Item.FieldNo(Description);
                    SearchFieldNo[3] := Item.FieldNo("Base Unit of Measure");
                end;
            Type::Resource:
                begin
                    RecRef.Open(DATABASE::Resource);
                    SearchFieldNo[1] := Resource.FieldNo("No.");
                    SearchFieldNo[2] := Resource.FieldNo(Name);
                    SearchFieldNo[3] := 0;
                end;
            Type::"Fixed Asset":
                begin
                    RecRef.Open(DATABASE::"Fixed Asset");
                    SearchFieldNo[1] := FixedAsset.FieldNo("No.");
                    SearchFieldNo[2] := FixedAsset.FieldNo(Description);
                    SearchFieldNo[3] := 0;
                end;
            Type::"Charge (Item)":
                begin
                    RecRef.Open(DATABASE::"Item Charge");
                    SearchFieldNo[1] := ItemCharge.FieldNo("No.");
                    SearchFieldNo[2] := ItemCharge.FieldNo(Description);
                    SearchFieldNo[3] := 0;
                end;
            Type::" ":
                begin
                    RecRef.Open(DATABASE::"Standard Text");
                    SearchFieldNo[1] := StandardText.FieldNo(Code);
                    SearchFieldNo[2] := StandardText.FieldNo(Description);
                    SearchFieldNo[3] := 0;
                end;
            Type::"Allocation Account":
                begin
                    RecRef.Open(DATABASE::"Allocation Account");
                    SearchFieldNo[1] := AllocationAccount.FieldNo("No.");
                    SearchFieldNo[2] := AllocationAccount.FieldNo(Name);
                    SearchFieldNo[3] := 0;
                end;
        end;
        OnAfterGetRecRefAndFieldsNoByType(RecRef, Type, SearchFieldNo);
    end;

    local procedure GetGLAccountTableRelationView(): Text
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.SetRange("Direct Posting", true);
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.SetRange(Blocked, false);
        exit(GLAccount.GetView(false));
    end;

    [TryFunction]
    local procedure TrySetFilterOnFieldRef(var FieldRef: FieldRef; "Filter": Text)
    begin
        FieldRef.SetFilter(Filter);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindRecordByDescriptionAndView(var Result: Text; Type: Option " ","G/L Account",Item,Resource,"Fixed Asset","Charge (Item)",,,,,"Allocation Account"; var RecRef: RecordRef; SearchFieldRef: array[4] of FieldRef; SearchFieldNo: array[4] of Integer; SearchText: Text; var MatchCount: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecRefAndFieldsNoByType(RecRef: RecordRef; Type: Option " ","G/L Account",Item,Resource,"Fixed Asset","Charge (Item)",,,,,"Allocation Account"; var SearchFieldNo: array[4] of Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindLastEntryIgnoringSecurityFilter(var RecRef: RecordRef; var Found: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindNoFromTypedValue(var Type: Option; var Value: Code[20]; var FoundNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindRecordByDescriptionAndView(var Result: Text; Type: Option " ","G/L Account",Item,Resource,"Fixed Asset","Charge (Item)",,,,,"Allocation Account"; var RecRef: RecordRef; SearchFieldRef: array[4] of FieldRef; SearchText: Text; RecordView: Text; var MatchCount: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindRecordContainingSearchString(Type: Option " ","G/L Account",Item,Resource,"Fixed Asset","Charge (Item)",,,,,"Allocation Account"; var RecRef: RecordRef; RecFilterFromStart: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindRecordStartingWithSearchString(Type: Option " ","G/L Account",Item,Resource,"Fixed Asset","Charge (Item)",,,,,"Allocation Account"; var RecRef: RecordRef; RecFilterFromStart: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetRecRefAndFieldsNoByType(RecRef: RecordRef; Type: Option " ","G/L Account",Item,Resource,"Fixed Asset","Charge (Item)",,,,,"Allocation Account"; var SearchFieldNo: array[4] of Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetMaxRecordCountToReturnOnBeforeExit(var Result: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindRecordByDescriptionAndViewOnBeforeFindRecordWithSimilarName(RecRef: RecordRef; var SearchText: Text; var SearchFieldNo: array[4] of Integer; var IsHandled: Boolean)
    begin
    end;
}

