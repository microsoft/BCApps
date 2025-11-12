// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Inventory.Item;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Pricing;
using System.Text;

page 664 "Sales Prepayment Percentages"
{
    Caption = 'Sales Prepayment Percentages';
    DataCaptionExpression = Caption();
    DelayedInsert = true;
    PageType = Worksheet;
    SourceTable = "Sales Prepayment %";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(SalesTypeFilter; SalesTypeFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Type Filter';
                    OptionCaption = 'Customer,Customer Price Group,All Customers,None';
                    ToolTip = 'Specifies if the sales prepayments apply to customers or price groups.';

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
                    ToolTip = 'Specifies a filter for the customer or price group that the prepayment percentages apply to.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        CustList: Page "Customer List";
                        CustPriceGrList: Page "Customer Price Groups";
                    begin
                        if SalesTypeFilter = SalesTypeFilter::"All Customers" then
                            exit;

                        case SalesTypeFilter of
                            SalesTypeFilter::Customer:
                                begin
                                    CustList.LookupMode := true;
                                    if CustList.RunModal() = ACTION::LookupOK then begin
                                        Text := CustList.GetSelectionFilter();
                                        exit(true);
                                    end;
                                end;
                            SalesTypeFilter::"Customer Price Group":
                                begin
                                    CustPriceGrList.LookupMode := true;
                                    if CustPriceGrList.RunModal() = ACTION::LookupOK then begin
                                        Text := CustPriceGrList.GetSelectionFilter();
                                        exit(true);
                                    end;
                                end;
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        SalesCodeFilterOnAfterValidate();
                    end;
                }
                field(CodeFilterCtrl; ItemNoFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item No. Filter';
                    Enabled = CodeFilterCtrlEnable;
                    ToolTip = 'Specifies a filter for the items that the prepayment percentages apply to.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ItemList: Page "Item List";
                    begin
                        ItemList.LookupMode := true;
                        if ItemList.RunModal() = ACTION::LookupOK then begin
                            Text := ItemList.GetSelectionFilter();
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        ItemNoFilterOnAfterValidate();
                    end;
                }
                field(StartingDateFilter; StartingDateFilter)
                {
                    ApplicationArea = Prepayments;
                    Caption = 'Starting Date Filter';
                    ToolTip = 'Specifies a filter for the starting date of the prepayment percentages.';

                    trigger OnValidate()
                    var
                        FilterTokens: Codeunit "Filter Tokens";
                    begin
                        FilterTokens.MakeDateFilter(StartingDateFilter);
                        StartingDateFilterOnAfterValid();
                    end;
                }
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Sales Type"; Rec."Sales Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sales type of the prepayment percentage.';

                    trigger OnValidate()
                    begin
                        SalesTypeOnAfterValidate();
                    end;
                }
                field("Sales Code"; Rec."Sales Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = SalesCodeEditable;
                    ToolTip = 'Specifies the code that belongs to the sales type.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the item for which the prepayment percentage is valid.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Prepayments;
                    ToolTip = 'Specifies the date from which the prepayment percentage is valid.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Prepayments;
                    ToolTip = 'Specifies the date to which the prepayment percentage is valid.';
                }
                field("Prepayment %"; Rec."Prepayment %")
                {
                    ApplicationArea = Prepayments;
                    ToolTip = 'Specifies the prepayment percentage to use to calculate the prepayment for sales.';
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
    }

    trigger OnAfterGetCurrRecord()
    begin
        SetEditable();
    end;

    trigger OnInit()
    begin
        CodeFilterCtrlEnable := true;
        SalesCodeFilterCtrlEnable := true;
        SalesCodeEditable := true;
    end;

    trigger OnOpenPage()
    begin
        GetRecFilters();
        SetRecFilters();
    end;

    var
        SalesTypeFilter: Option Customer,"Customer Price Group","All Customers","None";
        SalesCodeFilter: Text;
        ItemNoFilter: Text;
        StartingDateFilter: Text[30];
        SalesCodeEditable: Boolean;
        SalesCodeFilterCtrlEnable: Boolean;
        CodeFilterCtrlEnable: Boolean;

    local procedure SetEditable()
    begin
        SalesCodeEditable := Rec."Sales Type" <> Rec."Sales Type"::"All Customers";
    end;

    local procedure GetRecFilters()
    begin
        if Rec.HasFilter then begin
            if Rec.GetFilter("Sales Type") <> '' then
                SalesTypeFilter := Rec."Sales Type"
            else
                SalesTypeFilter := SalesTypeFilter::None;

            SalesCodeFilter := Rec.GetFilter("Sales Code");
            ItemNoFilter := Rec.GetFilter("Item No.");
            Evaluate(StartingDateFilter, Rec.GetFilter("Starting Date"));
        end;
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

        if ItemNoFilter <> '' then
            Rec.SetFilter("Item No.", ItemNoFilter)
        else
            Rec.SetRange("Item No.");

        if StartingDateFilter <> '' then
            Rec.SetFilter("Starting Date", StartingDateFilter)
        else
            Rec.SetRange("Starting Date");

        CurrPage.Update(false);
    end;

    procedure Caption(): Text
    var
        Item: Record Item;
        Cust: Record Customer;
        CustPriceGr: Record "Customer Price Group";
        ItemNoCaption: Text;
        SalesCodeCaption: Text;
    begin
        if ItemNoFilter <> '' then begin
            ItemNoCaption := StrSubstNo('%1 %2', Item.TableCaption(), ItemNoFilter);
            if Item.Get(CopyStr(ItemNoFilter, 1, MaxStrLen(Item."No."))) then
                ItemNoCaption := ItemNoCaption + ' - ' + Item.Description;
        end;

        case SalesTypeFilter of
            SalesTypeFilter::Customer:
                begin
                    SalesCodeCaption := StrSubstNo('%1 %2', Cust.TableCaption(), SalesCodeFilter);
                    if Cust.Get(CopyStr(SalesCodeFilter, 1, MaxStrLen(Cust."No."))) then
                        SalesCodeCaption := SalesCodeCaption + ' - ' + Cust.Name;
                end;
            SalesTypeFilter::"Customer Price Group":
                begin
                    SalesCodeCaption := StrSubstNo('%1 %2', CustPriceGr.TableCaption(), SalesCodeFilter);
                    if CustPriceGr.Get(CopyStr(SalesCodeFilter, 1, MaxStrLen(CustPriceGr.Code))) then
                        SalesCodeCaption := SalesCodeCaption + ' - ' + CustPriceGr.Description;
                end;
            SalesTypeFilter::"All Customers":
                SalesCodeCaption := Format(SalesTypeFilter);
        end;

        exit(DelChr(ItemNoCaption + ' ' + SalesCodeCaption, '<>'))
    end;

    local procedure SalesTypeOnAfterValidate()
    begin
        SetEditable();
    end;

    local procedure SalesTypeFilterOnAfterValidate()
    begin
        CurrPage.SaveRecord();
        SalesCodeFilter := '';
        SetRecFilters();
    end;

    local procedure SalesCodeFilterOnAfterValidate()
    begin
        CurrPage.SaveRecord();
        SetRecFilters();
    end;

    local procedure StartingDateFilterOnAfterValid()
    begin
        CurrPage.SaveRecord();
        SetRecFilters();
    end;

    local procedure ItemNoFilterOnAfterValidate()
    begin
        CurrPage.SaveRecord();
        SetRecFilters();
    end;
}

