// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.Source;

using Microsoft.Finance.Currency;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Pricing.PriceList;

table 7005 "Price Source"
{
#pragma warning disable AS0034
    TableType = Temporary;
#pragma warning restore AS0034
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Source Type"; Enum "Price Source Type")
        {
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                SetGroup();
                InitSource();
            end;
        }
        field(2; "Source ID"; Guid)
        {
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                if IsNullGuid("Source ID") then
                    InitSource()
                else begin
                    PriceSourceInterface := "Source Type";
                    PriceSourceInterface.GetNo(Rec);
                    SetFilterSourceNo();
                end;
            end;
        }
        field(3; "Source No."; Code[20])
        {
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                if "Source No." = '' then
                    InitSource()
                else begin
                    PriceSourceInterface := "Source Type";
                    PriceSourceInterface.GetId(Rec);
                    SetFilterSourceNo();
                end;
            end;
        }
        field(4; "Parent Source No."; Code[20])
        {
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                IsParentSourceAllowed();
                "Source No." := '';
                Clear("Source ID");
                "Filter Source No." := "Parent Source No.";
            end;
        }
        field(5; "Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(6; Level; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(7; "Source Group"; Enum "Price Source Group")
        {
            DataClassification = SystemMetadata;
        }
        field(8; "Price Type"; Enum "Price Type")
        {
            DataClassification = SystemMetadata;
        }
        field(10; "Currency Code"; Code[10])
        {
            DataClassification = SystemMetadata;
            TableRelation = Currency;
        }
        field(12; "Starting Date"; Date)
        {
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                VerifyDates();
            end;
        }
        field(13; "Ending Date"; Date)
        {
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                VerifyDates();
            end;
        }
        field(19; "Filter Source No."; Code[20])
        {
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(21; "Allow Line Disc."; Boolean)
        {
            DataClassification = SystemMetadata;
        }
        field(22; "Allow Invoice Disc."; Boolean)
        {
            DataClassification = SystemMetadata;
        }
        field(23; "Price Includes VAT"; Boolean)
        {
            DataClassification = SystemMetadata;
        }
        field(24; "VAT Bus. Posting Gr. (Price)"; Code[20])
        {
            DataClassification = SystemMetadata;
            TableRelation = "VAT Business Posting Group";
        }
        field(25; Description; Text[100])
        {
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
        }
        key(Level; Level)
        {
        }
    }

    var
        AmountTypeNotAllowedForSourceTypeErr: Label '%1 is not allowed for %2.', Comment = '%1 - Price or Discount, %2 - the source type';
        StartingDateErr: Label 'Starting Date %1 cannot be after Ending Date %2.', Comment = '%1 and %2 - dates';
        CampaignDateErr: Label 'If Source Type is Campaign, then you can only change Starting Date and Ending Date from the Campaign Card.';

    protected var
        PriceSourceInterface: Interface "Price Source";

    trigger OnInsert()
    begin
        "Entry No." := GetLastEntryNo() + 1;
    end;

    procedure NewEntry(SourceType: Enum "Price Source Type"; NewLevel: Integer)
    begin
        Init();
        Level := NewLevel;
        Validate("Source Type", SourceType);
    end;

    procedure GetDefaultAmountType() AmountType: Enum "Price Amount Type";
    var
        AmountTypeInt: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetDefaultAmountType(Rec, AmountType, IsHandled);
        if IsHandled then
            exit;

        foreach AmountTypeInt in AmountType.Ordinals() do begin
            AmountType := "Price Amount Type".FromInteger(AmountTypeInt);
            if IsForAmountType(AmountType) then
                exit(GetAmountType());
        end;
    end;

    local procedure GetLastEntryNo(): Integer;
    var
        TempPriceSource: Record "Price Source" temporary;
    begin
        TempPriceSource.Copy(Rec, true);
        TempPriceSource.Reset();
        if TempPriceSource.FindLast() then
            exit(TempPriceSource."Entry No.");
    end;

    procedure InitSource()
    begin
        Clear("Source ID");
        "Parent Source No." := '';
        "Source No." := '';
        Description := '';
        "Filter Source No." := '';
        "Currency Code" := '';
        GetPriceType();

        OnAfterInitSource(Rec);
    end;

    local procedure GetPriceType()
    begin
        case "Source Group" of
            "Source Group"::Customer:
                "Price Type" := "Price Type"::Sale;
            "Source Group"::Vendor:
                "Price Type" := "Price Type"::Purchase;
        end;
    end;

    local procedure GetSourceGroup()
    begin
        case "Price Type" of
            "Price Type"::Purchase:
                "Source Group" := "Source Group"::Vendor;
            "Price Type"::Sale:
                "Source Group" := "Source Group"::Customer;
        end;
    end;

    local procedure SetGroup()
    var
        SourceGroupInterface: Interface "Price Source Group";
    begin
        SourceGroupInterface := "Source Type";
        "Source Group" := SourceGroupInterface.GetGroup();
        if "Source Group" = "Source Group"::All then
            GetSourceGroup();
    end;

    procedure GetGroupNo(): Code[20]
    begin
        PriceSourceInterface := "Source Type";
        exit(PriceSourceInterface.GetGroupNo(Rec));
    end;

    procedure GetParentSourceType() ParentSourceType: Enum "Price Source Type";
    begin
        OnGetParentSourceType(Rec, ParentSourceType);
    end;

    procedure IsForAmountType(AmountType: Enum "Price Amount Type"): Boolean
    begin
        PriceSourceInterface := "Source Type";
        exit(PriceSourceInterface.IsForAmountType(AmountType))
    end;

    procedure IsParentSourceAllowed(): Boolean;
    begin
        PriceSourceInterface := "Source Type";
        exit(PriceSourceInterface.VerifyParent(Rec));
    end;

    procedure IsSourceNoAllowed(): Boolean;
    begin
        PriceSourceInterface := "Source Type";
        exit(PriceSourceInterface.IsSourceNoAllowed());
    end;

    procedure LookupNo() Result: Boolean;
    begin
        PriceSourceInterface := "Source Type";
        Result := PriceSourceInterface.IsLookupOK(Rec);
    end;

    procedure FilterPriceLines(var PriceListLine: Record "Price List Line") Result: Boolean;
    begin
        PriceListLine.SetRange("Source Type", "Source Type");
        if IsSourceNoAllowed() then begin
            if "Source No." = '' then
                exit;

            PriceListLine.SetRange("Source No.", "Source No.");
            if "Parent Source No." <> '' then
                PriceListLine.SetRange("Parent Source No.", "Parent Source No.");
        end else
            PriceListLine.SetRange("Source No.");

        OnAfterFilterPriceLines(Rec, PriceListLine);
    end;

    procedure VerifyAmountTypeForSourceType(AmountType: Enum "Price Amount Type")
    var
        ErrorMsg: Text;
        IsHandled: Boolean;
    begin
        OnBeforeVerifyAmountTypeForSourceType(Rec, AmountType, IsHandled);
        if IsHandled then
            exit;

        if not IsForAmountType(AmountType) then begin
            ErrorMsg := StrSubstNo(AmountTypeNotAllowedForSourceTypeErr, AmountType, "Source Type");
            Error(ErrorMsg);
        end;
    end;

    local procedure VerifyDates()
    begin
        PriceSourceInterfaceVerifyDate();
        if ("Ending Date" <> 0D) and ("Starting Date" <> 0D) and ("Ending Date" < "Starting Date") then
            Error(StartingDateErr, "Starting Date", "Ending Date");
    end;

    // Should be a method in Price Source Interface
    local procedure PriceSourceInterfaceVerifyDate()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePriceSourceInterfaceVerifyDate(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Source Type" = "Source Type"::Campaign then
            Error(CampaignDateErr);
    end;

    local procedure SetFilterSourceNo()
    begin
        if "Parent Source No." <> '' then
            "Filter Source No." := "Parent Source No."
        else
            "Filter Source No." := "Source No."
    end;

    local procedure GetAmountType() AmountType: Enum "Price Amount Type"
    begin
        if "Source Type" = "Source Type"::"Customer Disc. Group" then
            exit(AmountType::Discount);

        if "Source Type" = "Source Type"::"Customer Price Group" then
            exit(AmountType::Price);

        exit(AmountType::Any);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyAmountTypeForSourceType(PriceSource: Record "Price Source"; AmountType: Enum "Price Amount Type"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetParentSourceType(PriceSource: Record "Price Source"; var ParentSourceType: Enum "Price Source Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitSource(var PriceSource: Record "Price Source")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDefaultAmountType(PriceSource: Record "Price Source"; var AmountType: Enum "Price Amount Type"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePriceSourceInterfaceVerifyDate(PriceSource: Record "Price Source"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterPriceLines(PriceSource: Record "Price Source"; var PriceListLine: Record "Price List Line")
    begin
    end;
}