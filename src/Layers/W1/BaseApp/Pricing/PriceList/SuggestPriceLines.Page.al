// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.PriceList;

page 7021 "Suggest Price Lines"
{
    Caption = 'Price Lines';
    PageType = StandardDialog;
    SourceTable = "Price Line Filters";
    DataCaptionExpression = DataCaption;

    layout
    {
        area(content)
        {
            group(All)
            {
                ShowCaption = false;
                group(Line)
                {
                    ShowCaption = false;
                    Visible = CopyLines;
                    field("From Price List Code"; Rec."From Price List Code")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'From Price List';

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            PriceListHeader: Record "Price List Header";
                            PriceUXManagement: Codeunit "Price UX Management";
                        begin
                            PriceListHeader.Get(Rec."To Price List Code");
                            Rec."From Price List Code" := Rec."To Price List Code";
                            if PriceUXManagement.LookupPriceLists(
                                PriceListHeader."Source Group", PriceListHeader."Price Type", Rec."From Price List Code")
                            then begin
                                PriceListHeader.Get(Rec."From Price List Code");
                                Rec.Validate("From Price List Code");
                                CurrPage.Update(true);
                            end;
                        end;

                        trigger OnValidate()
                        begin
                            CurrPage.Update(true);
                        end;
                    }
                    field("Price Line Filter"; GetReadablePriceLineFilter())
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Price Line Filter';
                        ToolTip = 'Specifies the filters applied to the product table.';
                        Editable = false;

                        trigger OnAssistEdit()
                        begin
                            Rec.EditPriceLineFilter();
                            CurrPage.Update(true);
                        end;
                    }
                    field("Copy As New Lines"; Rec."Copy As New Lines")
                    {
                        ApplicationArea = Basic, Suite;
                        Visible = CopyToWorksheet;
                        Editable = CreateNewLinesEditable;
                        trigger OnValidate()
                        begin
                            ShowDefaults := Rec."Copy As New Lines" or not Rec."Copy Lines";
                            CurrPage.Update(true);
                        end;
                    }
                }
                group(Product)
                {
                    ShowCaption = false;
                    Visible = not CopyLines;
                    field("Product Type"; Rec."Asset Type")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Product Type';
                    }
                    field("Product Filter"; GetReadableAssetFilter())
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Product Filter';
                        ToolTip = 'Specifies the filters applied to the product table.';
                        Editable = false;

                        trigger OnAssistEdit()
                        begin
                            Rec.EditAssetFilter();
                            CurrPage.SaveRecord();
                        end;
                    }
                }
                group(DefaultsGroup)
                {
                    ShowCaption = false;
                    Visible = ShowDefaults;
                    field(Defaults; Defaults)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        Caption = 'Defaults';
                        ToolTip = 'Specifies the fields of the price list header that is used as defaults for new lines created in the worksheet.';
                        trigger OnDrillDown()
                        begin
                            ShowPriceListFilters();
                        end;
                    }
                }
                group(ForceDefaultsGroup)
                {
                    ShowCaption = false;
                    Visible = ShowForceDefaults;
                    field("Force Defaults"; Rec."Force Defaults")
                    {
                        ApplicationArea = Basic, Suite;
                    }
                }
                group(Options)
                {
                    Caption = 'Options';
                    field("Minimum Quantity"; Rec."Minimum Quantity")
                    {
                        ApplicationArea = Basic, Suite;
                        Visible = not CopyLines;
                        Caption = 'Minimum Quantity';
                    }
                    group(Adjustment)
                    {
                        ShowCaption = false;
                        field("Exchange Rate Date"; Rec."Exchange Rate Date")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Exchange Rate Date';
                        }
                    }
                    field("Adjustment Factor"; Rec."Adjustment Factor")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Adjustment Factor';
                    }
                    field("Rounding Method Code"; Rec."Rounding Method Code")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Rounding Method';
                    }
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        PriceListHeader: Record "Price List Header";
    begin
        if not Rec."Update Multiple Price Lists" then begin
            Rec."Copy As New Lines" := true;
            CreateNewLinesEditable := false;
        end else
            CreateNewLinesEditable := true;
        Rec.Insert();

        if Rec."To Price List Code" <> '' then
            if PriceListHeader.Get(Rec."To Price List Code") then
                if Defaults = '' then begin
                    TempDefaultsPriceListHeader := PriceListHeader;
                    Defaults := GetDefaults();
                end;

        if not Rec."Copy Lines" then
            ShowForceDefaults := false
        else
            if PriceListHeader.Code <> '' then
                ShowForceDefaults := PriceListHeader."Allow Updating Defaults"
            else
                ShowForceDefaults := true;

        CopyLines := Rec."Copy Lines";
        CopyToWorksheet := Rec."Copy Lines" and Rec.Worksheet;
        ShowDefaults := (Rec."Copy As New Lines" or not Rec."Copy Lines") and Rec.Worksheet;
        if CopyLines then
            DataCaption := DataCaptionCopyLbl
        else
            DataCaption := DataCaptionSuggestLbl;
    end;

    var
        TempDefaultsPriceListHeader: Record "Price List Header" temporary;
        Defaults: Text;
        DataCaption: Text;
        DataCaptionCopyLbl: Label 'Copy existing';
        DataCaptionSuggestLbl: Label 'Create new';
        DefaultsLbl: Label '%1 = %2; ', Locked = true;
        CopyToWorksheet: Boolean;
        ShowForceDefaults: Boolean;
        ShowDefaults: Boolean;
        CreateNewLinesEditable: Boolean;
        CopyLines: Boolean;

    procedure GetDefaults(var PriceListHeader: Record "Price List Header")
    begin
        PriceListHeader := TempDefaultsPriceListHeader;
    end;

    local procedure GetDefaults() Result: Text
    begin
        Result := GetDefaults(TempDefaultsPriceListHeader.FieldCaption("Source Type"), Format(TempDefaultsPriceListHeader."Source Type"), true);
        Result += GetDefaults(TempDefaultsPriceListHeader.FieldCaption("Parent Source No."), TempDefaultsPriceListHeader."Parent Source No.", false);
        Result += GetDefaults(TempDefaultsPriceListHeader.FieldCaption("Source No."), TempDefaultsPriceListHeader."Source No.", false);
        Result += GetDefaults(TempDefaultsPriceListHeader.FieldCaption("Currency Code"), TempDefaultsPriceListHeader."Currency Code", false);
        Result += GetDefaults(TempDefaultsPriceListHeader.FieldCaption("Starting Date"), format(TempDefaultsPriceListHeader."Starting Date"), false);
        Result += GetDefaults(TempDefaultsPriceListHeader.FieldCaption("Ending Date"), format(TempDefaultsPriceListHeader."Ending Date"), false);

        OnAfterGetDefaults(Result, TempDefaultsPriceListHeader);
    end;

    local procedure GetDefaults(FldName: Text; FldValue: Text; ShowBlank: Boolean): Text;
    begin
        if ShowBlank or (FldValue <> '') then
            exit(StrSubstNo(DefaultsLbl, FldName, FldValue))
    end;

    procedure SetDefaults(PriceListHeader: Record "Price List Header")
    begin
        TempDefaultsPriceListHeader := PriceListHeader;
        Defaults := GetDefaults();
    end;

    local procedure GetReadableAssetFilter() Result: Text
    var
        RecRef: RecordRef;
    begin
        if Rec."Asset Filter" = '' then
            exit('');
        RecRef.Open(Rec."Table ID");
        RecRef.SetView(Rec."Asset Filter");
        Result := RecRef.GetView(true);
        RecRef.Close();
    end;

    local procedure GetReadablePriceLineFilter(): Text
    var
        PriceListLine: Record "Price List Line";
    begin
        if Rec."Price Line Filter" = '' then
            exit('');
        PriceListLine.SetView(Rec."Price Line Filter");
        exit(PriceListLine.GetView(true));
    end;

    local procedure ShowPriceListFilters()
    var
        PriceListFilters: Page "Price List Filters";
    begin
        PriceListFilters.Set(TempDefaultsPriceListHeader);
        PriceListFilters.LookupMode(true);
        if PriceListFilters.RunModal() = Action::LookupOK then begin
            PriceListFilters.GetRecord(TempDefaultsPriceListHeader);
            Defaults := GetDefaults();
            CurrPage.Update(true);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetDefaults(var Result: Text; TempDefaultsPriceListHeader: Record "Price List Header")
    begin
    end;
}