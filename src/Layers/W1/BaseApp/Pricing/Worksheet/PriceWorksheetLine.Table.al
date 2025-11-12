// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.Worksheet;

using Microsoft.CRM.Campaign;
using Microsoft.CRM.Contact;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Source;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Pricing;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Pricing;
using Microsoft.Utilities;

table 7022 "Price Worksheet Line"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Price List Code"; Code[20])
        {
            Caption = 'Price List Code';
            DataClassification = CustomerContent;
            TableRelation = "Price List Header";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = CustomerContent;
            AutoIncrement = true;
        }
        field(3; "Source Type"; Enum "Price Source Type")
        {
            Caption = 'Assign-to Type';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestHeadersValue(FieldNo("Source Type"));
                CopyRecTo(PriceSource);
                PriceSource.Validate("Source Type", "Source Type");
                CopyFrom(PriceSource);
                "Amount Type" := PriceSource.GetDefaultAmountType();
                if "Asset No." <> '' then begin
                    CopyTo(PriceAsset);
                    PriceAsset.ValidateAssetNo();
                    CopyFrom(PriceAsset);
                end;
            end;
        }
        field(4; "Source No."; Code[20])
        {
            Caption = 'Assign-to No.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestHeadersValue(FieldNo("Source No."));
                if not FieldLookedUp then begin
                    CopyRecTo(PriceSource);
                    PriceSource.Validate("Source No.", "Source No.");
                end;
                CopyFrom(PriceSource);
                "Assign-to No." := "Source No.";
            end;

            trigger OnLookup()
            begin
                CopyTo(PriceSource);
                if PriceSource.LookupNo() then begin
                    FieldLookedUp := true;
                    Validate("Source No.", PriceSource."Source No.");
                    FieldLookedUp := false;
                end;
            end;
        }
        field(5; "Parent Source No."; Code[20])
        {
            Caption = 'Assign-to Parent No.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestHeadersValue(FieldNo("Parent Source No."));
                CopyRecTo(PriceSource);
                PriceSource.Validate("Parent Source No.", "Parent Source No.");
                CopyFrom(PriceSource);
                "Assign-to Parent No." := "Parent Source No.";
            end;

            trigger OnLookup()
            var
                ParentPriceSource: Record "Price Source";
            begin
                CopyRecTo(PriceSource);
                if not PriceSource.IsParentSourceAllowed() then
                    exit;

                ParentPriceSource."Source Group" := "Source Group";
                ParentPriceSource."Source Type" := PriceSource.GetParentSourceType();
                if ParentPriceSource.LookupNo() then
                    Validate("Parent Source No.", ParentPriceSource."Source No.");
            end;
        }
        field(6; "Source ID"; Guid)
        {
            Caption = 'Assign-to ID';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestHeadersValue(FieldNo("Source ID"));
                CopyRecTo(PriceSource);
                PriceSource.Validate("Source ID", "Source ID");
                CopyFrom(PriceSource);
            end;
        }
        field(7; "Asset Type"; Enum "Price Asset Type")
        {
            Caption = 'Product Type';
            DataClassification = CustomerContent;
            InitValue = Item;

            trigger OnValidate()
            begin
                if "Asset Type" = "Asset Type"::" " then
                    "Asset Type" := "Asset Type"::Item;

                CopyRecTo(PriceAsset);
                PriceAsset.Validate("Asset Type", "Asset Type");
                CopyFrom(PriceAsset);

                InitHeaderDefaults();
                TestStatusDraft();
            end;
        }
        field(8; "Asset No."; Code[20])
        {
            Caption = 'Product No.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestStatusDraft();
                if not FieldLookedUp then begin
                    CopyRecTo(PriceAsset);
                    PriceAsset.Validate("Asset No.", "Asset No.");
                end;
                CopyFrom(PriceAsset);
                "Product No." := "Asset No.";
                "Variant Code Lookup" := "Variant Code";
                "Unit of Measure Code Lookup" := "Unit of Measure Code";
            end;

            trigger OnLookup()
            begin
                CopyTo(PriceAsset);
                if PriceAsset.LookupNo() then begin
                    FieldLookedUp := true;
                    Validate("Asset No.", PriceAsset."Asset No.");
                    FieldLookedUp := false;
                end;
            end;
        }
        field(9; "Variant Code"; Code[10])
        {
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestStatusDraft();
                if not FieldLookedUp then begin
                    CopyRecTo(PriceAsset);
                    PriceAsset.Validate("Variant Code", "Variant Code");
                end;
                CopyFrom(PriceAsset);
                "Variant Code Lookup" := "Variant Code";
            end;

            trigger OnLookup()
            begin
                CopyTo(PriceAsset);
                if PriceAsset.LookupVariantCode() then begin
                    FieldLookedUp := true;
                    Validate("Variant Code", PriceAsset."Variant Code");
                    FieldLookedUp := false;
                end;
            end;
        }
        field(10; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = CustomerContent;
            TableRelation = Currency;

            trigger OnValidate()
            begin
                if "Currency Code" = xRec."Currency Code" then
                    exit;
                TestHeadersValue(FieldNo("Currency Code"));
            end;
        }
        field(11; "Work Type Code"; Code[10])
        {
            Caption = 'Work Type Code';
            DataClassification = CustomerContent;
            TableRelation = "Work Type";

            trigger OnValidate()
            begin
                TestStatusDraft();
                CopyRecTo(PriceAsset);
                PriceAsset.Validate("Work Type Code", "Work Type Code");
                CopyFrom(PriceAsset);
            end;
        }
        field(12; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestHeadersValue(FieldNo("Starting Date"));
                CopyRecTo(PriceSource);
                PriceSource.Validate("Starting Date", "Starting Date");
                CopyFrom(PriceSource);
            end;
        }
        field(13; "Ending Date"; Date)
        {
            Caption = 'Ending Date';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestHeadersValue(FieldNo("Ending Date"));
                CopyRecTo(PriceSource);
                PriceSource.Validate("Ending Date", "Ending Date");
                CopyFrom(PriceSource);
            end;
        }
        field(14; "Minimum Quantity"; Decimal)
        {
            Caption = 'Minimum Quantity';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                TestStatusDraft();
            end;
        }
        field(15; "Unit of Measure Code"; Code[10])
        {
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestStatusDraft();
                if not FieldLookedUp then begin
                    CopyRecTo(PriceAsset);
                    PriceAsset.Validate("Unit of Measure Code", "Unit of Measure Code");
                end;
                CopyFrom(PriceAsset);
                "Unit of Measure Code Lookup" := "Unit of Measure Code";
            end;

            trigger OnLookup()
            begin
                CopyTo(PriceAsset);
                if PriceAsset.LookupUnitofMeasure() then begin
                    FieldLookedUp := true;
                    Validate("Unit of Measure Code", PriceAsset."Unit of Measure Code");
                    FieldLookedUp := false;
                end;
            end;
        }
        field(16; "Amount Type"; Enum "Price Amount Type")
        {
            Caption = 'Defines';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Amount Type" = xRec."Amount Type" then
                    exit;

                TestStatusDraft();
                VerifyAmountTypeForSourceType("Amount Type");
                if PriceAsset."Amount Type" <> "Price Amount Type"::Any then
                    TestField("Amount Type", PriceAsset."Amount Type");

                case "Amount Type" of
                    "Amount Type"::Price:
                        begin
                            "Line Discount %" := 0;
                            GetValueFromHeader(FieldNo("Allow Invoice Disc."));
                            GetValueFromHeader(FieldNo("Allow Line Disc."));
                        end;
                    "Amount Type"::Discount:
                        begin
                            "Unit Price" := 0;
                            "Cost Factor" := 0;
                            "Allow Invoice Disc." := false;
                            "Allow Line Disc." := false;
                        end;
                end;
            end;
        }
        field(17; "Unit Price"; Decimal)
        {
            AccessByPermission = tabledata "Sales Price Access" = R;
            DataClassification = CustomerContent;
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            Caption = 'Unit Price';
            MinValue = 0;

            trigger OnValidate()
            begin
                TestStatusDraft();
                CheckAmountType(FieldCaption("Unit Price"), "Amount Type"::Discount);
                Verify();
                if "Unit Price" <> 0 then
                    "Cost Factor" := 0;
            end;
        }
        field(18; "Cost Factor"; Decimal)
        {
            AccessByPermission = tabledata "Sales Price Access" = R;
            DataClassification = CustomerContent;
            Caption = 'Cost Factor';

            trigger OnValidate()
            begin
                TestStatusDraft();
                CheckAmountType(FieldCaption("Cost Factor"), "Amount Type"::Discount);
                TestField("Source Group", "Source Group"::Job);
                Verify();
                if "Cost Factor" <> 0 then
                    "Unit Price" := 0;
            end;
        }
        field(19; "Unit Cost"; Decimal)
        {
            AccessByPermission = tabledata "Purchase Price Access" = R;
            DataClassification = CustomerContent;
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            Caption = 'Unit Cost';
            MinValue = 0;

            trigger OnValidate()
            begin
                TestStatusDraft();
                CheckAmountType(FieldCaption("Unit Cost"), "Amount Type"::Discount);
                Verify();
            end;
        }
        field(20; "Line Discount %"; Decimal)
        {
            DataClassification = CustomerContent;
            AutoFormatType = 2;
            Caption = 'Line Discount %';
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                TestStatusDraft();
                CheckAmountType(FieldCaption("Line Discount %"), "Amount Type"::Price);
                Verify();
            end;
        }
        field(21; "Allow Line Disc."; Boolean)
        {
            Caption = 'Allow Line Disc.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestStatusDraft();
                CheckAmountType(FieldCaption("Allow Line Disc."), "Amount Type"::Discount);
            end;
        }
        field(22; "Allow Invoice Disc."; Boolean)
        {
            Caption = 'Allow Invoice Disc.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestStatusDraft();
                CheckAmountType(FieldCaption("Allow Invoice Disc."), "Amount Type"::Discount);
            end;
        }
        field(23; "Price Includes VAT"; Boolean)
        {
            Caption = 'Price Includes VAT';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestHeadersValue(FieldNo("Price Includes VAT"));
            end;
        }
        field(24; "VAT Bus. Posting Gr. (Price)"; Code[20])
        {
            Caption = 'VAT Bus. Posting Gr. (Price)';
            DataClassification = CustomerContent;
            TableRelation = "VAT Business Posting Group";

            trigger OnValidate()
            begin
                TestHeadersValue(FieldNo("VAT Bus. Posting Gr. (Price)"));
            end;
        }
        field(25; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            DataClassification = CustomerContent;
            TableRelation = "VAT Product Posting Group";

            trigger OnValidate()
            begin
                TestStatusDraft();
            end;
        }
        field(26; "Asset ID"; Guid)
        {
            Caption = 'Asset ID';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestStatusDraft();
                CopyRecTo(PriceAsset);
                PriceAsset.Validate("Asset ID", "Asset ID");
                CopyFrom(PriceAsset);
            end;
        }
        field(27; "Line Amount"; Decimal)
        {
            DataClassification = CustomerContent;
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            Caption = 'Line Amount';
            MinValue = 0;
            Editable = false;
        }
        field(28; "Price Type"; Enum "Price Type")
        {
            Caption = 'Price Type';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestHeadersValue(FieldNo("Price Type"));
            end;
        }
        field(29; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestStatusDraft();
            end;
        }
        field(30; Status; Enum "Price Status")
        {
            Caption = 'Status';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestHeadersValue(FieldNo(Status));
            end;
        }
        field(31; "Direct Unit Cost"; Decimal)
        {
            AccessByPermission = tabledata "Purchase Price Access" = R;
            DataClassification = CustomerContent;
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            Caption = 'Direct Unit Cost';
            MinValue = 0;

            trigger OnValidate()
            begin
                TestStatusDraft();
                CheckAmountType(FieldCaption("Direct Unit Cost"), "Amount Type"::Discount);
                Verify();
            end;
        }
        field(32; "Source Group"; Enum "Price Source Group")
        {
            Caption = 'Source Group';
            DataClassification = CustomerContent;
        }
        field(33; "Product No."; Code[20])
        {
            Caption = 'Product No.';
            DataClassification = CustomerContent;
            TableRelation = if ("Asset Type" = const(Item)) Item where("No." = field("Product No."))
            else
            if ("Asset Type" = const("G/L Account")) "G/L Account"
            else
            if ("Asset Type" = const(Resource)) Resource
            else
            if ("Asset Type" = const("Resource Group")) "Resource Group"
            else
            if ("Asset Type" = const("Item Discount Group")) "Item Discount Group";
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                Validate("Asset No.", "Product No.");
            end;
        }
        field(34; "Assign-to No."; Code[20])
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
        field(35; "Assign-to Parent No."; Code[20])
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
        field(36; "Variant Code Lookup"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = if ("Asset Type" = const(Item)) "Item Variant".Code where("Item No." = field("Asset No."));
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                Validate("Variant Code", "Variant Code Lookup");
            end;
        }
        field(37; "Unit of Measure Code Lookup"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = if ("Asset Type" = const(Item)) "Item Unit of Measure".Code where("Item No." = field("Asset No."))
            else
            if ("Asset Type" = const(Resource)) "Resource Unit of Measure".Code where("Resource No." = field("Asset No."))
            else
            if ("Asset Type" = const("Resource Group")) "Unit of Measure";
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                Validate("Unit of Measure Code", "Unit of Measure Code Lookup");
            end;
        }
        field(100; "Existing Line"; Boolean)
        {
            Caption = 'Existing Line';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                if not "Existing Line" then begin
                    "Price List Code" := '';
                    Status := Status::Draft;
                    "Line No." := 0;
                end;
            end;
        }
        field(101; "Existing Unit Price"; Decimal)
        {
            AccessByPermission = tabledata "Sales Price Access" = R;
            DataClassification = CustomerContent;
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            Caption = 'Existing Unit Price';
            Editable = false;
            BlankZero = true;
        }
        field(102; "Existing Direct Unit Cost"; Decimal)
        {
            AccessByPermission = tabledata "Purchase Price Access" = R;
            DataClassification = CustomerContent;
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            Caption = 'Existing Direct Unit Cost';
            Editable = false;
            BlankZero = true;
        }
        field(103; "Existing Unit Cost"; Decimal)
        {
            AccessByPermission = tabledata "Purchase Price Access" = R;
            DataClassification = CustomerContent;
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            Caption = 'Existing Unit Cost';
            Editable = false;
            BlankZero = true;
        }
    }

    keys
    {
        key(PK; "Price List Code", "Existing Line", "Line No.")
        {
            Clustered = true;
        }
        key(Key1; "Price Type", "Source Group")
        {
        }
    }

    trigger OnInsert()
    var
        PriceListManagement: Codeunit "Price List Management";
    begin
        if "Price List Code" = '' then
            "Price List Code" := PriceListManagement.GetDefaultPriceListCode("Price Type", "Source Group", false);
    end;

    protected var
        PriceListHeader: Record "Price List Header";
        PriceAsset: Record "Price Asset";
        PriceSource: Record "Price Source";

    var
        IsNewRecord: Boolean;
        FieldLookedUp: Boolean;
        FieldNotAllowedForAmountTypeErr: Label 'Field %1 is not allowed in the price list line where %2 is %3.',
            Comment = '%1 - the field caption; %2 - Amount Type field caption; %3 - amount type value: Discount or Price';
        LineSourceTypeErr: Label 'cannot be set to %1 if the header''s source type is %2.', Comment = '%1 and %2 - the source type value.';

    procedure IsAssetItem(): Boolean;
    begin
        exit("Asset Type" = "Asset Type"::Item);
    end;

    procedure IsAssetResource(): Boolean;
    begin
        exit("Asset Type" in ["Asset Type"::Resource, "Asset Type"::"Resource Group"]);
    end;

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

    procedure IsHeaderActive() Result: Boolean;
    begin
        GetHeader();
        exit(PriceListHeader.Status = "Price Status"::Active);
    end;

    procedure IsLineToVerify() Result: Boolean;
    begin
        Result := (Status = Status::Draft) and IsHeaderActive();
    end;

    local procedure IsAllowedEditingActivePrice(): Boolean;
    var
        PriceListManagement: Codeunit "Price List Management";
    begin
        exit(PriceListManagement.IsAllowedEditingActivePrice("Price Type"));
    end;

    procedure IsUOMSupported() Result: Boolean;
    begin
        Result := IsAssetItem() or IsAssetResource();

        OnAfterIsUOMSupported(Rec, Result);
    end;

    procedure IsAmountMandatory(AmountType: enum "Price Amount Type"): Boolean;
    begin
        case "Amount Type" of
            "Amount Type"::Any:
                exit(true)
            else
                exit(AmountType = "Amount Type");
        end;
    end;

    procedure IsAmountSupported(): Boolean;
    begin
        exit("Asset Type" <> "Asset Type"::"Item Discount Group");
    end;

    procedure IsRealLine(): Boolean;
    begin
        exit("Line No." <> 0);
    end;

    procedure IsSourceNoAllowed(): Boolean;
    var
        PriceSourceInterface: Interface "Price Source";
    begin
        PriceSourceInterface := "Source Type";
        exit(PriceSourceInterface.IsSourceNoAllowed());
    end;

    local procedure CheckAmountType(FldCaption: Text; AmountType: Enum "Price Amount Type")
    begin
        if "Amount Type" = AmountType then
            Error(FieldNotAllowedForAmountTypeErr, FldCaption, FieldCaption("Amount Type"), Format("Amount Type"));
    end;

    procedure CopyExistingPrices(PriceListLine: Record "Price List Line")
    begin
        "Existing Unit Price" := PriceListLine."Unit Price";
        "Existing Direct Unit Cost" := PriceListLine."Direct Unit Cost";
        "Existing Unit Cost" := PriceListLine."Unit Cost";
        OnAfterCopyExistingPrices(Rec, PriceListLine);
    end;

    procedure CopySourceFrom(PriceListHeader: Record "Price List Header")
    begin
        "Source Group" := PriceListHeader."Source Group";
        "Source Type" := PriceListHeader."Source Type";
        SetSourceNo(PriceListHeader."Parent Source No.", PriceListHeader."Source No.");
        "Source ID" := PriceListHeader."Source ID";
        OnAfterCopySourceFrom(Rec, PriceListHeader);
    end;

    procedure CopyFrom(PriceListHeader: Record "Price List Header")
    begin
        "Price Type" := PriceListHeader."Price Type";
        Status := "Price Status"::Draft;
        if not PriceListHeader."Allow Updating Defaults" then begin
            CopySourceFrom(PriceListHeader);
            "Starting Date" := PriceListHeader."Starting Date";
            "Ending Date" := PriceListHeader."Ending Date";
            "Currency Code" := PriceListHeader."Currency Code";
        end;
        if PriceListHeader."Amount Type" <> "Price Amount Type"::Any then
            Validate("Amount Type", PriceListHeader."Amount Type");

        "Price Includes VAT" := PriceListHeader."Price Includes VAT";
        "VAT Bus. Posting Gr. (Price)" := PriceListHeader."VAT Bus. Posting Gr. (Price)";
        "Allow Invoice Disc." := PriceListHeader."Allow Invoice Disc.";
        "Allow Line Disc." := PriceListHeader."Allow Line Disc.";
        OnAfterCopyFromPriceListHeader(PriceListHeader);
    end;

    local procedure CopyFrom(PriceSource: Record "Price Source")
    begin
        "Price Type" := PriceSource."Price Type";
        "Source Group" := PriceSource."Source Group";
        "Source Type" := PriceSource."Source Type";
        SetSourceNo(PriceSource."Parent Source No.", PriceSource."Source No.");
        "Source ID" := PriceSource."Source ID";

        if not GetHeader() or PriceListHeader."Allow Updating Defaults" then begin
            "Currency Code" := PriceSource."Currency Code";
            "Price Includes VAT" := PriceSource."Price Includes VAT";
            "Allow Invoice Disc." := PriceSource."Allow Invoice Disc.";
            "Allow Line Disc." := PriceSource."Allow Line Disc.";
            "VAT Bus. Posting Gr. (Price)" := PriceSource."VAT Bus. Posting Gr. (Price)";
            "Starting Date" := PriceSource."Starting Date";
            "Ending Date" := PriceSource."Ending Date";
        end;
        OnAfterCopyFromPriceSource(PriceSource);
    end;

    procedure CopyFrom(PriceAsset: Record "Price Asset")
    begin
        if PriceAsset."Amount Type" <> PriceAsset."Amount Type"::Any then
            "Amount Type" := PriceAsset."Amount Type";
        "Price Type" := PriceAsset."Price Type";
        "Asset Type" := PriceAsset."Asset Type";
        SetAssetNo(PriceAsset."Asset No.");
        "Asset ID" := PriceAsset."Asset ID";
        Description := PriceAsset.Description;
        "Unit of Measure Code" := PriceAsset."Unit of Measure Code";
        "Variant Code" := PriceAsset."Variant Code";
        "Work Type Code" := PriceAsset."Work Type Code";

        if not GetHeader() or PriceListHeader."Allow Updating Defaults" then
            if "VAT Bus. Posting Gr. (Price)" = '' then begin
                "Price Includes VAT" := PriceAsset."Price Includes VAT";
                "VAT Bus. Posting Gr. (Price)" := PriceAsset."VAT Bus. Posting Gr. (Price)";
            end;

        if (PriceListHeader.Code = '') or (IsNullGuid(PriceListHeader.SystemId)) or (not PriceListHeader."Allow Invoice Disc.") then
            "Allow Invoice Disc." := PriceAsset."Allow Invoice Disc.";

        OnAfterCopyFromPriceAsset(PriceAsset, Rec);
    end;

    procedure SetNewRecord(NewRecord: Boolean)
    begin
        IsNewRecord := NewRecord;
    end;

    local procedure CopyRecTo(var PriceAsset: Record "Price Asset")
    begin
        if IsNewRecord then
            CopyTo(PriceAsset)
        else
            xRec.CopyTo(PriceAsset);
    end;

    local procedure CopyRecTo(var PriceSource: Record "Price Source")
    begin
        if IsNewRecord then
            CopyTo(PriceSource)
        else
            xRec.CopyTo(PriceSource);
    end;

    procedure CopyTo(var PriceAsset: Record "Price Asset")
    begin
        PriceAsset."Price Type" := "Price Type";
        PriceAsset."Asset Type" := "Asset Type";
        PriceAsset."Asset No." := "Asset No.";
        PriceAsset.Description := Description;
        PriceAsset."Asset ID" := "Asset ID";
        PriceAsset."Unit of Measure Code" := "Unit of Measure Code";
        PriceAsset."Variant Code" := "Variant Code";
        PriceAsset."Work Type Code" := "Work Type Code";

        PriceAsset."Allow Invoice Disc." := "Allow Invoice Disc.";
        PriceAsset."Price Includes VAT" := "Price Includes VAT";
        PriceAsset."VAT Bus. Posting Gr. (Price)" := "VAT Bus. Posting Gr. (Price)";
        OnAfterCopyToPriceAsset(PriceAsset);
    end;

    procedure CopyTo(var PriceSource: Record "Price Source")
    begin
        PriceSource."Price Type" := "Price Type";
        PriceSource."Source Group" := "Source Group";
        PriceSource.Validate("Source Type", "Source Type");
        PriceSource."Parent Source No." := "Parent Source No.";
        PriceSource."Source No." := "Source No.";
        PriceSource."Source ID" := "Source ID";

        PriceSource."Currency Code" := "Currency Code";
        PriceSource."Price Includes VAT" := "Price Includes VAT";
        PriceSource."Allow Invoice Disc." := "Allow Invoice Disc.";
        PriceSource."Allow Line Disc." := "Allow Line Disc.";
        PriceSource."VAT Bus. Posting Gr. (Price)" := "VAT Bus. Posting Gr. (Price)";
        PriceSource."Starting Date" := "Starting Date";
        PriceSource."Ending Date" := "Ending Date";
        OnAfterCopyToPriceSource(PriceSource);
    end;

    local procedure GetHeader(): Boolean;
    begin
        if "Price List Code" <> '' then begin
            if PriceListHeader.Code <> "Price List Code" then
                exit(PriceListHeader.Get("Price List Code"));
            exit(true);
        end;

        Clear(PriceListHeader);
    end;

    local procedure GetValueFromHeader(FieldId: Integer)
    begin
        if not GetHeader() then
            exit;
        case FieldId of
            FieldNo("Allow Invoice Disc."):
                "Allow Invoice Disc." := PriceListHeader."Allow Invoice Disc.";
            FieldNo("Allow Line Disc."):
                "Allow Line Disc." := PriceListHeader."Allow Line Disc.";
        end;
    end;

    local procedure InitHeaderDefaults()
    begin
        if GetHeader() then
            CopyFrom(PriceListHeader);

        OnAfterInitHeaderDefaults(PriceListHeader);
    end;

    local procedure IsSourceTypeSupported(): Boolean;
    var
        PriceSourceGroup: Interface "Price Source Group";
    begin
        PriceSourceGroup := PriceListHeader."Source Group";
        exit(PriceSourceGroup.IsSourceTypeSupported("Source Type"));
    end;

    local procedure SetAssetNo(AssetNo: Code[20])
    begin
        "Asset No." := AssetNo;
        "Product No." := AssetNo;
    end;

    local procedure SetSourceNo(ParentSourceNo: Code[20]; SourceNo: Code[20])
    begin
        "Parent Source No." := ParentSourceNo;
        "Source No." := SourceNo;

        "Assign-to Parent No." := ParentSourceNo;
        "Assign-to No." := SourceNo;
    end;

    procedure SyncDropDownLookupFields()
    begin
        "Assign-to Parent No." := "Parent Source No.";
        "Assign-to No." := "Source No.";
        "Product No." := "Asset No.";
        "Unit of Measure Code Lookup" := "Unit of Measure Code";
        "Variant Code Lookup" := "Variant Code";
    end;

    local procedure TestHeadersValue(FieldId: Integer)
    var
        LineSourceTypeError: Text;
    begin
        if not GetHeader() then
            exit;

        TestStatusDraft();
        case FieldId of
            FieldNo("Source Group"):
                TestField("Source Group", PriceListHeader."Source Group");
            FieldNo(Status):
                TestField(Status, PriceListHeader.Status);
        end;
        if not PriceListHeader."Allow Updating Defaults" then
            case FieldId of
                FieldNo("Price Includes VAT"):
                    TestField("Price Includes VAT", PriceListHeader."Price Includes VAT");
                FieldNo("VAT Bus. Posting Gr. (Price)"):
                    TestField("VAT Bus. Posting Gr. (Price)", PriceListHeader."VAT Bus. Posting Gr. (Price)");
                FieldNo("Currency Code"):
                    TestField("Currency Code", PriceListHeader."Currency Code");
                FieldNo("Starting Date"):
                    TestField("Starting Date", PriceListHeader."Starting Date");
                FieldNo("Ending Date"):
                    TestField("Ending Date", PriceListHeader."Ending Date");
                FieldNo("Source Type"):
                    if PriceListHeader."Source No." <> '' then
                        TestField("Source Type", PriceListHeader."Source Type")
                    else begin
                        LineSourceTypeError :=
                            StrSubstNo(LineSourceTypeErr, "Source Type", PriceListHeader."Source Type");
                        if "Source Type".AsInteger() < PriceListHeader."Source Type".AsInteger() then
                            FieldError("Source Type", LineSourceTypeError);
                        if not IsSourceTypeSupported() then
                            FieldError("Source Type", LineSourceTypeError);
                    end;
                FieldNo("Source No."):
                    if PriceListHeader."Source No." <> '' then
                        TestField("Source No.", PriceListHeader."Source No.");
                FieldNo("Source Id"):
                    if PriceListHeader."Source No." <> '' then
                        TestField("Source Id", PriceListHeader."Source Id");
                FieldNo("Parent Source No."):
                    if PriceListHeader."Parent Source No." <> '' then
                        TestField("Parent Source No.", PriceListHeader."Parent Source No.");
            end;
    end;

    local procedure TestStatusDraft()
    begin
        if not IsEditable() then
            TestField(Status, Status::Draft);
    end;

    procedure Verify(): Boolean;
    begin
        VerifySource();
        TestField("Asset Type");
        exit(true);
    end;

    [TryFunction]
    procedure TryVerify()
    begin
        Verify();
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

    local procedure VerifyAmountTypeForSourceType(AmountType: Enum "Price Amount Type")
    begin
        CopyTo(PriceSource);
        PriceSource.VerifyAmountTypeForSourceType(AmountType);
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

    [IntegrationEvent(true, false)]
    local procedure OnAfterCopyFromPriceAsset(PriceAsset: Record "Price Asset"; var PriceWorksheetLine: Record "Price Worksheet Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCopyFromPriceListHeader(PriceListHeader: Record "Price List Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCopyFromPriceSource(PriceSource: Record "Price Source")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyExistingPrices(var PriceWorksheetLine: Record "Price Worksheet Line"; PriceListLine: Record "Price List Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCopyToPriceAsset(var PriceAsset: Record "Price Asset")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCopyToPriceSource(var PriceSource: Record "Price Source")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopySourceFrom(var PriceWorksheetLine: Record "Price Worksheet Line"; PriceListHeader: Record "Price List Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterInitHeaderDefaults(PriceListHeader: Record "Price List Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterIsUOMSupported(PriceWorksheetLine: Record "Price Worksheet Line"; var Result: Boolean)
    begin
    end;
}