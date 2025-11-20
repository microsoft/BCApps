// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

using Microsoft.Finance.Currency;

page 150 "Setup Business Unit Currency"
{
    PageType = Card;
    SourceTable = "Business Unit";
    Caption = 'Setup Business Unit Currencies';
    SourceTableTemporary = true;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            field("Starting Date"; TempConsolidationProcess."Starting Date")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ToolTip = 'Specifies the starting date of the consolidation process.';
                Visible = ConsolidationProcessSet;
            }
            field("Ending Date"; TempConsolidationProcess."Ending Date")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ToolTip = 'Specifies the ending date of the consolidation process.';
                Visible = ConsolidationProcessSet;
            }
            field(CurrencyCode; Rec."Currency Code")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Currency Code';
                Editable = false;
                ToolTip = 'Specifies the currency code of the business unit.';
            }
            field("Currency Exchange Rate Table"; CurrencyExchangeRateTable)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Source of Exchange Rate';
                OptionCaption = 'Consolidation Company,Business Unit';
                ToolTip = 'Specifies the table that contains the exchange rates to use for the consolidation.';
                Editable = NeedsCurrencyTranslation;

                trigger OnValidate()
                begin
                    AnyValueChanged := true;
                end;
            }
            field(AverageCurrencyFactor; IncomeCurrencyFactor)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Average Currency Factor';
                ToolTip = 'Specifies the exchange rate to use for income statement accounts. Income statement G/L Entries from the business unit will be divided by this factor.';
                Editable = NeedsCurrencyTranslation;
                DecimalPlaces = 0 : 15;
                trigger OnDrillDown()
                begin
                    if not NeedsCurrencyTranslation then
                        exit;
                    AnyValueChanged := AnyValueChanged or ShowCurrencySelector(IncomeCurrencyFactor);
                end;

                trigger OnValidate()
                begin
                    if IncomeCurrencyFactor = 0 then
                        Error(ValueCantBeZeroErr);
                    AnyValueChanged := true;
                end;
            }
            field(ClosingCurrencyFactor; BalanceCurrencyFactor)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Closing Currency Factor';
                ToolTip = 'Specifies the exchange rate to use for balance accounts. Balance sheet G/L Entries from the business unit will be divided by this factor.';
                Editable = NeedsCurrencyTranslation;
                DecimalPlaces = 0 : 15;
                trigger OnDrillDown()
                begin
                    if not NeedsCurrencyTranslation then
                        exit;
                    AnyValueChanged := AnyValueChanged or ShowCurrencySelector(BalanceCurrencyFactor);
                end;

                trigger OnValidate()
                begin
                    if BalanceCurrencyFactor = 0 then
                        Error(ValueCantBeZeroErr);
                    AnyValueChanged := true;
                end;
            }
            group(Adjustment)
            {
                field(LastClosingCurrencyFactor; LastBalanceCurrencyFactor)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Last Closing Currency Factor';
                    ToolTip = 'Specifies the last closing currency factor used for the business unit. This is used to adjust the balance accounts with the new currency exchange rate. It is automatically filled after consolidating the business unit. ';
                    Editable = NeedsCurrencyTranslation;
                    DecimalPlaces = 0 : 15;

                    trigger OnDrillDown()
                    begin
                        if not NeedsCurrencyTranslation then
                            exit;
                        AnyValueChanged := AnyValueChanged or ShowCurrencySelector(LastBalanceCurrencyFactor);
                    end;

                    trigger OnValidate()
                    begin
                        if LastBalanceCurrencyFactor = 0 then
                            Error(ValueCantBeZeroErr);
                        AnyValueChanged := true;
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RevertChanges)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Revert';
                ToolTip = 'Revert to the original values.';
                Enabled = AnyValueChanged;
                Image = Undo;
                trigger OnAction()
                begin
                    SetEditableValuesFromBusinessUnit();
                    AnyValueChanged := false;
                end;
            }
            action(OpenExchangeRates)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Exchange Rates';
                Tooltip = 'See the exchange rates for this currency in the consolidation company.';
                Image = Currency;
                RunObject = page "Currency Exchange Rates";
                RunPageLink = "Currency Code" = field("Currency Code");
            }
            action(SelectFromPrevious)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Select from previous consolidations';
                ToolTip = 'Get the exchange rates used in previous consolidations.';
                Image = History;
                trigger OnAction()
                var
                    BusUnitInConsProcess: Record "Bus. Unit In Cons. Process";
                    PreviousExchangeRates: Page "Previous Exchange Rates";
                    ToCopy: Integer;
                    CopyAverageCurrencyFactor, CopyClosingCurrencyFactor, CopyLastClosingCurrencyFactor : Boolean;
                begin

                    PreviousExchangeRates.LookupMode(true);
                    PreviousExchangeRates.SetBusinessUnit(Rec);
                    if ConsolidationProcessSet then
                        PreviousExchangeRates.SetMaxEndingDate(TempConsolidationProcess."Ending Date");
                    if PreviousExchangeRates.RunModal() <> Action::LookupOK then
                        exit;
                    if not NeedsCurrencyTranslation then
                        exit;
                    PreviousExchangeRates.SetSelectionFilter(BusUnitInConsProcess);
                    if not BusUnitInConsProcess.FindFirst() then
                        exit;
                    ToCopy := StrMenu('All,Average Exchange Rate,Closing Exchange Rate, Last Closing Exchange Rate', 1, WhichExchangeRatesToCopyMsg);
                    if ToCopy = 0 then
                        exit;
                    CopyAverageCurrencyFactor := ToCopy in [1, 2];
                    CopyClosingCurrencyFactor := ToCopy in [1, 3];
                    CopyLastClosingCurrencyFactor := ToCopy in [1, 4];
                    if CopyAverageCurrencyFactor and (IncomeCurrencyFactor = 0) then
                        Error(ValueCantBeZeroErr);
                    if CopyAverageCurrencyFactor then
                        IncomeCurrencyFactor := BusUnitInConsProcess."Average Exchange Rate";
                    if CopyClosingCurrencyFactor and (BalanceCurrencyFactor = 0) then
                        Error(ValueCantBeZeroErr);
                    if CopyClosingCurrencyFactor then
                        BalanceCurrencyFactor := BusUnitInConsProcess."Closing Exchange Rate";
                    if CopyLastClosingCurrencyFactor and (LastBalanceCurrencyFactor = 0) then
                        Error(ValueCantBeZeroErr);
                    if CopyLastClosingCurrencyFactor then
                        LastBalanceCurrencyFactor := BusUnitInConsProcess."Last Closing Exchange Rate";
                    CurrencyExchangeRateTable := BusUnitInConsProcess."Currency Exchange Rate Table";
                    AnyValueChanged := true;
                end;
            }
        }
        area(Promoted)
        {
            actionref(RevertChanges_Promoted; RevertChanges)
            {
            }
            actionref(OpenExchangeRates_Promoted; OpenExchangeRates)
            {
            }
            actionref(SelectFromPrevious_Promoted; SelectFromPrevious)
            {
            }
        }
    }

    trigger OnOpenPage()
    begin
        NotifyAboutPreviousExchangeRatePage();
        SetNeedsCurrencyTranslation();
    end;

    local procedure SetNeedsCurrencyTranslation()
    begin
        if Rec."Currency Code" = '' then begin
            NeedsCurrencyTranslation := false;
            exit;
        end;
        if not ConsolidationProcessSet then begin
            NeedsCurrencyTranslation := Rec."Currency Code" <> ConsolidationCurrency.GetCurrentCompanyCurrencyCode();
            exit;
        end;
        NeedsCurrencyTranslation := ConsolidationCurrency.GetConsolidationCompanyCurrencyCode(TempConsolidationProcess) <> Rec."Currency Code";
    end;

    local procedure NotifyAboutPreviousExchangeRatePage()
    var
        BusUnitInConsProcess: Record "Bus. Unit In Cons. Process";
        Notification: Notification;
    begin
        if not ConsolidationProcessSet then
            exit;
        BusUnitInConsProcess.SetRange("Business Unit Code", Rec.Code);
        BusUnitInConsProcess.SetRange("Ending Date", TempConsolidationProcess."Starting Date", TempConsolidationProcess."Ending Date");
        if BusUnitInConsProcess.IsEmpty() then
            exit;
        Notification.Message := YouHaveRunConsolidationForBusinessUnitBeforeMsg;
        Notification.Send();
    end;

    internal procedure SetConsolidationProcess(var ConsolidationProcess: Record "Consolidation Process")
    begin
        TempConsolidationProcess.DeleteAll();
        TempConsolidationProcess := ConsolidationProcess;
        TempConsolidationProcess.Insert();
        ConsolidationProcessSet := true;
    end;

    internal procedure SetBusinessUnit(var BusinessUnit: Record "Business Unit")
    begin
        Rec.Copy(BusinessUnit);
        SetEditableValuesFromBusinessUnit();
        Rec.Insert();
    end;

    internal procedure GetIncomeCurrencyFactor(): Decimal
    begin
        exit(IncomeCurrencyFactor);
    end;

    internal procedure GetBalanceCurrencyFactor(): Decimal
    begin
        exit(BalanceCurrencyFactor);
    end;

    internal procedure GetLastBalanceCurrencyFactor(): Decimal
    begin
        exit(LastBalanceCurrencyFactor);
    end;

    internal procedure GetCurrencyExchangeRateTable(): Option
    begin
        exit(CurrencyExchangeRateTable);
    end;

    var
        TempConsolidationProcess: Record "Consolidation Process" temporary;
        ConsolidationCurrency: Codeunit "Consolidation Currency";
        BalanceCurrencyFactor, LastBalanceCurrencyFactor, IncomeCurrencyFactor : Decimal;
        CurrencyExchangeRateTable: Option "Local","Business Unit";
        NeedsCurrencyTranslation, ConsolidationProcessSet, AnyValueChanged : Boolean;
        ValueCantBeZeroErr: Label 'Please enter a value different from zero.';
        YouHaveRunConsolidationForBusinessUnitBeforeMsg: Label 'You have run a consolidation for this business unit for these dates before. You can use the action "Select from previous consolidations" to set the exchange rates as you used them before.';
        WhichExchangeRatesToCopyMsg: Label 'Which exchange rates do you want to copy from the selected consolidation? The current values will be overwritten.';

    local procedure ShowCurrencySelector(var Factor: Decimal) ValueChanged: Boolean
    var
        CurrencyFactorSelector: Page "Currency Factor Selector";
        NewFactor: Decimal;
    begin
        CurrencyFactorSelector.LookupMode(true);
        if ConsolidationProcessSet then
            CurrencyFactorSelector.SetConsolidationCurrencyCode(ConsolidationCurrency.GetConsolidationCompanyCurrencyCode(TempConsolidationProcess))
        else
            CurrencyFactorSelector.SetConsolidationCurrencyCode(ConsolidationCurrency.GetCurrentCompanyCurrencyCode());
        CurrencyFactorSelector.SetBusinessUnitCurrencyCode(Rec."Currency Code");
        CurrencyFactorSelector.SetCurrencyFactor(Factor);
        if CurrencyFactorSelector.RunModal() <> Action::LookupOK then
            exit;
        NewFactor := CurrencyFactorSelector.GetCurrencyFactor();
        ValueChanged := NewFactor <> Factor;
        Factor := NewFactor;
    end;

    local procedure SetEditableValuesFromBusinessUnit()
    begin
        CurrencyExchangeRateTable := Rec."Currency Exchange Rate Table";
        BalanceCurrencyFactor := Rec."Balance Currency Factor";
        IncomeCurrencyFactor := Rec."Income Currency Factor";
        LastBalanceCurrencyFactor := Rec."Last Balance Currency Factor";
    end;

}
