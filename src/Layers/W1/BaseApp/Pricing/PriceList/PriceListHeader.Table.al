// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.PriceList;

using Microsoft.CRM.Campaign;
using Microsoft.CRM.Contact;
using Microsoft.Finance.Currency;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.Source;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Setup;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Pricing;
using Microsoft.Sales.Setup;
using System.Utilities;
using System.Telemetry;

table 7000 "Price List Header"
{
    Caption = 'Price List';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Code; Code[20])
        {
            Caption = 'Code';
            DataClassification = CustomerContent;
            trigger OnValidate()
            var
                NoSeries: Codeunit "No. Series";
            begin
                if Code <> xRec.Code then begin
                    if xRec.Code <> '' then
                        Error(CanotRenameErr, Rec.TableCaption());
                    NoSeries.TestManual(GetNoSeries());
                    "No. Series" := '';
                end;
            end;
        }
        field(2; Description; Text[250])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestStatusDraft();
            end;
        }
        field(3; "Source Group"; Enum "Price Source Group")
        {
            DataClassification = CustomerContent;
            Caption = 'Assign-to Group';
        }
        field(4; "Source Type"; Enum "Price Source Type")
        {
            DataClassification = CustomerContent;
            Caption = 'Assign-to Type';
            trigger OnValidate()
            begin
                if xRec."Source Type" = "Source Type" then
                    exit;

                CheckIfLinesExist(FieldCaption("Source Type"));
                xRec.CopyTo(PriceSource);
                PriceSource.Validate("Source Type", "Source Type");
                CopyFrom(PriceSource);
                "Amount Type" := PriceSource.GetDefaultAmountType();
            end;
        }
        field(5; "Source No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Assign-to No. (custom)';
            trigger OnValidate()
            begin
                if xRec."Source No." = "Source No." then
                    exit;

                CheckIfLinesExist(FieldCaption("Source No."));
                if not PriceSourceLookedUp then begin
                    xRec.CopyTo(PriceSource);
                    PriceSource.Validate("Source No.", "Source No.");
                end;
                CopyFrom(PriceSource);
                "Assign-to No." := "Source No.";
            end;

            trigger OnLookup()
            begin
                PriceCalculationMgt.FeatureCustomizedLookupUsage(Database::"Price List Header");
                LookupSourceNo();
            end;
        }
        field(6; "Parent Source No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Assign-to Parent No. (projects)';
            trigger OnValidate()
            begin
                if xRec."Parent Source No." = "Parent Source No." then
                    exit;

                TestStatusDraft();
                xRec.CopyTo(PriceSource);
                PriceSource.Validate("Parent Source No.", "Parent Source No.");
                CopyFrom(PriceSource);
                "Assign-to Parent No." := "Parent Source No.";
            end;
        }
        field(7; "Source ID"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Assign-to ID';
            trigger OnValidate()
            begin
                if xRec."Source ID" = "Source ID" then
                    exit;

                TestStatusDraft();
                xRec.CopyTo(PriceSource);
                PriceSource.Validate("Source ID", "Source ID");
                CopyFrom(PriceSource);
            end;
        }
        field(8; "Price Type"; Enum "Price Type")
        {
            DataClassification = CustomerContent;
            Caption = 'Price Type';
        }
        field(9; "Amount Type"; Enum "Price Amount Type")
        {
            DataClassification = CustomerContent;
            Caption = 'Defines';

            trigger OnValidate()
            begin
                if not "Allow Updating Defaults" then begin
                    CopyTo(PriceSource);
                    PriceSource.VerifyAmountTypeForSourceType("Amount Type");
                end else
                    VerifyAmountTypeForCustPriceAndDiscountGroup();
            end;
        }
        field(10; "Currency Code"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'Currency Code';
            TableRelation = Currency;

            trigger OnValidate()
            begin
                if "Currency Code" <> xRec."Currency Code" then
                    CheckIfLinesExist(FieldCaption("Currency Code"));
            end;
        }
        field(11; "Starting Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Starting Date';
            trigger OnValidate()
            begin
                if "Starting Date" = xRec."Starting Date" then
                    exit;

                TestStatusDraft();
                xRec.CopyTo(PriceSource);
                PriceSource.Validate("Starting Date", "Starting Date");
                CopyFrom(PriceSource);

                UpdateDatesInLines(Rec.FieldNo("Starting Date"), Rec.FieldCaption("Starting Date"));
            end;
        }
        field(12; "Ending Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Ending Date';
            trigger OnValidate()
            begin
                if "Ending Date" = xRec."Ending Date" then
                    exit;

                TestStatusDraft();
                xRec.CopyTo(PriceSource);
                PriceSource.Validate("Ending Date", "Ending Date");
                CopyFrom(PriceSource);

                UpdateDatesInLines(Rec.FieldNo("Ending Date"), Rec.FieldCaption("Ending Date"));
            end;
        }
        field(13; "Price Includes VAT"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Price Includes VAT';

            trigger OnValidate()
            begin
                if "Price Includes VAT" <> xRec."Price Includes VAT" then
                    CheckIfLinesExist(FieldCaption("Price Includes VAT"));
            end;
        }
        field(14; "VAT Bus. Posting Gr. (Price)"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'VAT Bus. Posting Gr. (Price)';
            TableRelation = "VAT Business Posting Group";

            trigger OnValidate()
            begin
                if "VAT Bus. Posting Gr. (Price)" <> xRec."VAT Bus. Posting Gr. (Price)" then
                    CheckIfLinesExist(FieldCaption("VAT Bus. Posting Gr. (Price)"));
            end;
        }
        field(15; "Allow Line Disc."; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Allow Line Disc.';
            InitValue = true;

            trigger OnValidate()
            begin
                TestStatusDraft();
            end;
        }
        field(16; "Allow Invoice Disc."; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Allow Invoice Disc.';
            InitValue = true;

            trigger OnValidate()
            begin
                TestStatusDraft();
            end;
        }
        field(17; "No. Series"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(18; Status; Enum "Price Status")
        {
            Caption = 'Status';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                FeatureTelemetry: Codeunit "Feature Telemetry";
            begin
                if Status <> xRec.Status then begin
                    if Status = Status::Active then
                        FeatureTelemetry.LogUptake('0000LLR', PriceCalculationMgt.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Used");

                    if not UpdateStatus() then
                        Status := xRec.Status;

                    if Status = Status::Active then
                        FeatureTelemetry.LogUsage('0000LLR', PriceCalculationMgt.GetFeatureTelemetryName(), 'Price List activated');
                end;
            end;
        }
        field(19; "Filter Source No."; Code[20])
        {
            Caption = 'Filter Source No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(20; "Allow Updating Defaults"; Boolean)
        {
            Caption = 'Allow Updating Defaults';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                if xRec."Allow Updating Defaults" and not Rec."Allow Updating Defaults" then
                    CheckIfLinesExist(Rec.FieldCaption("Allow Updating Defaults"));
            end;
        }
        field(21; "Assign-to No."; Code[20])
        {
            Caption = 'Assign-to No.';
            DataClassification = CustomerContent;
            TableRelation = if ("Source Type" = const(Campaign)) Campaign
            else
            if ("Source Type" = const(Contact)) Contact
            else
            if ("Source Type" = const(Customer)) Customer
            else
            if ("Source Type" = const("Customer Disc. Group")) "Customer Discount Group"
            else
            if ("Source Type" = const("Customer Price Group")) "Customer Price Group"
            else
            if ("Source Type" = const(Job)) Job
            else
            if ("Source Type" = const("Job Task")) "Job Task"."Job Task No." where("Job No." = field("Parent Source No."), "Job Task Type" = const(Posting))
            else
            if ("Source Type" = const(Vendor)) Vendor;
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                Validate("Source No.", "Assign-to No.");
            end;
        }
        field(22; "Assign-to Parent No."; Code[20])
        {
            Caption = 'Assign-to Parent No.';
            DataClassification = CustomerContent;
            TableRelation = if ("Source Type" = const("Job Task")) Job;
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                Validate("Parent Source No.", "Assign-to Parent No.");
            end;
        }
    }

    keys
    {
        key(PK; Code)
        {
        }
        key(Key1; "Source Type", "Source No.", "Starting Date", "Currency Code")
        {
        }
        key(Key2; Status, "Price Type", "Source Group", "Source Type", "Source No.", "Currency Code", "Starting Date", "Ending Date")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Description)
        {
        }
    }

    trigger OnInsert()
    var
        NoSeries: Codeunit "No. Series";
    begin
        if "Source Group" = "Source Group"::All then
            TestField(Code);
        if Code = '' then begin
            "No. Series" := GetNoSeries();
            if NoSeries.AreRelated("No. Series", xRec."No. Series") then
                "No. Series" := xRec."No. Series";
            Code := NoSeries.GetNextNo("No. Series");
        end;
        if "Amount Type" = "Amount Type"::Any then begin
            CopyTo(PriceSource);
            "Amount Type" := PriceSource.GetDefaultAmountType();
        end;
    end;

    trigger OnDelete()
    var
        PriceListLine: Record "Price List Line";
    begin
        if (Status = Status::Active) and not IsEditable() then
            Error(CannotDeleteActivePriceListErr, Code);

        PriceListLine.SetRange("Price List Code", Code);
        PriceListLine.DeleteAll();
    end;

    trigger OnRename()
    begin
        Error(CanotRenameErr, Rec.TableCaption());
    end;

    var
        PriceSource: Record "Price Source";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        ConfirmUpdateQst: Label 'Do you want to update %1 in the price list lines?', Comment = '%1 - the field caption';
        LinesExistErr: Label 'You cannot change %1 because one or more lines exist.', Comment = '%1 - the field caption';
        StatusUpdateQst: Label 'Do you want to update status to %1?', Comment = '%1 - status value: Draft, Active, or Inactive';
        CannotDeleteActivePriceListErr: Label 'You cannot delete the active price list %1.', Comment = '%1 - the price list code.';
        CanotRenameErr: Label 'You cannot rename a %1.', Comment = '%1 - the table name';
        PriceSourceLookedUp: Boolean;

    procedure IsEditable() Result: Boolean;
    begin
        case Status of
            Status::Draft:
                exit(true);
            Status::Active:
                exit(IsAllowedEditingActivePrice());
            else
                exit(false);
        end;
    end;

    local procedure IsAllowedEditingActivePrice(): Boolean;
    var
        PriceListManagement: Codeunit "Price List Management";
    begin
        exit(PriceListManagement.IsAllowedEditingActivePrice("Price Type"));
    end;

    procedure IsCRMIntegrationAllowed(StatusActiveFilterApplied: Boolean; AllowUpdatingDefaultsFilterApplied: Boolean): Boolean;
    begin
        exit(
            ((StatusActiveFilterApplied and (Rec.Status = Rec.Status::Active)) or not StatusActiveFilterApplied) and
            ((AllowUpdatingDefaultsFilterApplied and Rec."Allow Updating Defaults") or (not AllowUpdatingDefaultsFilterApplied and not Rec."Allow Updating Defaults")));
    end;

    procedure AssistEditCode(xPriceListHeader: Record "Price List Header"): Boolean
    var
        PriceListHeader: Record "Price List Header";
        NoSeries: Codeunit "No. Series";
    begin
        if "Source Group" = "Source Group"::All then
            exit(false);

        PriceListHeader := Rec;
        if NoSeries.LookupRelatedNoSeries(GetNoSeries(), xPriceListHeader."No. Series", PriceListHeader."No. Series") then begin
            PriceListHeader.Code := NoSeries.GetNextNo(PriceListHeader."No. Series");
            Rec := PriceListHeader;
            exit(true);
        end;
    end;

    procedure BlankDefaults()
    begin
        if Rec."Allow Updating Defaults" then begin
            Rec."Source Type" := Rec."Source Type"::All;
            SetSourceNo('', '');
            Rec."Currency Code" := '';
            Rec."Starting Date" := 0D;
            Rec."Ending Date" := 0D;
        end;
        OnAfterBlankDefaults(Rec);
    end;

    local procedure GetNoSeries() Result: Code[20];
    var
        JobsSetup: Record "Jobs Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        case "Source Group" of
            "Source Group"::Customer:
                begin
                    SalesReceivablesSetup.Get();
                    SalesReceivablesSetup.TestField("Price List Nos.");
                    Result := SalesReceivablesSetup."Price List Nos.";
                end;
            "Source Group"::Vendor:
                begin
                    PurchasesPayablesSetup.Get();
                    PurchasesPayablesSetup.TestField("Price List Nos.");
                    Result := PurchasesPayablesSetup."Price List Nos.";
                end;
            "Source Group"::Job:
                begin
                    JobsSetup.Get();
                    JobsSetup.TestField("Price List Nos.");
                    Result := JobsSetup."Price List Nos.";
                end;
        end;

        OnAfterGetNoSeries(Rec, Result);
    end;

    procedure CheckIfLinesExist(Caption: Text)
    var
        PriceListLine: Record "Price List Line";
        ErrorMsg: Text;
    begin
        if IsTemporary() or (Code = '') then
            exit;
        TestStatusDraft();
        if "Allow Updating Defaults" then
            exit;
        PriceListLine.SetRange("Price List Code", Code);
        if not PriceListLine.IsEmpty() then begin
            ErrorMsg := StrSubstNo(LinesExistErr, Caption);
            Error(ErrorMsg);
        end;
    end;

    procedure CopyFrom(PriceSource: Record "Price Source")
    begin
        "Price Type" := PriceSource."Price Type";
        "Source Group" := PriceSource."Source Group";
        if "Source Group" = "Source Group"::All then
            case "Price Type" of
                "Price Type"::Sale:
                    "Source Group" := "Source Group"::Customer;
                "Price Type"::Purchase:
                    "Source Group" := "Source Group"::Vendor;
            end;
        "Source Type" := PriceSource."Source Type";
        SetSourceNo(PriceSource."Parent Source No.", PriceSource."Source No.");
        "Source ID" := PriceSource."Source ID";
        "Filter Source No." := PriceSource."Filter Source No.";

        "Currency Code" := PriceSource."Currency Code";
        "Starting Date" := PriceSource."Starting Date";
        "Ending Date" := PriceSource."Ending Date";
        "Price Includes VAT" := PriceSource."Price Includes VAT";
        "Allow Invoice Disc." := PriceSource."Allow Invoice Disc.";
        "Allow Line Disc." := PriceSource."Allow Line Disc.";
        "VAT Bus. Posting Gr. (Price)" := PriceSource."VAT Bus. Posting Gr. (Price)";

        OnAfterCopyFromPriceSource(PriceSource);
    end;

    procedure CopyTo(var PriceSource: Record "Price Source")
    begin
        PriceSource."Source Group" := "Source Group";
        PriceSource."Source Type" := "Source Type";
        PriceSource."Source No." := "Source No.";
        PriceSource."Parent Source No." := "Parent Source No.";
        PriceSource."Source ID" := "Source ID";
        PriceSource."Filter Source No." := "Filter Source No.";

        PriceSource."Price Type" := "Price Type";
        PriceSource."Currency Code" := "Currency Code";
        PriceSource."Starting Date" := "Starting Date";
        PriceSource."Ending Date" := "Ending Date";
        PriceSource."Price Includes VAT" := "Price Includes VAT";
        PriceSource."Allow Invoice Disc." := "Allow Invoice Disc.";
        PriceSource."Allow Line Disc." := "Allow Line Disc.";
        PriceSource."VAT Bus. Posting Gr. (Price)" := "VAT Bus. Posting Gr. (Price)";

        OnAfterCopyToPriceSource(PriceSource);
    end;

    procedure IsSourceNoAllowed(): Boolean;
    var
        PriceSourceInterface: Interface "Price Source";
    begin
        PriceSourceInterface := "Source Type";
        exit(PriceSourceInterface.IsSourceNoAllowed());
    end;

    procedure UpdateAmountType()
    var
        xAmountType: Enum "Price Amount Type";
    begin
        CopyTo(PriceSource);
        xAmountType := "Amount Type";
        if "Amount Type" = "Amount Type"::Any then begin
            if "Source Type" in ["Source Type"::"Customer Disc. Group", "Source Type"::"Customer Price Group"] then
                "Amount Type" := PriceSource.GetDefaultAmountType()
            else
                "Amount Type" := CalcAmountType();
            if "Amount Type" <> xAmountType then
                Modify()
        end;
    end;

    local procedure CalcAmountType(): Enum "Price Amount Type";
    var
        PriceListLine: Record "Price List Line";
    begin
        PriceListLine.SetRange("Price List Code", Code);
        if PriceListLine.IsEmpty() then
            exit("Amount Type"::Any);

        PriceListLine.SetRange("Amount Type", "Amount Type"::Any);
        if not PriceListLine.IsEmpty() then
            exit("Amount Type"::Any);

        PriceListLine.SetRange("Amount Type", "Amount Type"::Price);
        if PriceListLine.IsEmpty() then
            exit("Amount Type"::Discount);

        PriceListLine.SetRange("Amount Type", "Amount Type"::Discount);
        if PriceListLine.IsEmpty() then
            exit("Amount Type"::Price);

        exit("Amount Type"::Any);
    end;

    local procedure UpdateDatesInLines(FieldId: Integer; Caption: Text)
    var
        PriceListLine: Record "Price List Line";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if IsTemporary() then
            exit;
        PriceListLine.SetRange("Price List Code", Code);
        if PriceListLine.IsEmpty() then
            exit;

        if "Allow Updating Defaults" then
            if not ConfirmManagement.GetResponse(StrSubstNo(ConfirmUpdateQst, Caption), true) then
                exit;

        case FieldId of
            Rec.FieldNo("Starting Date"):
                begin
                    PriceListLine.SetFilter("Starting Date", '<>%1', Rec."Starting Date");
                    SetStatusToDraft(PriceListLine);
                    PriceListLine.ModifyAll("Starting Date", Rec."Starting Date");
                    PriceListLine.SetRange("Starting Date", Rec."Starting Date");
                    PriceListLine.SetFilter("Ending Date", '<%1', Rec."Starting Date");
                    PriceListLine.ModifyAll("Ending Date", Rec."Ending Date");
                end;
            Rec.FieldNo("Ending Date"):
                begin
                    PriceListLine.SetFilter("Ending Date", '<>%1', Rec."Ending Date");
                    SetStatusToDraft(PriceListLine);
                    OnUpdateDatesInLinesOnBeforePriceListLineModifyAllEndingDate(PriceListLine, Rec);
                    PriceListLine.ModifyAll("Ending Date", Rec."Ending Date");
                    PriceListLine.SetRange("Ending Date", Rec."Ending Date");
                    PriceListLine.SetFilter("Starting Date", '>%1', Rec."Ending Date");
                    PriceListLine.ModifyAll("Starting Date", Rec."Starting Date");
                end;
        end;
    end;

    local procedure SetSourceNo(ParentSourceNo: Code[20]; SourceNo: Code[20])
    begin
        "Parent Source No." := ParentSourceNo;
        "Source No." := SourceNo;

        "Assign-to Parent No." := ParentSourceNo;
        "Assign-to No." := SourceNo;
    end;

    local procedure SetStatusToDraft(var PriceListLine: Record "Price List Line")
    begin
        PriceListLine.SetFilter(Status, '<>%1', "Price Status"::Draft);
        PriceListLine.ModifyAll(Status, "Price Status"::Draft);
        PriceListLine.SetRange(Status);
    end;

    procedure SyncDropDownLookupFields()
    begin
        "Assign-to Parent No." := "Parent Source No.";
        "Assign-to No." := "Source No.";
    end;

    procedure TestStatusDraft()
    begin
        if not IsEditable() then
            TestField(Status, Status::Draft);
    end;

    procedure HasDraftLines(): Boolean;
    var
        PriceListLine: Record "Price List Line";
    begin
        exit(HasDraftLines(PriceListLine));
    end;

    procedure HasDraftLines(var PriceListLine: Record "Price List Line") Result: Boolean;
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeHasDraftLines(PriceListLine, Result, IsHandled, Rec);
        if IsHandled then
            exit(Result);

        if (Status <> Status::Active) or not IsEditable() then
            exit(false);
        PriceListLine.SetRange("Price List Code", Code);
        PriceListLine.SetRange(Status, Status::Draft);
        PriceListLine.SetRange(SystemModifiedBy, UserSecurityId());
        exit(not PriceListLine.IsEmpty());
    end;

    procedure LookupSourceNo() Result: Boolean;
    begin
        PriceSourceLookedUp := false;
        CopyTo(PriceSource);
        if PriceSource.LookupNo() then begin
            PriceSourceLookedUp := true;
            Validate("Source No.", PriceSource."Source No.");
            PriceSourceLookedUp := false;
            Result := true;
        end;
    end;

    local procedure UpdateStatus() Updated: Boolean;
    var
        PriceListLine: Record "Price List Line";
        ConfirmManagement: Codeunit "Confirm Management";
        PriceListManagement: Codeunit "Price List Management";
        IsHandled, Confirmed : Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateStatus(Rec, Updated, IsHandled);
        if IsHandled then
            exit(Updated);

        if Status = Status::Active then
            VerifySource();

        Updated := true;
        PriceListLine.SetRange("Price List Code", Code);
        if PriceListLine.IsEmpty() then
            exit;

        if Status = Status::Active then begin
            PriceListManagement.VerifyLines(PriceListLine);
            if not PriceListManagement.ResolveDuplicatePrices(Rec) then
                exit(false);
        end;

        IsHandled := false;
        OnUpdateStatusOnBeforeConfirmStatus(Rec, Updated, Confirmed, IsHandled);
        if not IsHandled then
            Confirmed := ConfirmManagement.GetResponseOrDefault(StrSubstNo(StatusUpdateQst, Status), true);

        if Confirmed then
            PriceListLine.ModifyAll(Status, Status)
        else
            Updated := false
    end;

    local procedure VerifyParentSource() Result: Boolean;
    var
        PriceSourceLocal: Record "Price Source";
        PriceSourceInterface: Interface "Price Source";
    begin
        CopyTo(PriceSourceLocal);
        PriceSourceInterface := "Source Type";
        Result := PriceSourceInterface.VerifyParent(PriceSourceLocal);
    end;

    local procedure VerifySource()
    begin
        if VerifyParentSource() then
            TestField("Parent Source No.")
        else
            TestField("Parent Source No.", '');

        if IsSourceNoAllowed() then
            TestField("Source No.")
        else
            TestField("Source No.", '');
    end;

    local procedure VerifyAmountTypeForCustPriceAndDiscountGroup()
    begin
        if not ("Source Type" in ["Source Type"::"Customer Price Group", "Source Type"::"Customer Disc. Group"]) then
            exit;

        CopyTo(PriceSource);
        PriceSource.VerifyAmountTypeForSourceType("Amount Type");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterBlankDefaults(var PriceListHeader: Record "Price List Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCopyFromPriceSource(PriceSource: Record "Price Source")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCopyToPriceSource(var PriceSource: Record "Price Source")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetNoSeries(var PriceListHeader: Record "Price List Header"; var Result: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHasDraftLines(var PriceListLine: Record "Price List Line"; var Result: Boolean; var IsHandled: Boolean; var PriceListHeader: Record "Price List Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateStatus(var PriceListHeader: Record "Price List Header"; var Updated: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateStatusOnBeforeConfirmStatus(PriceListHeader: Record "Price List Header"; Updated: Boolean; var Confirmed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateDatesInLinesOnBeforePriceListLineModifyAllEndingDate(var PriceListLine: Record "Price List Line"; var PriceListHeader: Record "Price List Header")
    begin
    end;
}