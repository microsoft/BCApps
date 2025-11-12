// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Pricing;

using Microsoft.CRM.Campaign;
using Microsoft.Finance.Currency;
using Microsoft.Inventory.Item;
using Microsoft.Pricing.Calculation;
using Microsoft.Sales.Customer;
using System.Environment;
using System.Text;
using System.Globalization;

page 7004 "Sales Line Discounts"
{
    Caption = 'Sales Line Discounts';
    DataCaptionExpression = PageCaptionText;
    DelayedInsert = true;
    PageType = List;
    SaveValues = true;
    ShowFilter = false;
    SourceTable = "Sales Line Discount";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                Visible = not IsOnMobile;
                field(SalesTypeFilter; SalesTypeFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Type Filter';
                    OptionCaption = 'Customer,Customer Discount Group,All Customers,Campaign,None';
                    ToolTip = 'Specifies a filter for which sales line discounts to display.';

                    trigger OnValidate()
                    begin
                        SalesTypeFilterOnAfterValidate();
                    end;
                }
                field(SalesCodeFilterCtrl; SalesCodeFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Code Filter';
                    Enabled = SalesCodeFilterCtrlEnable;
                    ToolTip = 'Specifies a filter for which sales line discounts to display.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        CustList: Page "Customer List";
                        CustDiscGrList: Page "Customer Disc. Groups";
                        CampaignList: Page "Campaign List";
                    begin
                        if SalesTypeFilter = SalesTypeFilter::"All Customers" then
                            exit;

                        case SalesTypeFilter of
                            SalesTypeFilter::Customer:
                                begin
                                    CustList.LookupMode := true;
                                    if CustList.RunModal() = ACTION::LookupOK then
                                        Text := CustList.GetSelectionFilter()
                                    else
                                        exit(false);
                                end;
                            SalesTypeFilter::"Customer Discount Group":
                                begin
                                    CustDiscGrList.LookupMode := true;
                                    if CustDiscGrList.RunModal() = ACTION::LookupOK then
                                        Text := CustDiscGrList.GetSelectionFilter()
                                    else
                                        exit(false);
                                end;
                            SalesTypeFilter::Campaign:
                                begin
                                    CampaignList.LookupMode := true;
                                    if CampaignList.RunModal() = ACTION::LookupOK then
                                        Text := CampaignList.GetSelectionFilter()
                                    else
                                        exit(false);
                                end;
                        end;

                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        SalesCodeFilterOnAfterValidate();
                    end;
                }
                field(StartingDateFilter; StartingDateFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Starting Date Filter';
                    ToolTip = 'Specifies a filter for which sales line discounts to display.';

                    trigger OnValidate()
                    var
                        FilterTokens: Codeunit "Filter Tokens";
                    begin
                        FilterTokens.MakeDateFilter(StartingDateFilter);
                        StartingDateFilterOnAfterValid();
                    end;
                }
                field(ItemTypeFilter; ItemTypeFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Type Filter';
                    OptionCaption = 'Item,Item Discount Group,None';
                    ToolTip = 'Specifies a filter for which sales line discounts to display.';

                    trigger OnValidate()
                    begin
                        ItemTypeFilterOnAfterValidate();
                    end;
                }
                field(CodeFilterCtrl; CodeFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Code Filter';
                    Enabled = CodeFilterCtrlEnable;
                    ToolTip = 'Specifies a filter for which sales line discounts to display.';

                    trigger OnLookup(var Text: Text) Result: Boolean
                    var
                        ItemList: Page "Item List";
                        ItemDiscGrList: Page "Item Disc. Groups";
                    begin
                        Result := true;
                        case Rec.Type of
                            Rec.Type::Item:
                                begin
                                    ItemList.LookupMode := true;
                                    if ItemList.RunModal() = ACTION::LookupOK then
                                        Text := ItemList.GetSelectionFilter()
                                    else
                                        Result := false;
                                end;
                            Rec.Type::"Item Disc. Group":
                                begin
                                    ItemDiscGrList.LookupMode := true;
                                    if ItemDiscGrList.RunModal() = ACTION::LookupOK then
                                        Text := ItemDiscGrList.GetSelectionFilter()
                                    else
                                        Result := false;
                                end;
                            else
                                OnLookupCodeFilterCaseElse(Rec, Text, Result);
                        end;

                        exit(Result);
                    end;

                    trigger OnValidate()
                    begin
                        CodeFilterOnAfterValidate();
                    end;
                }
                field(SalesCodeFilterCtrl2; CurrencyCodeFilter)
                {
                    ApplicationArea = Suite;
                    Caption = 'Currency Code Filter';
                    ToolTip = 'Specifies a filter for which sales line discounts to display.';

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
                        CurrencyCodeFilterOnAfterValid();
                    end;
                }
            }
            group(Filters)
            {
                Caption = 'Filters';
                Visible = IsOnMobile;
                field(FilterDescription; GetFilterDescription())
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                    ToolTip = 'Specifies a filter for which sales line discounts to display.';

                    trigger OnAssistEdit()
                    begin
                        FilterLines();
                        CurrPage.Update(false);
                    end;
                }
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Sales Type"; Rec."Sales Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sales type of the sales line discount. The sales type defines whether the sales price is for an individual customer, customer discount group, all customers, or for a campaign.';

                    trigger OnValidate()
                    begin
                        SetEditableFields();
                    end;
                }
                field("Sales Code"; Rec."Sales Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = SalesCodeEditable;
                    ToolTip = 'Specifies one of the following values, depending on the value in the Sales Type field.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of item that the sales discount line is valid for. That is, either an item or an item discount group.';
                }
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies one of two values, depending on the value in the Type field.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the currency code of the sales line discount price.';
                    Visible = false;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Minimum Quantity"; Rec."Minimum Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the minimum quantity that the customer must purchase in order to gain the agreed discount.';
                }
                field("Line Discount %"; Rec."Line Discount %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the discount percentage that is granted for the item on the line.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date from which the sales line discount is valid.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date to which the sales line discount is valid.';
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
        area(processing)
        {
            action(SalesLineDiscountsFilter)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Filter';
                Image = "Filter";
                ToolTip = 'Apply the filter.';
                Visible = IsOnMobile;

                trigger OnAction()
                begin
                    FilterLines();
                end;
            }
            action(ClearFilter)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Clear Filter';
                Image = ClearFilter;
                ToolTip = 'Clear filter.';
                Visible = IsOnMobile;

                trigger OnAction()
                begin
                    Rec.Reset();
                    UpdateBasicRecFilters();
                    SetEditableFields();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(SalesLineDiscountsFilter_Promoted; SalesLineDiscountsFilter)
                {
                }
                actionref(ClearFilter_Promoted; ClearFilter)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        SetEditableFields();
    end;

    trigger OnInit()
    var
        FeaturePriceCalculation: Codeunit "Feature - Price Calculation";
    begin
        FeaturePriceCalculation.FailIfFeatureEnabled();
        CodeFilterCtrlEnable := true;
        SalesCodeFilterCtrlEnable := true;
        SalesCodeEditable := true;
    end;

    trigger OnOpenPage()
    begin
        IsOnMobile := ClientTypeManagement.GetCurrentClientType() = CLIENTTYPE::Phone;
        GetRecFilters();
        SetRecFilters();
        SetCaption();
    end;

    var
        Cust: Record Customer;
        CustDiscGr: Record "Customer Discount Group";
        Campaign: Record Campaign;
        Item: Record Item;
        ItemDiscGr: Record "Item Discount Group";
        ClientTypeManagement: Codeunit "Client Type Management";
#pragma warning disable AA0074
        Text000: Label 'All Customers';
#pragma warning restore AA0074
        PageCaptionText: Text;
        SalesCodeEditable: Boolean;
        SalesCodeFilterCtrlEnable: Boolean;
        CodeFilterCtrlEnable: Boolean;
        IsOnMobile: Boolean;

    protected var
        CodeFilter: Text;
        CurrencyCodeFilter: Text;
        SalesCodeFilter: Text;
        SalesTypeFilter: Option Customer,"Customer Discount Group","All Customers",Campaign,"None";
        ItemTypeFilter: Option Item,"Item Discount Group","None";
        StartingDateFilter: Text[30];

    local procedure GetRecFilters()
    begin
        if Rec.GetFilters() <> '' then
            UpdateBasicRecFilters();
    end;

    procedure SetRecFilters()
    begin
        SalesCodeFilterCtrlEnable := true;
        CodeFilterCtrlEnable := true;

        if SalesTypeFilter <> SalesTypeFilter::None then
            Rec.SetRange("Sales Type", SalesTypeFilter)
        else
            Rec.SetRange("Sales Type");

        if SalesTypeFilter in [SalesTypeFilter::"All Customers", SalesTypeFilter::None] then begin
            SalesCodeFilterCtrlEnable := false;
            SalesCodeFilter := '';
        end;

        if SalesCodeFilter <> '' then
            Rec.SetFilter("Sales Code", SalesCodeFilter)
        else
            Rec.SetRange("Sales Code");

        if ItemTypeFilter <> ItemTypeFilter::None then
            Rec.SetRange(Type, ItemTypeFilter)
        else
            Rec.SetRange(Type);

        if ItemTypeFilter = ItemTypeFilter::None then begin
            CodeFilterCtrlEnable := false;
            CodeFilter := '';
        end;

        if CodeFilter <> '' then
            Rec.SetFilter(Code, CodeFilter)
        else
            Rec.SetRange(Code);

        if CurrencyCodeFilter <> '' then
            Rec.SetFilter("Currency Code", CurrencyCodeFilter)
        else
            Rec.SetRange("Currency Code");

        if StartingDateFilter <> '' then
            Rec.SetFilter("Starting Date", StartingDateFilter)
        else
            Rec.SetRange("Starting Date");

        CurrPage.Update(false);
    end;

    local procedure SetCaption()
    begin
        if IsOnMobile then
            PageCaptionText := ''
        else
            PageCaptionText := GetFilterDescription();
    end;

    local procedure GetFilterDescription(): Text
    var
        ObjTranslation: Record "Object Translation";
        SourceTableName: Text;
        SalesSrcTableName: Text;
        Description: Text;
    begin
        GetRecFilters();

        SourceTableName := '';
        case ItemTypeFilter of
            ItemTypeFilter::Item:
                begin
                    SourceTableName := ObjTranslation.TranslateObject(ObjTranslation."Object Type"::Table, 27);
                    Item.SetFilter("No.", CodeFilter);
                    if not Item.FindFirst() then
                        Clear(Item);
                end;
            ItemTypeFilter::"Item Discount Group":
                begin
                    SourceTableName := ObjTranslation.TranslateObject(ObjTranslation."Object Type"::Table, 341);
                    ItemDiscGr.SetFilter(Code, CodeFilter);
                    if not ItemDiscGr.FindFirst() then
                        Clear(ItemDiscGr);
                end;
        end;

        SalesSrcTableName := '';
        Description := '';
        case SalesTypeFilter of
            SalesTypeFilter::Customer:
                begin
                    SalesSrcTableName := ObjTranslation.TranslateObject(ObjTranslation."Object Type"::Table, 18);
                    Cust.SetFilter("No.", SalesCodeFilter);
                    if Cust.FindFirst() then
                        Description := Cust.Name;
                end;
            SalesTypeFilter::"Customer Discount Group":
                begin
                    SalesSrcTableName := ObjTranslation.TranslateObject(ObjTranslation."Object Type"::Table, 340);
                    CustDiscGr.SetFilter(Code, SalesCodeFilter);
                    if CustDiscGr.FindFirst() then
                        Description := CustDiscGr.Description;
                end;
            SalesTypeFilter::Campaign:
                begin
                    SalesSrcTableName := ObjTranslation.TranslateObject(ObjTranslation."Object Type"::Table, 5071);
                    Campaign.SetFilter("No.", SalesCodeFilter);
                    if Campaign.FindFirst() then
                        Description := Campaign.Description;
                end;
            SalesTypeFilter::"All Customers":
                SalesSrcTableName := Text000;
        end;

        if SalesSrcTableName = Text000 then
            exit(StrSubstNo('%1 %2 %3 %4 %5', SalesSrcTableName, SalesCodeFilter, Description, SourceTableName, CodeFilter));
        exit(StrSubstNo('%1 %2 %3 %4 %5', SalesSrcTableName, SalesCodeFilter, Description, SourceTableName, CodeFilter));
    end;

    local procedure SalesCodeFilterOnAfterValidate()
    begin
        CurrPage.SaveRecord();
        SetRecFilters();
        SetCaption();
    end;

    local procedure SalesTypeFilterOnAfterValidate()
    begin
        CurrPage.SaveRecord();
        SalesCodeFilter := '';
        SetRecFilters();
        SetCaption();
    end;

    local procedure StartingDateFilterOnAfterValid()
    begin
        CurrPage.SaveRecord();
        SetRecFilters();
    end;

    local procedure ItemTypeFilterOnAfterValidate()
    begin
        CurrPage.SaveRecord();
        CodeFilter := '';
        SetRecFilters();
    end;

    local procedure CodeFilterOnAfterValidate()
    begin
        CurrPage.SaveRecord();
        SetRecFilters();
        SetCaption();
    end;

    local procedure CurrencyCodeFilterOnAfterValid()
    begin
        CurrPage.SaveRecord();
        SetRecFilters();
    end;

    local procedure GetSalesTypeFilter(): Integer
    begin
        case Rec.GetFilter("Sales Type") of
            Format(Rec."Sales Type"::Customer):
                exit(0);
            Format(Rec."Sales Type"::"Customer Disc. Group"):
                exit(1);
            Format(Rec."Sales Type"::"All Customers"):
                exit(2);
            Format(Rec."Sales Type"::Campaign):
                exit(3);
        end;
    end;

    local procedure GetTypeFilter() TypeFilter: Integer
    begin
        case Rec.GetFilter(Type) of
            Format(Rec.Type::Item):
                exit(0);
            Format(Rec.Type::"Item Disc. Group"):
                exit(1);
            else
                OnGetTypeFilterCaseElse(Rec, TypeFilter);
        end;
    end;

    local procedure FilterLines()
    var
        FilterPageBuilder: FilterPageBuilder;
    begin
        FilterPageBuilder.AddTable(Rec.TableCaption, DATABASE::"Sales Line Discount");
        FilterPageBuilder.SetView(Rec.TableCaption, Rec.GetView());

        if Rec.GetFilter("Sales Type") = '' then
            FilterPageBuilder.AddFieldNo(Rec.TableCaption, Rec.FieldNo("Sales Type"));
        if Rec.GetFilter("Sales Code") = '' then
            FilterPageBuilder.AddFieldNo(Rec.TableCaption, Rec.FieldNo("Sales Code"));
        if Rec.GetFilter(Type) = '' then
            FilterPageBuilder.AddFieldNo(Rec.TableCaption, Rec.FieldNo(Type));
        if Rec.GetFilter(Code) = '' then
            FilterPageBuilder.AddFieldNo(Rec.TableCaption, Rec.FieldNo(Code));
        if Rec.GetFilter("Starting Date") = '' then
            FilterPageBuilder.AddFieldNo(Rec.TableCaption, Rec.FieldNo("Starting Date"));
        if Rec.GetFilter("Currency Code") = '' then
            FilterPageBuilder.AddFieldNo(Rec.TableCaption, Rec.FieldNo("Currency Code"));

        if FilterPageBuilder.RunModal() then
            Rec.SetView(FilterPageBuilder.GetView(Rec.TableCaption));

        UpdateBasicRecFilters();
        SetEditableFields();
    end;

    local procedure UpdateBasicRecFilters()
    begin
        if Rec.GetFilter("Sales Type") <> '' then
            SalesTypeFilter := GetSalesTypeFilter()
        else
            SalesTypeFilter := SalesTypeFilter::None;

        if Rec.GetFilter(Type) <> '' then
            ItemTypeFilter := GetTypeFilter()
        else
            ItemTypeFilter := ItemTypeFilter::None;

        SalesCodeFilter := Rec.GetFilter("Sales Code");
        CodeFilter := Rec.GetFilter(Code);
        CurrencyCodeFilter := Rec.GetFilter("Currency Code");
        Evaluate(StartingDateFilter, Rec.GetFilter("Starting Date"));
    end;

    local procedure SetEditableFields()
    begin
        SalesCodeEditable := Rec."Sales Type" <> Rec."Sales Type"::"All Customers";
    end;

    [IntegrationEvent(true, false)]
    local procedure OnLookupCodeFilterCaseElse(SalesLineDiscount: Record "Sales Line Discount"; var Text: Text; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnGetTypeFilterCaseElse(var SalesLineDiscount: Record "Sales Line Discount"; var TypeFilter: Integer)
    begin
    end;
}
