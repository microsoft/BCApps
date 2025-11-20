// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using System.Environment.Configuration;
using System.Security.AccessControl;

table 1670 "Option Lookup Buffer"
{
    Caption = 'Option Lookup Buffer';
    LookupPageID = "Option Lookup List";
    ReplicateData = false;
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; ID; Integer)
        {
            Caption = 'ID';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(2; "Option Caption"; Text[30])
        {
            Caption = 'Option Values';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(3; "Lookup Type"; Enum "Option Lookup Type")
        {
            Caption = 'Lookup Type';
            DataClassification = SystemMetadata;
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Option Caption")
        {
            Clustered = true;
        }
        key(Key2; ID)
        {
        }
    }

    fieldgroups
    {
    }

    var
        UnsupportedTypeErr: Label 'Unsupported Lookup Type.';
        InvalidTypeErr: Label '''%1'' is not a valid type for this document.', Comment = '%1 = Type caption. Fx. Item';
        CurrentType: Text[30];

    procedure FillLookupBuffer(LookupType: Enum "Option Lookup Type")
    var
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        Permission: Record Permission;
        TableNo: Integer;
        FieldNo: Integer;
        RelationFieldNo: Integer;
        IsHandled: Boolean;
    begin
        case LookupType of
            "Lookup Type"::Sales:
                FillBufferInternal(DATABASE::"Sales Line", SalesLine.FieldNo(Type), SalesLine.FieldNo("No."), LookupType);
            "Lookup Type"::Purchases:
                FillBufferInternal(DATABASE::"Purchase Line", PurchaseLine.FieldNo(Type), PurchaseLine.FieldNo("No."), LookupType);
            "Lookup Type"::Permissions:
                FillBufferInternal(DATABASE::Permission, Permission.FieldNo("Read Permission"), 0, LookupType);
            else begin
                IsHandled := false;
                OnFillBufferLookupTypeCase(LookupType, IsHandled, TableNo, FieldNo, RelationFieldNo);
                if not IsHandled then
                    Error(UnsupportedTypeErr);
                FillBufferInternal(TableNo, FieldNo, RelationFieldNo, LookupType);
            end;
        end;
    end;

    procedure AutoCompleteLookup(var OptionType: Text[30]; LookupType: Enum "Option Lookup Type"): Boolean
    var
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        Permission: Record Permission;
        IsHandled: Boolean;
    begin
        OptionType := DelChr(OptionType, '<>');
        if OptionType = '' then
            case LookupType of
                "Lookup Type"::Sales:
                    OptionType := SalesLine.FormatType();
                "Lookup Type"::Purchases:
                    OptionType := PurchaseLine.FormatType();
                "Lookup Type"::Permissions:
                    OptionType := Format(Permission."Read Permission");
                else begin
                    IsHandled := false;
                    OnAutoCOmpleteOptionLookupTypeCase(LookupType, OptionType, IsHandled);
                    if not IsHandled then
                        exit(false);
                end;
            end;

        SetRange("Option Caption");
        if IsEmpty() then
            FillLookupBuffer(LookupType);

        SetRange("Option Caption", OptionType);
        if FindFirst() then
            exit(true);

        SetFilter("Option Caption", '%1', '@' + OptionType + '*');
        if FindFirst() then begin
            OptionType := "Option Caption";
            exit(true);
        end;

        SetFilter("Option Caption", '%1', '@*' + OptionType + '*');
        if FindFirst() then begin
            OptionType := "Option Caption";
            exit(true);
        end;

        SetRange("Option Caption", CurrentType);
        if FindFirst() then begin
            OptionType := "Option Caption";
            exit(true);
        end;

        exit(false);
    end;

    procedure ValidateOption(Option: Text[30])
    begin
        SetRange("Option Caption", Option);
        if IsEmpty() then
            Error(InvalidTypeErr, Option);

        SetRange("Option Caption");
    end;

    procedure FormatOption(FieldRef: FieldRef) Result: Text[30]
    var
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        Option: Option;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFormatOption(FieldRef, Result, IsHandled);
        if IsHandled then
            exit;

        Option := FieldRef.Value();
        case FieldRef.Record().Number of
            DATABASE::"Sales Line", DATABASE::"Standard Sales Line":
                if Option = SalesLine.Type::" ".AsInteger() then
                    exit(SalesLine.FormatType());
            DATABASE::"Purchase Line", DATABASE::"Standard Purchase Line":
                if Option = PurchaseLine.Type::" ".AsInteger() then
                    exit(PurchaseLine.FormatType());
        end;

        exit(Format(FieldRef));
    end;

    local procedure CreateNew(OptionID: Integer; OptionText: Text[30]; LookupType: Enum "Option Lookup Type")
    begin
        Init();
        ID := OptionID;
        "Option Caption" := OptionText;
        "Lookup Type" := LookupType;
        OnCreateNewOnBeforeInsert(Rec, OptionID, OptionText, LookupType);
        Insert();
    end;

    local procedure FillBufferInternal(TableNo: Integer; FieldNo: Integer; RelationFieldNo: Integer; LookupType: Enum "Option Lookup Type")
    var
        RecRef: RecordRef;
        RelatedRecRef: RecordRef;
        FieldRef: FieldRef;
        FieldRefRelation: FieldRef;
        OptionIndex: Integer;
        RelatedTableNo: Integer;
    begin
        RecRef.Open(TableNo);
        FieldRef := RecRef.Field(FieldNo);
        for OptionIndex := 0 to (FieldRef.EnumValueCount() - 1) do begin
            FieldRef.Value(FieldRef.GetEnumValueOrdinal(OptionIndex + 1));
            if IncludeOption(LookupType, FieldRef.Value(), RecRef) then begin
                FieldRefRelation := RecRef.Field(RelationFieldNo);
                RelatedTableNo := FieldRefRelation.Relation();
                if RelatedTableNo = 0 then
                    CreateNew(FieldRef.Value(), FormatOption(FieldRef), LookupType)
                else begin
                    RelatedRecRef.Open(RelatedTableNo);
                    RelatedRecRef.SetPermissionFilter();
                    if RelatedRecRef.ReadPermission then
                        CreateNew(FieldRef.Value(), FormatOption(FieldRef), LookupType);
                    RelatedRecRef.Close();
                end;
            end;
        end;
    end;

    local procedure IncludeOption(LookupType: Enum "Option Lookup Type"; OptionType: Integer; RecRef: RecordRef): Boolean
    var
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        IsHandled: Boolean;
        Result: Boolean;
    begin
        Result := false;
        IsHandled := false;
        OnBeforeIncludeOption(Rec, LookupType.AsInteger(), OptionType, IsHandled, Result, RecRef);
        if IsHandled then
            exit(Result);

        case LookupType of
            "Lookup Type"::Sales:
                case OptionType of
                    SalesLine.Type::" ".AsInteger(), SalesLine.Type::"G/L Account".AsInteger(), SalesLine.Type::Item.AsInteger(), SalesLine.Type::"Allocation Account".AsInteger():
                        exit(true);
                    SalesLine.Type::"Charge (Item)".AsInteger():
                        if ApplicationAreaMgmtFacade.IsItemChargesEnabled() then
                            exit(true);
                    SalesLine.Type::"Fixed Asset".AsInteger():
                        if ApplicationAreaMgmtFacade.IsFixedAssetEnabled() then
                            exit(true);
                    SalesLine.Type::Resource.AsInteger():
                        if ApplicationAreaMgmtFacade.IsJobsEnabled() then
                            exit(true);
                end;
            "Lookup Type"::Purchases:
                case OptionType of
                    PurchaseLine.Type::" ".AsInteger(), PurchaseLine.Type::"G/L Account".AsInteger(), PurchaseLine.Type::Item.AsInteger(), PurchaseLine.Type::"Allocation Account".AsInteger():
                        exit(true);
                    PurchaseLine.Type::"Charge (Item)".AsInteger():
                        if ApplicationAreaMgmtFacade.IsItemChargesEnabled() then
                            exit(true);
                    PurchaseLine.Type::"Fixed Asset".AsInteger():
                        if ApplicationAreaMgmtFacade.IsFixedAssetEnabled() then
                            exit(true);
                    PurchaseLine.Type::Resource.AsInteger():
                        if ApplicationAreaMgmtFacade.IsJobsEnabled() then
                            exit(true);
                end;
            "Lookup Type"::Permissions:
                exit(true);
        end;
    end;

    procedure SetCurrentType(LineType: Option " ","G/L Account",Item,Resource,"Fixed Asset","Charge (Item)")
    begin
        CurrentType := Format(LineType::Item); // Default value
        if LineType = LineType::" " then
            exit;
        CurrentType := Format(LineType);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIncludeOption(OptionLookupBuffer: Record "Option Lookup Buffer"; LookupType: Option; Option: Integer; var Handled: Boolean; var Result: Boolean; RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFormatOption(FieldRef: FieldRef; var Result: Text[30]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateNewOnBeforeInsert(var OptionLookupBuffer: Record "Option Lookup Buffer"; OptionID: Integer; OptionText: Text[30]; LookupType: Enum "Option Lookup Type")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnFillBufferLookupTypeCase(LookupType: Enum "Option Lookup Type"; var IsHandled: Boolean; var TableNo: Integer; var FieldNo: Integer; var RelationFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAutoCompleteOptionLookupTypeCase(LookupType: Enum "Option Lookup Type"; var OptionType: Text[30]; var IsHandled: Boolean)
    begin
    end;
}

