// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.PriceList;

using Microsoft.CRM.Campaign;
using Microsoft.CRM.Contact;
using Microsoft.Finance.Currency;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.Source;
using Microsoft.Pricing.Worksheet;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Pricing;
using System.Text;
using System.Globalization;

page 7024 "Prices Overview"
{
    Caption = 'Prices Overview';
    DataCaptionExpression = PageCaptionText;
    InsertAllowed = false;
    PageType = Worksheet;
    SaveValues = true;
    RefreshOnActivate = true;
    SourceTable = "Price List Line";
    ApplicationArea = Basic, Suite;
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(PriceType; PriceSource."Price Type")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Price Type Filter';
                    ToolTip = 'Specifies a filter for which prices to display: sale, purchase or both.';
                    trigger OnValidate()
                    begin
                        PriceSource.Validate("Price Type");
                        SetRecFilters();
                        SetCaption();
                    end;
                }
                group(SourceFilters)
                {
                    ShowCaption = false;
                    field(SourceType; PriceSource."Source Type")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Assign-to Type Filter';
                        ToolTip = 'Specifies a filter for which prices to display.';

                        trigger OnValidate()
                        begin
                            PriceSource.Validate("Source Type");
                            ParentSourceNoFilter := '';
                            SourceNoFilter := '';
                            SetRecFilters();
                            SetCaption();
                        end;
                    }
                    field(ParentSourceNo; ParentSourceNoFilter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Assign-to Parent No. Filter';
                        Visible = ParentSourceNoFilterEditable;
                        ToolTip = 'Specifies a filter for which prices to display.';

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            JobPriceSource: Record "Price Source";
                        begin
                            if not PriceSource.IsParentSourceAllowed() then
                                exit;
                            JobPriceSource."Source Group" := JobPriceSource."Source Group"::Job;
                            JobPriceSource."Source Type" := "Price Source Type"::Job;
                            if JobPriceSource.LookupNo() then begin
                                ParentSourceNoFilter := JobPriceSource."Source No.";
                                SourceNoFilter := '';
                            end;
                        end;

                        trigger OnValidate()
                        begin
                            PriceSource.Validate("Parent Source No.");
                        end;
                    }
                    field(SourceNo; SourceNoFilter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Assign-to Filter';
                        Enabled = SourceNoFilterEditable;
                        ToolTip = 'Specifies a filter for which prices to display.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            if PriceSource.LookupNo() then begin
                                Text := PriceSource."Source No.";
                                exit(true);
                            end;
                        end;

                        trigger OnValidate()
                        begin
                            SetRecFilters();
                            SetCaption();
                        end;
                    }
                }
                group(AssetFilters)
                {
                    ShowCaption = false;
                    field(AssetType; PriceAsset."Asset Type")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Product Type Filter';
                        ToolTip = 'Specifies a filter for which prices to display.';

                        trigger OnValidate()
                        begin
                            PriceAsset.Validate("Asset Type");
                            AssetNoFilter := '';
                            SetRecFilters();
                            SetCaption();
                        end;
                    }
                    field(AssetNo; AssetNoFilter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Product No. Filter';
                        Enabled = AssetNoFilterEditable;
                        ToolTip = 'Specifies a filter for which prices to display.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            if PriceAsset.LookupNo() then begin
                                Text := PriceAsset."Asset No.";
                                exit(true);
                            end;
                        end;

                        trigger OnValidate()
                        begin
                            SetRecFilters();
                            SetCaption();
                        end;
                    }
                }
                field(AmountType; AmountTypeFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Defines Filter';
                    ToolTip = 'Specifies whether the price list line defines prices, discounts, or both.';

                    trigger OnValidate()
                    begin
                        SetRecFilters();
                        SetCaption();
                    end;
                }
                group(DateFilters)
                {
                    ShowCaption = false;
                    field(StartingDateFilter; StartingDateFilter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date Filter';
                        ToolTip = 'Specifies a filter for which prices to display.';

                        trigger OnValidate()
                        var
                            FilterTokens: Codeunit "Filter Tokens";
                        begin
                            FilterTokens.MakeDateFilter(StartingDateFilter);
                            SetRecFilters();
                        end;
                    }
                    field(EndingDateFilter; EndingDateFilter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending Date Filter';
                        ToolTip = 'Specifies a filter for which prices to display.';

                        trigger OnValidate()
                        var
                            FilterTokens: Codeunit "Filter Tokens";
                        begin
                            FilterTokens.MakeDateFilter(EndingDateFilter);
                            SetRecFilters();
                        end;
                    }
                }
                field(CurrencyCodeFilterCtrl; CurrencyCodeFilter)
                {
                    ApplicationArea = Suite;
                    Caption = 'Currency Code Filter';
                    ToolTip = 'Specifies a filter for which prices to display.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        CurrencyList: Page Currencies;
                    begin
                        CurrencyList.LookupMode := true;
                        if CurrencyList.RunModal() = ACTION::LookupOK then
                            Text := CurrencyList.GetSelectionFilter()
                        else
                            exit(false);

                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        SetRecFilters();
                    end;
                }
            }
            repeater(Lines)
            {
                ShowCaption = false;
                field("Price List Code"; Rec."Price List Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Style = Attention;
                    StyleExpr = LineToVerify;
                    ToolTip = 'Specifies the unique identifier of the price list.';

                    trigger OnDrillDown()
                    begin
                        PriceUXManagement.EditPriceList(Rec."Price List Code");
                    end;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Style = Attention;
                    StyleExpr = LineToVerify;
                    ToolTip = 'Specifies whether the price list line is in Draft status and can be edited, Inactive and cannot be edited or used, or Active and used for price calculations.';
                }
                field("Price Type"; Rec."Price Type")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = PriceTypeVisible;
                    Editable = AllowUpdatingDefaults;
                    ToolTip = 'Specifies the price type: sale or purchase price.';
                }
                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = SourceTypeEditable;
                    ToolTip = 'Specifies the source of the price on the price list line. For example, the price can come from the customer or customer price group.';

                    trigger OnValidate()
                    begin
                        CalcSourceNoEditable()
                    end;
                }
                field("Parent Source No."; Rec."Parent Source No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = AssignToParentNoEditable;
                    ShowMandatory = AssignToParentNoEditable;
                    ToolTip = 'Specifies the unique identifier of the project on the price list line.';
                    Visible = UseCustomLookup;
                }
                field("Source No."; Rec."Source No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = AssignToNoEditable;
                    ShowMandatory = AssignToNoEditable;
                    ToolTip = 'Specifies the unique identifier of the source of the price on the price list line.';
                    Visible = UseCustomLookup;
                }
                field("Assign-to Parent No."; Rec."Assign-to Parent No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = AssignToParentNoEditable;
                    ShowMandatory = AssignToParentNoEditable;
                    ToolTip = 'Specifies the unique identifier of the project on the price list line.';
                    Visible = not UseCustomLookup;
                }
                field("Assign-to No."; Rec."Assign-to No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = AssignToNoEditable;
                    ShowMandatory = AssignToNoEditable;
                    ToolTip = 'Specifies the unique identifier of the source of the price on the price list line.';
                    Visible = not UseCustomLookup;
                }
                field("Asset Type"; Rec."Asset Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = AssetTypeEditable;
                    Style = Attention;
                    StyleExpr = LineToVerify;
                    ToolTip = 'Specifies the type of the product.';
                }
                field("Asset No."; Rec."Asset No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = PriceLineEditable;
                    ShowMandatory = PriceLineEditable;
                    Style = Attention;
                    StyleExpr = LineToVerify;
                    ToolTip = 'Specifies the number of the product.';
                    Visible = UseCustomLookup;
                }
                field("Product No."; Rec."Product No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = PriceLineEditable;
                    ShowMandatory = PriceLineEditable;
                    Style = Attention;
                    StyleExpr = LineToVerify;
                    ToolTip = 'Specifies the number of the product.';
                    Visible = not UseCustomLookup;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = VariantCodeVisible;
                    Editable = VariantCodeEditable;
                    ToolTip = 'Specifies the variant of the item on the line.';
                }
                field("Variant Code Lookup"; Rec."Variant Code Lookup")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = VariantCodeLookupVisible;
                    Editable = VariantCodeEditable;
                    ToolTip = 'Specifies the variant of the item on the line.';
                }
                field("Work Type Code"; Rec."Work Type Code")
                {
                    ApplicationArea = Jobs;
                    Visible = ResourceAssetVisible;
                    Editable = WorkTypeCodeEditable;
                    ToolTip = 'Specifies the work type code for the resource.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    Editable = DateEditable;
                    ToolTip = 'Specifies the currency code of the price list line.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = UoMVisible;
                    Editable = PriceLineEditable;
                    ToolTip = 'Specifies the unit price of the product.';
                }
                field("Unit of Measure Code Lookup"; Rec."Unit of Measure Code Lookup")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = UoMLookupVisible;
                    Editable = PriceLineEditable;
                    ToolTip = 'Specifies the unit price of the product.';
                }
                field("Minimum Quantity"; Rec."Minimum Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = PriceLineEditable;
                    ToolTip = 'Specifies the minimum quantity of the product.';
                }
                field("Amount Type"; Rec."Amount Type")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = AmountTypeIsVisible;
                    Editable = AmountTypeIsEditable;
                    ToolTip = 'Specifies whether the price list line defines prices, discounts, or both.';
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = SalesPriceVisible;
                    Editable = UnitPriceEditable;
                    Style = Attention;
                    StyleExpr = LineToVerify and SalesPriceLine and PriceEditable;
                    ToolTip = 'Specifies the unit price of the product.';
                }
                field("Cost Factor"; Rec."Cost Factor")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = SalesPriceVisible;
                    Editable = UnitPriceEditable;
                    Style = Attention;
                    StyleExpr = LineToVerify and SalesPriceLine and PriceEditable;
                    ToolTip = 'Specifies the unit cost factor for project-related prices, if you have agreed with your customer that he should pay certain item usage by cost value plus a certain percent value to cover your overhead expenses.';
                }
                field("Direct Unit Cost"; Rec."Direct Unit Cost")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = PurchPriceVisible;
                    Editable = UnitPriceEditable;
                    Style = Attention;
                    StyleExpr = LineToVerify and PurchPriceLine and PriceEditable;
                    ToolTip = 'Specifies the direct unit cost of the product.';
                }
                field("Unit Cost"; Rec."Unit Cost")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = PurchPriceVisible;
                    Editable = UnitPriceEditable;
                    Style = Attention;
                    StyleExpr = LineToVerify and PurchPriceLine and PriceEditable;
                    ToolTip = 'Specifies the unit cost of the resource.';
                }
                field("Line Discount %"; Rec."Line Discount %")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = DiscountVisible;
                    Editable = LineDiscPctEditable;
                    Style = Attention;
                    StyleExpr = LineToVerify and DiscountEditable;
                    ToolTip = 'Specifies the line discount percentage for the product.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = DateEditable;
                    ToolTip = 'Specifies the date from which the price is valid.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = DateEditable;
                    ToolTip = 'Specifies the last date that the price is valid.';
                }
                field("Allow Line Disc."; Rec."Allow Line Disc.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = AllowDiscVisible;
                    Editable = PriceLineEditable;
                    ToolTip = 'Specifies if a line discount will be calculated when the price is offered.';
                }
                field("Allow Invoice Disc."; Rec."Allow Invoice Disc.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = AllowDiscVisible;
                    Editable = PriceLineEditable;
                    ToolTip = 'Specifies if an invoice discount will be calculated when the price is offered.';
                }
                field("VAT Bus. Posting Gr. (Price)"; Rec."VAT Bus. Posting Gr. (Price)")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                    Editable = PriceLineEditable;
                    ToolTip = 'Specifies the VAT business posting group for customers for whom you want the price (which includes VAT) to apply.';
                }
                field("Price Includes VAT"; Rec."Price Includes VAT")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                    Editable = PriceLineEditable;
                    ToolTip = 'Specifies if the price includes VAT.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(OpenPriceList)
            {
                ApplicationArea = All;
                Caption = 'Open Price List';
                Image = EditLines;
                Visible = LineExists;
                ToolTip = 'View or edit the price list.';

                trigger OnAction()
                begin
                    PriceUXManagement.EditPriceList(Rec."Price List Code");
                end;
            }

        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(VerifyLines)
                {
                    ApplicationArea = Basic, Suite;
                    Ellipsis = true;
                    Image = CheckDuplicates;
                    Caption = 'Verify Lines';
                    ToolTip = 'Checks data consistency in the new and modified price list lines. Finds the duplicate price lines and suggests the resolution of the line conflicts.';

                    trigger OnAction()
                    var
                        PriceListLine: Record "Price List Line";
                    begin
                        PriceListLine.Copy(Rec);
                        PriceListManagement.ActivateDraftLines(PriceListLine);
                        CurrPage.Update(false);
                    end;
                }
                action(AddLines)
                {
                    ApplicationArea = Basic, Suite;
                    Ellipsis = true;
                    Image = NewRow;
                    Caption = 'Add New Lines';
                    ToolTip = 'Opens the page where you can add new lines manually or copy them from the existing price lists or suggest new lines based on data in the product cards.';

                    trigger OnAction()
                    var
                        PriceWorksheet: Page "Price Worksheet";
                    begin
                        CurrPage.SaveRecord();
                        PriceWorksheet.SetPriceType(PriceSource."Price Type");
                        PriceWorksheet.RunModal();
                        CurrPage.Update(false);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(VerifyLines_Promoted; VerifyLines)
                {
                }
                actionref(AddLines_Promoted; AddLines)
                {
                }
                actionref(OpenPriceList_Promoted; OpenPriceList)
                {
                }
            }
        }
    }

    trigger OnInit()
    var
        FeaturePriceCalculation: Codeunit "Feature - Price Calculation";
    begin
        FeaturePriceCalculation.FailIfFeatureDisabled();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        SetEditableFields();
        LineExists := Rec."Price List Code" <> '';
    end;

    trigger OnAfterGetRecord()
    begin
        CalcSourceNoEditable();
        SetFieldsStyle();
    end;

    trigger OnOpenPage()
    begin
        OnBeforeOpenPage(PriceSource);

        UseCustomLookup := Rec.UseCustomizedLookup();
        GetRecFilters();
        SetRecFilters();
        SetCaption();
    end;

    var
        PriceSource: Record "Price Source";
        CurrPriceListHeader: Record "Price List Header";
        PriceListManagement: Codeunit "Price List Management";
        PriceUXManagement: Codeunit "Price UX Management";
        FilterRecordRef: RecordRef;
        AmountTypeFilter: Enum "Price Amount Type";
        ParentSourceNoEditable: Boolean;
        SourceTypeEditable: Boolean;
        SourceNoEditable: Boolean;
        ParentSourceNoFilter: Text;
        ParentSourceNoFilterEditable: Boolean;
        SourceNoFilter: Text;
        SourceNoFilterEditable: Boolean;
        CurrencyCodeFilter: Text;
        StartingDateFilter: Text;
        EndingDateFilter: Text;
        PageCaptionText: Text;
        AssetNoFilterEditable: Boolean;
        LineExists: Boolean;
        UseCustomLookup: Boolean;
        Description3Lbl: Label '%1 %2 %3', Locked = true;
        Description5Lbl: Label '%1 %2 %3 %4 %5', Locked = true;
        WithinFilterLbl: Label 'No %1 within the filter %2.', Comment = '%1 - the unique entity id, %2 - the filter string ';

    protected var
        PriceAsset: Record "Price Asset";
        AssetNoFilter: Text;
        AssignToNoEditable: Boolean;
        AssignToParentNoEditable: Boolean;
        PriceTypeVisible: Boolean;
        AmountTypeIsEditable: Boolean;
        AmountTypeIsVisible: Boolean;
        PriceVisible: Boolean;
        DiscountVisible: Boolean;
        DiscountOnlyVisible: Boolean;
        SalesVisible: Boolean;
        PurchVisible: Boolean;
        ItemAssetVisible: Boolean;
        ResourceAssetVisible: Boolean;
        ItemAsset: Boolean;
        ResourceAsset: Boolean;
        PriceLineEditable: Boolean;
        AssetTypeEditable: Boolean;
        DiscountEditable: Boolean;
        PriceEditable: Boolean;
        LineToVerify: Boolean;
        SalesPriceLine: Boolean;
        SalesPriceVisible: Boolean;
        PurchPriceLine: Boolean;
        PurchPriceVisible: Boolean;
        AllowDiscVisible: Boolean;
        AllowUpdatingDefaults: Boolean;
        DateEditable: Boolean;
        VariantCodeEditable: Boolean;
        UnitPriceEditable: Boolean;
        LineDiscPctEditable: Boolean;
        VariantCodeVisible: Boolean;
        VariantCodeLookupVisible: Boolean;
        UoMVisible: Boolean;
        UoMLookupVisible: Boolean;
        WorkTypeCodeEditable: Boolean;

    procedure SetRecFilters()
    begin
        CurrPage.SaveRecord();

        RefreshSourceNoFilter();
        RefreshAssetNoFilter();
        SetFilters();
        CheckRecFilters();
        SetVisibleFields();

        CurrPage.Update(false);
    end;

    local procedure CalcSourceNoEditable()
    begin
        SourceNoEditable := Rec.IsSourceNoAllowed();
        ParentSourceNoEditable := PriceSource.IsParentSourceAllowed();
    end;

    local procedure CheckFilters(TableNo: Integer; FilterTxt: Text)
    var
        FilterFieldRef: FieldRef;
    begin
        if (FilterTxt = '') or (TableNo = 0) then
            exit;
        Clear(FilterFieldRef);
        if FilterRecordRef.Number <> TableNo then begin
            Clear(FilterRecordRef);
            FilterRecordRef.Open(TableNo);
        end;
        FilterFieldRef := FilterRecordRef.Field(1);
        FilterFieldRef.SetFilter(FilterTxt);
        if FilterRecordRef.IsEmpty() then
            Error(WithinFilterLbl, FilterRecordRef.Caption, FilterTxt);
    end;

    local procedure CheckRecFilters()
    begin
        case PriceSource."Source Type" of
            PriceSource."Source Type"::Customer:
                CheckFilters(Database::Customer, SourceNoFilter);
            PriceSource."Source Type"::"Customer Price Group":
                CheckFilters(Database::"Customer Price Group", SourceNoFilter);
            PriceSource."Source Type"::Campaign:
                CheckFilters(Database::Campaign, SourceNoFilter);
            PriceSource."Source Type"::Contact:
                CheckFilters(Database::Contact, SourceNoFilter);
        end;

        CheckFilters(PriceAsset."Table Id", AssetNoFilter);
        CheckFilters(Database::Currency, CurrencyCodeFilter);
    end;

    local procedure GetFilterDescription(): Text
    var
        Cust: Record Customer;
        CustPriceGr: Record "Customer Price Group";
        Campaign: Record Campaign;
        ObjTranslation: Record "Object Translation";
        SourceTableName: Text;
        SalesSrcTableName: Text;
        Description: Text;
    begin
        GetRecFilters();

        SourceTableName := '';
        if PriceAsset."Table Id" <> 0 then
            SourceTableName :=
                ObjTranslation.TranslateObject(ObjTranslation."Object Type"::Table, PriceAsset."Table Id");

        SalesSrcTableName := '';
        Description := '';
        case PriceSource."Source Type" of
            PriceSource."Source Type"::Customer:
                begin
                    SalesSrcTableName := ObjTranslation.TranslateObject(ObjTranslation."Object Type"::Table, 18);
                    Cust."No." := CopyStr(SourceNoFilter, 1, MaxStrLen(Cust."No."));
                    if Cust.FindFirst() then
                        Description := Cust.Name;
                end;
            PriceSource."Source Type"::"Customer Price Group":
                begin
                    SalesSrcTableName := ObjTranslation.TranslateObject(ObjTranslation."Object Type"::Table, 6);
                    CustPriceGr.Code := CopyStr(SourceNoFilter, 1, MaxStrLen(CustPriceGr.Code));
                    if CustPriceGr.FindFirst() then
                        Description := CustPriceGr.Description;
                end;
            PriceSource."Source Type"::Campaign:
                begin
                    SalesSrcTableName := ObjTranslation.TranslateObject(ObjTranslation."Object Type"::Table, 5071);
                    Campaign."No." := CopyStr(SourceNoFilter, 1, MaxStrLen(Campaign."No."));
                    if Campaign.FindFirst() then
                        Description := Campaign.Description;
                end;
            PriceSource."Source Type"::"All Customers":
                begin
                    SalesSrcTableName := Format(PriceSource."Source Type");
                    exit(StrSubstNo(Description3Lbl, SalesSrcTableName, SourceTableName, AssetNoFilter));
                end;
        end;

        exit(StrSubstNo(Description5Lbl, SalesSrcTableName, SourceNoFilter, Description, SourceTableName, PriceAsset."Asset No."));
    end;

    local procedure GetRecFilters()
    begin
        Rec.FilterGroup(2);
        if Rec.GetFilters() <> '' then
            UpdateBasicRecFilters();

        Evaluate(StartingDateFilter, Rec.GetFilter("Starting Date"));
        Rec.FilterGroup(0);
    end;

    local procedure RefreshAssetNoFilter()
    begin
        AssetNoFilterEditable := PriceAsset.IsAssetNoRequired();
        if not AssetNoFilterEditable then
            AssetNoFilter := '';
    end;

    local procedure RefreshSourceNoFilter()
    begin
        SourceNoFilterEditable := PriceSource.IsSourceNoAllowed();
        ParentSourceNoFilterEditable := PriceSource.IsParentSourceAllowed();
        if not SourceNoFilterEditable then begin
            ParentSourceNoFilter := '';
            SourceNoFilter := '';
        end;
    end;

    local procedure SetCaption()
    begin
        PageCaptionText := GetFilterDescription();
    end;

    local procedure SetEditableFields()
    begin
        if Rec."Price List Code" <> CurrPriceListHeader.Code then begin
            AllowUpdatingDefaults := true;
            if CurrPriceListHeader.Get(Rec."Price List Code") then
                AllowUpdatingDefaults := CurrPriceListHeader."Allow Updating Defaults";
        end;

        ItemAsset := Rec.IsAssetItem();
        ResourceAsset := Rec.IsAssetResource();
        PriceLineEditable := Rec.IsEditable();
        SourceTypeEditable :=
            (PriceSource."Source Type" = PriceSource."Source Type"::All) and PriceLineEditable and AllowUpdatingDefaults;
        AssetTypeEditable := (PriceAsset."Asset Type" = PriceAsset."Asset Type"::" ") and PriceLineEditable;
        AmountTypeIsEditable := (Rec."Asset Type" <> Rec."Asset Type"::"Item Discount Group") and PriceLineEditable;
        CalcSourceNoEditable();
        SetFieldsStyle();
        VariantCodeEditable := PriceLineEditable and ItemAsset;
        UnitPriceEditable := PriceLineEditable and PriceEditable;
        DateEditable := PriceLineEditable and AllowUpdatingDefaults;
        LineDiscPctEditable := PriceLineEditable and DiscountEditable;
        AssignToNoEditable := SourceNoEditable and PriceLineEditable and AllowUpdatingDefaults;
        AssignToParentNoEditable := PriceLineEditable and ParentSourceNoEditable and AllowUpdatingDefaults;
        WorkTypeCodeEditable := PriceLineEditable and ResourceAsset;
    end;

    local procedure SetFieldsStyle()
    begin
        LineToVerify := Rec.IsLineToVerify();
        SalesPriceLine := Rec."Price Type" = Rec."Price Type"::Sale;
        PurchPriceLine := Rec."Price Type" = Rec."Price Type"::Purchase;
        PriceEditable := Rec."Amount Type" in [Rec."Amount Type"::Any, Rec."Amount Type"::Price];
        DiscountEditable := Rec."Amount Type" in [Rec."Amount Type"::Any, Rec."Amount Type"::Discount];
    end;

    local procedure SetFilters()
    begin
        Rec.FilterGroup(2);
        if PriceSource."Price Type" <> PriceSource."Price Type"::Any then
            Rec.SetRange("Price Type", PriceSource."Price Type")
        else
            Rec.SetRange("Price Type");

        if PriceSource."Source Type" <> PriceSource."Source Type"::All then
            Rec.SetRange("Source Type", PriceSource."Source Type")
        else
            Rec.SetRange("Source Type");

        if SourceNoFilter <> '' then
            Rec.SetFilter("Source No.", SourceNoFilter)
        else
            Rec.SetRange("Source No.");

        if PriceAsset."Asset Type" <> PriceAsset."Asset Type"::" " then
            Rec.SetRange("Asset Type", PriceAsset."Asset Type")
        else
            Rec.SetRange("Asset Type");

        if AssetNoFilter <> '' then
            Rec.SetFilter("Asset No.", AssetNoFilter)
        else
            Rec.SetRange("Asset No.");

        if AmountTypeFilter <> AmountTypeFilter::Any then
            Rec.SetRange("Amount Type", AmountTypeFilter)
        else
            Rec.SetRange("Amount Type");

        if CurrencyCodeFilter <> '' then
            Rec.SetFilter("Currency Code", CurrencyCodeFilter)
        else
            Rec.SetRange("Currency Code");

        if StartingDateFilter <> '' then
            Rec.SetFilter("Starting Date", StartingDateFilter)
        else
            Rec.SetRange("Starting Date");

        if EndingDateFilter <> '' then
            Rec.SetFilter("Ending Date", EndingDateFilter)
        else
            Rec.SetRange("Ending Date");
        Rec.FilterGroup(0);

        OnAfterSetFilters(Rec, StartingDateFilter, EndingDateFilter);
    end;

    local procedure SetVisibleFields()
    var
        PriceListLine: Record "Price List Line";
    begin
        PriceTypeVisible := PriceSource."Price Type" = PriceSource."Price Type"::Any;
        AmountTypeIsVisible := AmountTypeFilter = AmountTypeFilter::Any;
        PriceVisible := AmountTypeFilter in [AmountTypeFilter::Any, AmountTypeFilter::Price];
        DiscountVisible := AmountTypeFilter in [AmountTypeFilter::Any, AmountTypeFilter::Discount];
        DiscountOnlyVisible := PriceAsset."Asset Type" = PriceAsset."Asset Type"::"Item Discount Group";
        SalesVisible := PriceSource."Price Type" in [PriceSource."Price Type"::Any, PriceSource."Price Type"::Sale];
        PurchVisible := PriceSource."Price Type" in [PriceSource."Price Type"::Any, PriceSource."Price Type"::Purchase];

        PriceListLine."Asset Type" := PriceAsset."Asset Type";
        ItemAssetVisible := (PriceAsset."Asset Type" = PriceAsset."Asset Type"::" ") or PriceListLine.IsAssetItem();
        ResourceAssetVisible := (PriceAsset."Asset Type" = PriceAsset."Asset Type"::" ") or PriceListLine.IsAssetResource();
        SalesPriceVisible := PriceVisible and SalesVisible and not DiscountOnlyVisible;
        PurchPriceVisible := PriceVisible and PurchVisible and not DiscountOnlyVisible;
        AllowDiscVisible := PriceVisible and not DiscountOnlyVisible;
        VariantCodeVisible := ItemAssetVisible and UseCustomLookup;
        VariantCodeLookupVisible := ItemAssetVisible and not UseCustomLookup;
        UoMVisible := (ItemAssetVisible or ResourceAssetVisible) and UseCustomLookup;
        UoMLookupVisible := (ItemAssetVisible or ResourceAssetVisible) and not UseCustomLookup;
    end;

    local procedure UpdateBasicRecFilters()
    begin
        if Rec.GetFilter("Source Type") <> '' then
            Evaluate(PriceSource."Source Type", Rec.GetFilter("Source Type"))
        else
            PriceSource."Source Type" := PriceSource."Source Type"::All;

        SourceNoFilter := Rec.GetFilter("Source No.");
        AssetNoFilter := Rec.GetFilter("Asset No.");
        CurrencyCodeFilter := Rec.GetFilter("Currency Code");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetFilters(var PriceListLine: record "Price List Line"; var StartingDateFilter: Text; var EndingDateFilter: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenPage(var PriceSource: record "Price Source")
    begin
    end;
}

