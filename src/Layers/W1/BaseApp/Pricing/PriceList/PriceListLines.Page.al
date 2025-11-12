// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.PriceList;

using Microsoft.Pricing.Source;
using Microsoft.Projects.Project.Pricing;
using Microsoft.Sales.Pricing;
using System.Environment.Configuration;
using System.Integration.Excel;

page 7001 "Price List Lines"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = ListPart;
    SourceTable = "Price List Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(SourceType; SourceType)
                {
                    ApplicationArea = All;
                    Caption = 'Assign-to Type';
                    Visible = SourceTypeVisible;
                    ToolTip = 'Specifies the type of entity to which the price list is assigned. The options are relevant to the entity you are currently viewing.';

                    trigger OnValidate()
                    begin
                        ValidateSourceType(SourceType.AsInteger());
                    end;
                }
                field(JobSourceType; JobSourceType)
                {
                    ApplicationArea = All;
                    Caption = 'Assign-to Type';
                    Visible = JobSourceTypeVisible;
                    ToolTip = 'Specifies the type of entity to which the price list is assigned. The options are relevant to the entity you are currently viewing.';

                    trigger OnValidate()
                    begin
                        ValidateSourceType(JobSourceType.AsInteger());
                    end;
                }
                field(ParentSourceNo; Rec."Parent Source No.")
                {
                    ApplicationArea = All;
                    Caption = 'Assign-to Project No.';
                    Importance = Promoted;
                    Editable = IsParentAllowed;
                    Visible = ParentSourceNoVisible;
                    ToolTip = 'Specifies the project to which the prices are assigned. If you choose an entity, the price list will be used only for that entity.';
                }
                field(AssignToParentNo; Rec."Assign-to Parent No.")
                {
                    ApplicationArea = All;
                    Caption = 'Assign-to Project No.';
                    Importance = Promoted;
                    Editable = IsParentAllowed;
                    ShowMandatory = IsParentAllowed;
                    Visible = AssignToParentNoVisible;
                    ToolTip = 'Specifies the project to which the prices are assigned. If you choose an entity, the price list will be used only for that entity.';
                }
                field(SourceNo; Rec."Source No.")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    Enabled = SourceNoEnabled;
                    ShowMandatory = SourceNoEnabled;
                    Visible = SourceNoVisible;
                    ToolTip = 'Specifies the entity to which the prices are assigned. The options depend on the selection in the Assign-to Type field. If you choose an entity, the price list will be used only for that entity.';
                }
                field(AssignToNo; Rec."Assign-to No.")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    Enabled = SourceNoEnabled;
                    ShowMandatory = SourceNoEnabled;
                    Visible = AssignToNoVisible;
                    ToolTip = 'Specifies the entity to which the prices are assigned. The options depend on the selection in the Assign-to Type field. If you choose an entity, the price list will be used only for that entity.';
                }
                field(CurrencyCode; Rec."Currency Code")
                {
                    ApplicationArea = All;
                    Visible = AllowUpdatingDefaults;
                    ToolTip = 'Specifies the currency that is used for the prices on the price list. The currency can be the same for all prices on the price list, or you can specify a currency for individual lines.';
                }
                field(StartingDate; Rec."Starting Date")
                {
                    ApplicationArea = All;
                    Visible = AllowUpdatingDefaults;
                    ToolTip = 'Specifies the date from which the price is valid.';
                }
                field(EndingDate; Rec."Ending Date")
                {
                    ApplicationArea = All;
                    Visible = AllowUpdatingDefaults;
                    ToolTip = 'Specifies the last date that the price is valid.';
                }
                field("Asset Type"; Rec."Asset Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of the product.';

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                    end;
                }
                field("Asset No."; Rec."Asset No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the identifier of the product. If no product is selected, the price and discount values will apply to all products of the selected product type for which those values are not specified. For example, if you choose Item as the product type but do not specify a specific item, the price will apply to all items for which a price is not specified.';
                    Style = Attention;
                    StyleExpr = LineToVerify;
                    Visible = UseCustomLookup;
                    ShowMandatory = true;

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field("Product No."; Rec."Product No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the identifier of the product. If no product is selected, the price and discount values will apply to all products of the selected product type for which those values are not specified. For example, if you choose Item as the product type but do not specify a specific item, the price will apply to all items for which a price is not specified.';
                    Style = Attention;
                    StyleExpr = LineToVerify;
                    Visible = not UseCustomLookup;
                    ShowMandatory = true;

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the product.';
                    Style = Attention;
                    StyleExpr = LineToVerify;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = All;
                    Enabled = ItemAsset;
                    Editable = ItemAsset;
                    Visible = UseCustomLookup;
                    ToolTip = 'Specifies the item variant.';
                }
                field("Variant Code Lookup"; Rec."Variant Code Lookup")
                {
                    ApplicationArea = All;
                    Enabled = ItemAsset;
                    Editable = ItemAsset;
                    Visible = not UseCustomLookup;
                    ToolTip = 'Specifies the item variant.';
                }
                field("Work Type Code"; Rec."Work Type Code")
                {
                    ApplicationArea = All;
                    Enabled = ResourceAsset;
                    Editable = ResourceAsset;
                    ToolTip = 'Specifies the work type code for the resource.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                    Enabled = UOMEditable;
                    Editable = UOMEditable;
                    Visible = UseCustomLookup;
                    ToolTip = 'Specifies the unit of measure for the product.';
                }
                field("Unit of Measure Code Lookup"; Rec."Unit of Measure Code Lookup")
                {
                    ApplicationArea = All;
                    Enabled = UOMEditable;
                    Editable = UOMEditable;
                    Visible = not UseCustomLookup;
                    ToolTip = 'Specifies the unit of measure for the product.';
                }
                field("Minimum Quantity"; Rec."Minimum Quantity")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the minimum quantity of the product.';
                }
                field("Amount Type"; Rec."Amount Type")
                {
                    ApplicationArea = All;
                    Importance = Standard;
                    Visible = AmountTypeIsVisible;
                    Editable = AmountTypeIsEditable;
                    ToolTip = 'Specifies whether the price list line defines prices, discounts, or both.';
                    trigger OnValidate()
                    begin
                        SetMandatoryAmount();
                    end;
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    AccessByPermission = tabledata "Sales Price Access" = R;
                    ApplicationArea = All;
                    Editable = AmountEditable;
                    Enabled = PriceMandatory;
                    Visible = PriceVisible;
                    StyleExpr = PriceStyle;
                    ToolTip = 'Specifies the unit price of the product.';
                }
                field("Cost Factor"; Rec."Cost Factor")
                {
                    AccessByPermission = tabledata "Sales Price Access" = R;
                    ApplicationArea = All;
                    Editable = AmountEditable;
                    Enabled = PriceMandatory;
                    Visible = CostFactorVisible;
                    StyleExpr = PriceStyle;
                    ToolTip = 'Specifies the unit cost factor for project-related prices, if you have agreed with your customer that he should pay certain item usage by cost value plus a certain percent value to cover your overhead expenses.';
                }
                field("Allow Line Disc."; Rec."Allow Line Disc.")
                {
                    ApplicationArea = All;
                    Visible = PriceVisible;
                    Enabled = PriceMandatory;
                    Editable = PriceMandatory;
                    ToolTip = 'Specifies if a line discount will be calculated when the price is offered.';
                }
                field("Line Discount %"; Rec."Line Discount %")
                {
                    AccessByPermission = tabledata "Sales Discount Access" = R;
                    ApplicationArea = All;
                    Visible = DiscountVisible;
                    Enabled = DiscountMandatory;
                    Editable = DiscountMandatory;
                    StyleExpr = DiscountStyle;
                    ToolTip = 'Specifies the line discount percentage for the product.';
                }
                field("Allow Invoice Disc."; Rec."Allow Invoice Disc.")
                {
                    ApplicationArea = All;
                    Visible = PriceVisible;
                    Enabled = PriceMandatory;
                    Editable = PriceMandatory;
                    ToolTip = 'Specifies if an invoice discount will be calculated when the price is offered.';
                }
                field(PriceIncludesVAT; Rec."Price Includes VAT")
                {
                    ApplicationArea = All;
                    Visible = AllowUpdatingDefaults;
                    ToolTip = 'Specifies the if prices include VAT.';
                }
                field(VATBusPostingGrPrice; Rec."VAT Bus. Posting Gr. (Price)")
                {
                    ApplicationArea = All;
                    Visible = AllowUpdatingDefaults;
                    ToolTip = 'Specifies the default VAT business posting group code.';
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(EditInExcel)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Edit in Excel';
                Image = Excel;
                ToolTip = 'Send the data in the worksheet to an Excel file for analysis or editing.';
                Visible = IsSaaSExcelAddinEnabled;
                AccessByPermission = System "Allow Action Export To Excel" = X;

                trigger OnAction()
                var
                    EditinExcel: Codeunit "Edit in Excel";
                    EditinExcelFilters: Codeunit "Edit in Excel Filters";
                begin
                    EditinExcelFilters.AddFieldV2('Price_List_Code', Enum::"Edit in Excel Filter Type"::Equal, Rec."Price List Code", Enum::"Edit in Excel Edm Type"::"Edm.String");
                    EditinExcel.EditPageInExcel('Price List Lines', Page::"Price List Lines", EditinExcelFilters, StrSubstNo(ExcelFileNameTxt, Rec."Price List Code"));
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        ServerSetting: Codeunit "Server Setting";
    begin
        UseCustomLookup := Rec.UseCustomizedLookup();
        IsSaaSExcelAddinEnabled := ServerSetting.GetIsSaasExcelAddinEnabled();
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateSourceType();
        SetSourceNoEnabled();
        LineToVerify := Rec.IsLineToVerify();
        SetMandatoryAmount();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        SetEditable();
        UpdateSourceType();
        SetSourceNoEnabled();
        LineToVerify := Rec.IsLineToVerify();
        SetMandatoryAmount();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if not GetHeader() then
            exit;
        if PriceListHeader."Allow Updating Defaults" then begin
            Rec.CopySourceFrom(PriceListHeader);
            if Rec."Starting Date" = 0D then
                Rec."Starting Date" := PriceListHeader."Starting Date";
            if Rec."Ending Date" = 0D then
                Rec."Ending Date" := PriceListHeader."Ending Date";
            if Rec."Currency Code" = '' then
                Rec."Currency Code" := PriceListHeader."Currency Code";
        end;
        Rec."Amount Type" := ViewAmountType;
        Rec.SetNewRecord(true);
        Rec.Validate("Asset Type", xRec."Asset Type");
        UpdateSourceType();
    end;

    protected procedure GetHeader(): Boolean
    begin
        if Rec."Price List Code" = '' then
            exit(false);
        if PriceListHeader.Code = Rec."Price List Code" then
            exit(true);
        exit(PriceListHeader.Get(Rec."Price List Code"));
    end;

    var
        JobSourceType: Enum "Job Price Source Type";
        SourceType: Enum "Sales Price Source Type";

    protected var
        PriceListHeader: Record "Price List Header";
        PriceType: Enum "Price Type";
        ViewAmountType: Enum "Price Amount Type";
        AllowUpdatingDefaults: Boolean;
        AmountEditable: Boolean;
        AmountTypeIsEditable: Boolean;
        AmountTypeIsVisible: Boolean;
        DiscountStyle: Text;
        DiscountMandatory: Boolean;
        DiscountVisible: Boolean;
        IsJobGroup: Boolean;
        IsParentAllowed: Boolean;
        ItemAsset: Boolean;
        PriceStyle: Text;
        PriceMandatory: Boolean;
        AssignToNoVisible: Boolean;
        AssignToParentNoVisible: Boolean;
        IsSaaSExcelAddinEnabled: Boolean;
        JobSourceTypeVisible: Boolean;
        SourceTypeVisible: Boolean;
        SourceNoVisible: Boolean;
        PriceVisible: Boolean;
        ResourceAsset: Boolean;
        SourceNoEnabled: Boolean;
        ParentSourceNoVisible: Boolean;
        LineToVerify: Boolean;
        UOMEditable: Boolean;
        CostFactorVisible: Boolean;
        UseCustomLookup: Boolean;
        ExcelFileNameTxt: Label 'Sales Price List %1 - Lines', Comment = '%1 = Price List Code';

    local procedure GetStyle(Mandatory: Boolean): Text;
    begin
        if LineToVerify and Mandatory then
            exit('Attention');
        if Mandatory then
            exit('Strong');
        exit('Subordinate');
    end;

    local procedure SetEditable()
    begin
        AmountTypeIsEditable := Rec."Asset Type" <> Rec."Asset Type"::"Item Discount Group";
        AmountEditable := Rec.IsAmountSupported();
        UOMEditable := Rec.IsUOMSupported();
        ItemAsset := Rec.IsAssetItem();
        ResourceAsset := Rec.IsAssetResource();
    end;

    local procedure SetMandatoryAmount()
    begin
        DiscountMandatory := Rec.IsAmountMandatory(Rec."Amount Type"::Discount);
        DiscountStyle := GetStyle(DiscountMandatory);
        PriceMandatory := Rec.IsAmountMandatory(Rec."Amount Type"::Price);
        PriceStyle := GetStyle(PriceMandatory);
    end;

    local procedure UpdateColumnVisibility()
    begin
        AllowUpdatingDefaults := PriceListHeader."Allow Updating Defaults";
        AmountTypeIsVisible := ViewAmountType = ViewAmountType::Any;
        DiscountVisible := ViewAmountType in [ViewAmountType::Any, ViewAmountType::Discount];
        PriceVisible := ViewAmountType in [ViewAmountType::Any, ViewAmountType::Price];
        CostFactorVisible := IsJobGroup and PriceVisible;
        AssignToNoVisible := AllowUpdatingDefaults and not UseCustomLookup;
        AssignToParentNoVisible := IsJobGroup and AssignToNoVisible;
        SourceNoVisible := AllowUpdatingDefaults and UseCustomLookup;
        ParentSourceNoVisible := IsJobGroup and SourceNoVisible;
        JobSourceTypeVisible := IsJobGroup and AllowUpdatingDefaults;
        SourceTypeVisible := not IsJobGroup and AllowUpdatingDefaults;
        OnAfterUpdateColumnVisibility(PriceListHeader, SourceTypeVisible, JobSourceTypeVisible);
    end;

    procedure SetHeader(NewPriceListHeader: Record "Price List Header")
    begin
        PriceListHeader := NewPriceListHeader;
        Rec.SetHeader(PriceListHeader);

        SetSubFormLinkFilter(PriceListHeader."Amount Type");
    end;

    procedure SetPriceType(NewPriceType: Enum "Price Type")
    begin
        PriceType := NewPriceType;
        PriceListHeader."Price Type" := NewPriceType;
    end;

    procedure SetSubFormLinkFilter(NewViewAmountType: Enum "Price Amount Type")
    begin
        ViewAmountType := NewViewAmountType;
        Rec.FilterGroup(2);
        if ViewAmountType = ViewAmountType::Any then
            Rec.SetRange("Amount Type")
        else
            Rec.SetFilter("Amount Type", '%1|%2', ViewAmountType, ViewAmountType::Any);
        Rec.FilterGroup(0);
        UpdateSourceType();
        UpdateColumnVisibility();
        CurrPage.Update(false);
    end;

    local procedure UpdateSourceType()
    begin
        case PriceListHeader."Source Group" of
            PriceListHeader."Source Group"::Customer:
                begin
                    IsJobGroup := false;
                    SourceType := "Sales Price Source Type".FromInteger(Rec."Source Type".AsInteger());
                end;
            PriceListHeader."Source Group"::Job:
                begin
                    IsJobGroup := true;
                    JobSourceType := "Job Price Source Type".FromInteger(Rec."Source Type".AsInteger());
                end;
            else
                OnUpdateSourceTypeOnCaseElse(PriceListHeader, SourceType, IsJobGroup);
        end;
    end;

    protected procedure SetSourceNoEnabled()
    var
        PriceSource: Record "Price Source";
    begin
        PriceSource."Source Type" := Rec."Source Type";
        IsParentAllowed := PriceSource.IsParentSourceAllowed();
        SourceNoEnabled := Rec.IsSourceNoAllowed();
    end;

    protected procedure ValidateSourceType(SourceType: Integer)
    begin
        Rec.Validate("Source Type", SourceType);
        SetSourceNoEnabled();
        CurrPage.Update(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateColumnVisibility(PriceListHeader: Record "Price List Header"; var SourceTypeVisible: Boolean; var JobSourceTypeVisible: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnUpdateSourceTypeOnCaseElse(PriceListHeader: Record "Price List Header"; var SourceType: Enum "Sales Price Source Type"; var IsJobGroup: Boolean)
    begin
    end;
}