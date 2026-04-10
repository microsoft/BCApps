// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.Source;

using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;

codeunit 7011 "Price Source List"
{
    var
        TempPriceSource: Record "Price Source" temporary;
        PriceType: Enum "Price Type";
        CurrentLevel: Integer;
        InconsistentPriceTypeErr: Label 'The source added to the list must have the Price Type equal to %1',
            Comment = '%1 - price type value';

    procedure Init()
    begin
        CurrentLevel := 0;
        PriceType := PriceType::Any;
        TempPriceSource.Reset();
        TempPriceSource.DeleteAll();
    end;

    procedure GetMinMaxLevel(var Level: array[2] of Integer)
    var
        TempPriceSourceLocal: Record "Price Source" temporary;
    begin
        TempPriceSourceLocal.Copy(TempPriceSource, true);
        TempPriceSourceLocal.Reset();
        if TempPriceSourceLocal.IsEmpty() then begin
            Level[2] := Level[1] - 1;
            exit;
        end;

        TempPriceSourceLocal.SetCurrentKey(Level);
        TempPriceSourceLocal.FindFirst();
        Level[1] := TempPriceSourceLocal.Level;
        TempPriceSourceLocal.FindLast();
        Level[2] := TempPriceSourceLocal.Level;
    end;

    procedure GetPriceType(): Enum "Price Type";
    begin
        exit(PriceType);
    end;

    local procedure ValidatePriceType(NewPriceType: Enum "Price Type")
    begin
        if PriceType = PriceType::Any then
            PriceType := NewPriceType
        else
            if (PriceType <> NewPriceType) and (NewPriceType <> NewPriceType::Any) then
                Error(InconsistentPriceTypeErr, PriceType);
    end;

    procedure SetPriceType(NewPriceType: Enum "Price Type")
    begin
        ValidatePriceType(NewPriceType);
    end;

    procedure IncLevel()
    begin
        CurrentLevel += 1;
    end;

    procedure SetLevel(Level: Integer)
    begin
        CurrentLevel := Level;
    end;

    procedure Add(SourceType: Enum "Price Source Type"; SourceNo: Code[20])
    begin
        if SourceNo = '' then
            exit;
        TempPriceSource.NewEntry(SourceType, CurrentLevel);
        TempPriceSource.Validate("Source No.", SourceNo);
        OnAddOnBeforeInsert(TempPriceSource);
        ValidatePriceType(TempPriceSource."Price Type");
        TempPriceSource.Insert(true);
    end;

    procedure Add(SourceType: Enum "Price Source Type"; ParentSourceNo: Code[20]; SourceNo: Code[20])
    begin
        if SourceNo = '' then
            exit;
        TempPriceSource.NewEntry(SourceType, CurrentLevel);
        TempPriceSource.Validate("Parent Source No.", ParentSourceNo);
        TempPriceSource.Validate("Source No.", SourceNo);
        OnAddOnBeforeInsert(TempPriceSource);
        ValidatePriceType(TempPriceSource."Price Type");
        TempPriceSource.Insert(true);
    end;

    procedure Add(SourceType: Enum "Price Source Type"; SourceId: Guid)
    begin
        if IsNullGuid(SourceId) then
            exit;
        TempPriceSource.NewEntry(SourceType, CurrentLevel);
        TempPriceSource.Validate("Source ID", SourceId);
        OnAddOnBeforeInsert(TempPriceSource);
        ValidatePriceType(TempPriceSource."Price Type");
        TempPriceSource.Insert(true);
    end;

    procedure Add(SourceType: Enum "Price Source Type")
    begin
        TempPriceSource.NewEntry(SourceType, CurrentLevel);
        ValidatePriceType(TempPriceSource."Price Type");
        TempPriceSource.Insert(true);
    end;

    procedure Add(PriceSource: Record "Price Source")
    begin
        PriceSource.Level := CurrentLevel;
        TempPriceSource.TransferFields(PriceSource);
        ValidatePriceType(TempPriceSource."Price Type");
        TempPriceSource.Insert(true);
    end;

    procedure AddChildren(PriceSource: Record "Price Source")
    var
        TempChildPriceSource: Record "Price Source" temporary;
    begin
        OnBeforeAddChildren(PriceSource, TempChildPriceSource);
        if TempChildPriceSource.FindSet() then
            repeat
                Add(TempChildPriceSource);
            until TempChildPriceSource.Next() = 0;
    end;

    procedure AddJobAsSources(JobNo: Code[20]; JobTaskNo: Code[20])
    begin
        if JobNo <> '' then begin
            IncLevel();
            Add("Price Source Type"::"All Jobs");
            IncLevel();
            Add("Price Source Type"::Job, JobNo);
            if JobTaskNo <> '' then begin
                IncLevel();
                Add("Price Source Type"::"Job Task", JobNo, JobTaskNo);
            end;
        end;
    end;

    procedure GetValue(SourceType: Enum "Price Source Type") Result: Code[20];
    var
        TempPriceSourceLocal: Record "Price Source" temporary;
        PriceSourceInterface: Interface "Price Source";
    begin
        TempPriceSourceLocal.Copy(TempPriceSource, true);
        TempPriceSourceLocal.Reset();
        TempPriceSourceLocal.SetRange("Source Type", SourceType);
        if TempPriceSourceLocal.FindFirst() then begin
            PriceSourceInterface := TempPriceSourceLocal."Source Type";
            Result := TempPriceSourceLocal."Source No.";
        end;
        OnAfterGetValue(SourceType, Result);
    end;

    procedure Copy(var FromPriceSourceList: Codeunit "Price Source List")
    begin
        Init();
        FromPriceSourceList.GetList(TempPriceSource);
    end;

    procedure GetList(var ToTempPriceSource: Record "Price Source" temporary) Found: Boolean
    begin
        if ToTempPriceSource.IsTemporary then
            ToTempPriceSource.Copy(TempPriceSource, true);
        Found := ToTempPriceSource.FindSet();
        UpdatePriceTypeSourceGroup(ToTempPriceSource)
    end;

    local procedure UpdatePriceTypeSourceGroup(var PriceSource: Record "Price Source")
    begin
        if PriceSource."Price Type" = PriceSource."Price Type"::Any then
            PriceSource."Price Type" := PriceType;
        if PriceSource."Source Group" = PriceSource."Source Group"::All then
            case PriceType of
                PriceType::Sale:
                    PriceSource."Source Group" := PriceSource."Source Group"::Customer;
                PriceType::Purchase:
                    PriceSource."Source Group" := PriceSource."Source Group"::Vendor;
            end;
    end;

    procedure First(var PriceSource: Record "Price Source"; AtLevel: Integer): Boolean;
    begin
        TempPriceSource.Reset();
        TempPriceSource.SetCurrentKey(Level);
        TempPriceSource.SetRange(Level, AtLevel);
        exit(GetRecordIfFound(TempPriceSource.FindSet(), PriceSource))
    end;

    procedure Next(var PriceSource: Record "Price Source"): Boolean;
    begin
        exit(GetRecordIfFound(TempPriceSource.Next() > 0, PriceSource))
    end;

    local procedure GetRecordIfFound(Found: Boolean; var PriceSource: Record "Price Source"): Boolean
    begin
        if Found then begin
            PriceSource := TempPriceSource;
            CurrentLevel := TempPriceSource.Level;
        end else
            Clear(PriceSource);
        exit(Found)
    end;

    procedure GetSourceGroup(var DtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup"): Boolean;
    var
        PriceSource: Record "Price Source";
    begin
        if GetSourceGroup(PriceSource) then begin
            DtldPriceCalculationSetup."Source Group" := PriceSource."Source Group";
            DtldPriceCalculationSetup."Source Type" := PriceSource."Source Type";
            DtldPriceCalculationSetup."Source No." := PriceSource.GetGroupNo();
            exit(true);
        end;
    end;

    local procedure GetSourceGroup(var FoundPriceSource: Record "Price Source"): Boolean;
    var
        TempPriceSourceLocal: Record "Price Source" temporary;
    begin
        TempPriceSourceLocal.Copy(TempPriceSource, true);
        TempPriceSourceLocal.Reset();
        TempPriceSourceLocal.SetCurrentKey(Level);
        TempPriceSourceLocal.SetAscending(Level, false);
        TempPriceSourceLocal.SetFilter("Source Group", '<>%1', TempPriceSourceLocal."Source Group"::All);
        if TempPriceSourceLocal.IsEmpty() then
            exit(false);
        TempPriceSourceLocal.SetFilter("Source No.", '<>%1', '');
        if TempPriceSourceLocal.FindFirst() then begin
            FoundPriceSource := TempPriceSourceLocal;
            exit(true);
        end;
        TempPriceSourceLocal.SetRange("Source No.");
        if TempPriceSourceLocal.FindFirst() then begin
            FoundPriceSource := TempPriceSourceLocal;
            exit(true);
        end;
    end;

    procedure Remove(SourceType: Enum "Price Source Type"): Boolean;
    var
        PriceSource: Record "Price Source";
    begin
        PriceSource.SetRange("Source Type", SourceType);
        exit(Remove(PriceSource));
    end;

    procedure RemoveAtLevel(SourceType: Enum "Price Source Type"; Level: Integer): Boolean;
    var
        PriceSource: Record "Price Source";
    begin
        PriceSource.SetRange(Level, Level);
        PriceSource.SetRange("Source Type", SourceType);
        exit(Remove(PriceSource));
    end;

    local procedure Remove(var PriceSource: Record "Price Source"): Boolean
    var
        TempPriceSourceLocal: Record "Price Source" temporary;
    begin
        TempPriceSourceLocal.Copy(TempPriceSource, true);
        TempPriceSourceLocal.CopyFilters(PriceSource);
        if not TempPriceSourceLocal.IsEmpty() then begin
            TempPriceSourceLocal.DeleteAll();
            exit(true);
        end;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAddOnBeforeInsert(var PriceSource: Record "Price Source")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterGetValue(SourceType: Enum "Price Source Type"; var Result: Code[20])
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeAddChildren(PriceSource: Record "Price Source"; var TempChildPriceSource: Record "Price Source" temporary)
    begin
    end;
}