// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Inventory.Item;
using Microsoft.Purchases.Vendor;
using System.Text;

page 665 "Purchase Prepmt. Percentages"
{
    Caption = 'Purchase Prepmt. Percentages';
    DataCaptionExpression = Caption();
    DelayedInsert = true;
    PageType = Worksheet;
    SourceTable = "Purchase Prepayment %";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(VendNoFilter; VendNoFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor No. Filter';
                    ToolTip = 'Specifies a filter for which purchase prepayment percentages display.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        VendList: Page "Vendor List";
                    begin
                        VendList.LookupMode := true;
                        if VendList.RunModal() <> ACTION::LookupOK then
                            exit(false);
                        Text := VendList.GetSelectionFilter();
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        VendNoFilterOnAfterValidate();
                    end;
                }
                field(CodeFilterCtrl; ItemNoFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item No. Filter';
                    ToolTip = 'Specifies a filter which applies.';

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
                    ToolTip = 'Specifies a starting date filter for which purchase prepayment percentages will display.';

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
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the vendor that the prepayment percentage for this item is valid for.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the item for which the prepayment percentage is valid.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Prepayments;
                    ToolTip = 'Specifies the date from which the purchase prepayment percentage is valid.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Prepayments;
                    ToolTip = 'Specifies the date to which the purchase prepayment percentage is valid.';
                }
                field("Prepayment %"; Rec."Prepayment %")
                {
                    ApplicationArea = Prepayments;
                    ToolTip = 'Specifies the prepayment percentage to use to calculate the prepayment for purchases.';
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

    trigger OnOpenPage()
    begin
        GetRecFilters();
        SetRecFilters();
    end;

    var
        VendNoFilter: Text;
        ItemNoFilter: Text;
        StartingDateFilter: Text[30];

    local procedure SetEditable()
    begin
    end;

    local procedure GetRecFilters()
    begin
        if Rec.HasFilter then begin
            VendNoFilter := Rec.GetFilter("Vendor No.");
            ItemNoFilter := Rec.GetFilter("Item No.");
            Evaluate(StartingDateFilter, Rec.GetFilter("Starting Date"));
        end;
    end;

    procedure SetRecFilters()
    begin
        if VendNoFilter <> '' then
            Rec.SetFilter("Vendor No.", VendNoFilter)
        else
            Rec.SetRange("Vendor No.");

        if StartingDateFilter <> '' then
            Rec.SetFilter("Starting Date", StartingDateFilter)
        else
            Rec.SetRange("Starting Date");

        if ItemNoFilter <> '' then
            Rec.SetFilter("Item No.", ItemNoFilter)
        else
            Rec.SetRange("Item No.");

        CurrPage.Update(false);
    end;

    procedure Caption(): Text
    var
        Item: Record Item;
        Vend: Record Vendor;
        ItemNoCaption: Text;
        PurchaseCodeCaption: Text;
    begin
        if ItemNoFilter <> '' then begin
            ItemNoCaption := StrSubstNo('%1 %2', Item.TableCaption(), ItemNoFilter);
            if Item.Get(CopyStr(ItemNoFilter, 1, MaxStrLen(Item."No."))) then
                ItemNoCaption := ItemNoCaption + ' - ' + Item.Description;
        end;

        PurchaseCodeCaption := StrSubstNo('%1 %2', Vend.TableCaption(), VendNoFilter);
        if Vend.Get(CopyStr(VendNoFilter, 1, MaxStrLen(Vend."No."))) then
            PurchaseCodeCaption := PurchaseCodeCaption + ' - ' + Vend.Name;

        exit(DelChr(ItemNoCaption + ' ' + PurchaseCodeCaption, '<>'))
    end;

    local procedure VendNoFilterOnAfterValidate()
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

