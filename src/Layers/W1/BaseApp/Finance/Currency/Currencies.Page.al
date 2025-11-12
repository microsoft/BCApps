// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Currency;

using Microsoft.Finance.GeneralLedger.Reports;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Integration.Dataverse;
using System.Text;

page 5 Currencies
{
    AdditionalSearchTerms = 'Multiple Foreign Currencies, Monetary Page, Exchange Page, Forex Overview, Money Page, Cash Page, Trade Currencies, Financial Unit Page, Transaction Money Page, Business Currency Page, Capital Type Page';
    ApplicationArea = Suite;
    Caption = 'Currencies';
    CardPageID = "Currency Card";
    PageType = List;
    AboutTitle = 'About Currencies';
    AboutText = 'Set up and manage currency codes, exchange rates, rounding rules, and related general ledger accounts to support transactions and financial reporting in multiple currencies.';
    SourceTable = Currency;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a currency code that you can select. The code must comply with ISO 4217.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a text to describe the currency code.';
                }
                field("ISO Code"; Rec."ISO Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a three-letter currency code defined in ISO 4217.';
                }
                field("ISO Numeric Code"; Rec."ISO Numeric Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a three-digit code number defined in ISO 4217.';
                }
                field(Symbol; Rec.Symbol)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the symbol for the currency, for example, $ for US dollars.';
                }
                field(CurrencySymbolPosition; Rec."Currency Symbol Position")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the position of the currency symbol in relation to the amount.';
                    Caption = 'Currency Symbol Position';
                    importance = Additional;
                }

                field(ExchangeRateDate; ExchangeRateDate)
                {
                    ApplicationArea = Suite;
                    Caption = 'Exchange Rate Date';
                    Editable = false;
                    ToolTip = 'Specifies the date of the exchange rate in the Exchange Rate field. You can update the rate by choosing the Update Exchange Rates button.';

                    trigger OnDrillDown()
                    begin
                        DrillDownActionOnPage();
                    end;
                }
                field(ExchangeRateAmt; ExchangeRateAmt)
                {
                    ApplicationArea = Suite;
                    Caption = 'Exchange Rate';
                    DecimalPlaces = 0 : 7;
                    Editable = false;
                    ToolTip = 'Specifies the currency exchange rate. You can update the rate by choosing the Update Exchange Rates button.';

                    trigger OnDrillDown()
                    begin
                        DrillDownActionOnPage();
                    end;
                }
                field("EMU Currency"; Rec."EMU Currency")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies whether the currency is an EMU currency, for example DEM or EUR.';
                }
                field("Realized Gains Acc."; Rec."Realized Gains Acc.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the general ledger account number to which realized exchange rate gains will be posted.';
                }
                field("Realized Losses Acc."; Rec."Realized Losses Acc.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the general ledger account number to which realized exchange rate losses will be posted.';
                }
                field("Unrealized Gains Acc."; Rec."Unrealized Gains Acc.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the general ledger account number to which unrealized exchange rate gains will be posted when the Adjust Exchange Rates batch job is run.';
                }
                field("Unrealized Losses Acc."; Rec."Unrealized Losses Acc.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the general ledger account number to which unrealized exchange rate losses will be posted when the Adjust Exchange Rates batch job is run.';
                }
                field("Realized G/L Gains Account"; Rec."Realized G/L Gains Account")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the general ledger account to post exchange rate gains to for currency adjustments between LCY and the additional reporting currency.';
                    Visible = false;
                }
                field("Realized G/L Losses Account"; Rec."Realized G/L Losses Account")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the general ledger account to post exchange rate gains to for currency adjustments between LCY and the additional reporting currency.';
                    Visible = false;
                }
                field("Residual Gains Account"; Rec."Residual Gains Account")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the general ledger account to post residual amount gains to, if you post in the general ledger application area in both LCY and an additional reporting currency.';
                    Visible = false;
                }
                field("Residual Losses Account"; Rec."Residual Losses Account")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the general ledger account to post residual amount losses to, if you post in the general ledger application area in both LCY and an additional reporting currency.';
                    Visible = false;
                }
                field("Amount Rounding Precision"; Rec."Amount Rounding Precision")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the size of the interval to be used when rounding amounts in this currency.';
                }
                field("Amount Decimal Places"; Rec."Amount Decimal Places")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of decimal places the program will display for amounts in this currency.';
                }
                field("Invoice Rounding Precision"; Rec."Invoice Rounding Precision")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the size of the interval to be used when rounding amounts in this currency. You can specify invoice rounding for each currency in the Currency table.';
                }
                field("Invoice Rounding Type"; Rec."Invoice Rounding Type")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies whether an invoice amount will be rounded up or down. The program uses this information together with the interval for rounding that you have specified in the Invoice Rounding Precision field.';
                }
                field("Unit-Amount Rounding Precision"; Rec."Unit-Amount Rounding Precision")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the size of the interval to be used when rounding unit amounts (that is, item prices per unit) in this currency.';
                }
                field("Unit-Amount Decimal Places"; Rec."Unit-Amount Decimal Places")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of decimal places the program will display for amounts in this currency.';
                }
                field("Appln. Rounding Precision"; Rec."Appln. Rounding Precision")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the size of the interval that will be allowed as a rounding difference when you apply entries in different currencies to one another.';
                }
                field("Conv. LCY Rndg. Debit Acc."; Rec."Conv. LCY Rndg. Debit Acc.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies conversion information that must also contain a debit account if you wish to insert correction lines for rounding differences in the general journals using the Insert Conv. LCY Rndg. Lines function.';
                }
                field("Conv. LCY Rndg. Credit Acc."; Rec."Conv. LCY Rndg. Credit Acc.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies conversion information that must also contain a credit account if you wish to insert correction lines for rounding differences in the general journals using the Insert Conv. LCY Rndg. Lines function.';
                }
                field("Max. VAT Difference Allowed"; Rec."Max. VAT Difference Allowed")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the maximum VAT correction amount allowed for the currency.';
                    Visible = false;
                }
                field("VAT Rounding Type"; Rec."VAT Rounding Type")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how the program will round VAT when calculated for this currency.';
                    Visible = false;
                }
                field("Last Date Adjusted"; Rec."Last Date Adjusted")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies when the exchange rates were last adjusted, that is, the last date on which the Adjust Exchange Rates batch job was run.';
                }
                field("Last Date Modified"; Rec."Last Date Modified")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the last date on which any information in the Currency table was modified.';
                }
                field("Payment Tolerance %"; Rec."Payment Tolerance %")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the percentage that the payment or refund is allowed to be, less than the amount on the invoice or credit memo.';
                }
                field("Max. Payment Tolerance Amount"; Rec."Max. Payment Tolerance Amount")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the maximum allowed amount that the payment or refund can differ from the amount on the invoice or credit memo.';
                }
                field(CurrencyFactor; CurrencyFactor)
                {
                    ApplicationArea = Suite;
                    Caption = 'Currency Factor';
                    DecimalPlaces = 1 : 6;
                    ToolTip = 'Specifies the relationship between the additional reporting currency and the local currency. Amounts are recorded in both LCY and the additional reporting currency, using the relevant exchange rate and the currency factor.';

                    trigger OnValidate()
                    var
                        CurrencyExchangeRate: Record "Currency Exchange Rate";
                    begin
                        CurrencyExchangeRate.SetCurrentCurrencyFactor(Rec.Code, CurrencyFactor);
                    end;
                }
                field("Coupled to Dataverse"; Rec."Coupled to Dataverse")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies that the currency is coupled to a currency in Dataverse.';
                    Visible = CRMIntegrationEnabled or CDSIntegrationEnabled;
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
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Change Payment &Tolerance")
                {
                    ApplicationArea = Suite;
                    Caption = 'Change Payment &Tolerance';
                    Image = ChangePaymentTolerance;
                    ToolTip = 'Change either or both the maximum payment tolerance and the payment tolerance percentage and filters by currency.';

                    trigger OnAction()
                    var
                        ChangePmtTol: Report "Change Payment Tolerance";
                    begin
                        ChangePmtTol.SetCurrency(Rec);
                        ChangePmtTol.RunModal();
                    end;
                }
                action(SuggestAccounts)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Suggest Accounts';
                    Image = Default;
                    ToolTip = 'Suggest G/L Accounts for the selected currency. Suggestions will be based on similar setups and provide a quick setup that you can adjust to your business needs. If no similar setups exists no suggestion will be provided.';

                    trigger OnAction()
                    begin
                        Rec.SuggestSetupAccounts();
                    end;
                }
            }
            action("Exch. &Rates")
            {
                ApplicationArea = Suite;
                Caption = 'Exch. &Rates';
                Image = CurrencyExchangeRates;
                RunObject = Page "Currency Exchange Rates";
                RunPageLink = "Currency Code" = field(Code);
                ToolTip = 'View updated exchange rates for the currencies that you use.';
            }
            action("Adjust Exchange Rate")
            {
                ApplicationArea = Suite;
                Caption = 'Adjust Exchange Rate';
                Image = AdjustExchangeRates;
                RunObject = Codeunit "Exch. Rate Adjmt. Run Handler";
                ToolTip = 'Adjust general ledger, customer, vendor, and bank account entries to reflect a more updated balance if the exchange rate has changed since the entries were posted.';
            }
            action("Exchange Rate Adjust. Register")
            {
                ApplicationArea = Suite;
                Caption = 'Exchange Rate Adjust. Register';
                Image = ExchangeRateAdjustRegister;
                RunObject = Page "Exchange Rate Adjmt. Register";
                RunPageLink = "Currency Code" = field(Code);
                ToolTip = 'View the results of running the Adjust Exchange Rates batch job. One line is created for each currency or each combination of currency and posting group that is included in the adjustment.';
            }
            action("Exchange Rate Services")
            {
                ApplicationArea = Suite;
                Caption = 'Exchange Rate Services';
                Image = Web;
                RunObject = Page "Curr. Exch. Rate Service List";
                ToolTip = 'View or edit the setup of the services that are set up to fetch updated currency exchange rates when you choose the Update Exchange Rates action.';
            }
            action(UpdateExchangeRates)
            {
                ApplicationArea = Suite;
                Caption = 'Update Exchange Rates';
                Image = UpdateXML;
                RunObject = Codeunit "Update Currency Exchange Rates";
                ToolTip = 'Get the latest currency exchange rates from a service provider.';
            }
        }
        area(reporting)
        {
            action("Foreign Currency Balance")
            {
                ApplicationArea = Suite;
                Caption = 'Foreign Currency Balance';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Foreign Currency Balance";
                ToolTip = 'View the balances for all customers and vendors in both foreign currencies and in local currency (LCY). The report displays two LCY balances. One is the foreign currency balance converted to LCY by using the exchange rate at the time of the transaction. The other is the foreign currency balance converted to LCY by using the exchange rate of the work date.';
            }
        }
        area(navigation)
        {
            group(ActionGroupCRM)
            {
                Caption = 'Dataverse';
                Image = Administration;
                Visible = CRMIntegrationEnabled or CDSIntegrationEnabled;
                action(CRMGotoTransactionCurrency)
                {
                    ApplicationArea = Suite;
                    Caption = 'Transaction Currency';
                    Image = CoupledCurrency;
                    ToolTip = 'Open the coupled Dataverse transaction currency.';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.ShowCRMEntityFromRecordID(Rec.RecordId);
                    end;
                }
                action(CRMSynchronizeNow)
                {
                    AccessByPermission = TableData "CRM Integration Record" = IM;
                    ApplicationArea = Suite;
                    Caption = 'Synchronize';
                    Image = Refresh;
                    ToolTip = 'Send updated data to Dataverse.';

                    trigger OnAction()
                    var
                        Currency: Record Currency;
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        CurrencyRecordRef: RecordRef;
                    begin
                        CurrPage.SetSelectionFilter(Currency);
                        Currency.Next();

                        if Currency.Count = 1 then
                            CRMIntegrationManagement.UpdateOneNow(Currency.RecordId)
                        else begin
                            CurrencyRecordRef.GetTable(Currency);
                            CRMIntegrationManagement.UpdateMultipleNow(CurrencyRecordRef);
                        end
                    end;
                }
                group(Coupling)
                {
                    Caption = 'Coupling', Comment = 'Coupling is a noun';
                    Image = LinkAccount;
                    ToolTip = 'Create, change, or delete a coupling between the Business Central record and a Dataverse record.';
                    action(ManageCRMCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = IM;
                        ApplicationArea = Suite;
                        Caption = 'Set Up Coupling';
                        Image = LinkAccount;
                        ToolTip = 'Create or modify the coupling to a Dataverse Transaction Currency.';

                        trigger OnAction()
                        var
                            CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        begin
                            CRMIntegrationManagement.DefineCoupling(Rec.RecordId);
                        end;
                    }
                    action(MatchBasedCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = IM;
                        ApplicationArea = Suite;
                        Caption = 'Match-Based Coupling';
                        Image = CoupledCurrency;
                        ToolTip = 'Couple currencies to currencies in Dataverse based on criteria.';

                        trigger OnAction()
                        var
                            Currency: Record Currency;
                            CRMIntegrationManagement: Codeunit "CRM Integration Management";
                            RecRef: RecordRef;
                        begin
                            CurrPage.SetSelectionFilter(Currency);
                            RecRef.GetTable(Currency);
                            CRMIntegrationManagement.MatchBasedCoupling(RecRef);
                        end;
                    }
                    action(DeleteCRMCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = D;
                        ApplicationArea = Suite;
                        Caption = 'Delete Coupling';
                        Enabled = CRMIsCoupledToRecord;
                        Image = UnLinkAccount;
                        ToolTip = 'Delete the coupling to a Dataverse Transaction Currency.';

                        trigger OnAction()
                        var
                            Currency: Record Currency;
                            CRMCouplingManagement: Codeunit "CRM Coupling Management";
                            RecRef: RecordRef;
                        begin
                            CurrPage.SetSelectionFilter(Currency);
                            RecRef.GetTable(Currency);
                            CRMCouplingManagement.RemoveCoupling(RecRef);
                        end;
                    }
                }
                action(ShowLog)
                {
                    ApplicationArea = Suite;
                    Caption = 'Synchronization Log';
                    Image = Log;
                    ToolTip = 'View integration synchronization jobs for the currency table.';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.ShowLog(Rec.RecordId);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(SuggestAccounts_Promoted; SuggestAccounts)
                {
                }
                actionref("Change Payment &Tolerance_Promoted"; "Change Payment &Tolerance")
                {
                }
                actionref("Exch. &Rates_Promoted"; "Exch. &Rates")
                {
                }
                actionref("Adjust Exchange Rate_Promoted"; "Adjust Exchange Rate")
                {
                }
                actionref("Exchange Rate Adjust. Register_Promoted"; "Exchange Rate Adjust. Register")
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Exchange Rate Service', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(UpdateExchangeRates_Promoted; UpdateExchangeRates)
                {
                }
                actionref("Exchange Rate Services_Promoted"; "Exchange Rate Services")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Synchronize)
            {
                Caption = 'Synchronize';

                group(Category_Coupling)
                {
                    Caption = 'Coupling';
                    ShowAs = SplitButton;

                    actionref(ManageCRMCoupling_Promoted; ManageCRMCoupling)
                    {
                    }
                    actionref(MatchBasedCoupling_Promoted; MatchBasedCoupling)
                    {
                    }
                    actionref(DeleteCRMCoupling_Promoted; DeleteCRMCoupling)
                    {
                    }
                }
                actionref(CRMSynchronizeNow_Promoted; CRMSynchronizeNow)
                {
                }
                actionref(CRMGotoTransactionCurrency_Promoted; CRMGotoTransactionCurrency)
                {
                }
                actionref(ShowLog_Promoted; ShowLog)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
    begin
        CRMIsCoupledToRecord := CRMIntegrationEnabled or CDSIntegrationEnabled;
        if CRMIsCoupledToRecord then
            CRMIsCoupledToRecord := CRMCouplingManagement.IsRecordCoupledToCRM(Rec.RecordId);
    end;

    trigger OnAfterGetRecord()
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        CurrencyFactor := CurrencyExchangeRate.GetCurrentCurrencyFactor(Rec.Code);
        CurrencyExchangeRate.GetLastestExchangeRate(Rec.Code, ExchangeRateDate, ExchangeRateAmt);
    end;

    trigger OnOpenPage()
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        CRMIntegrationEnabled := CRMIntegrationManagement.IsCRMIntegrationEnabled();
        CDSIntegrationEnabled := CRMIntegrationManagement.IsCDSIntegrationEnabled();
    end;

    var
        CurrencyFactor: Decimal;
        ExchangeRateAmt: Decimal;
        ExchangeRateDate: Date;
        CRMIntegrationEnabled: Boolean;
        CDSIntegrationEnabled: Boolean;
        CRMIsCoupledToRecord: Boolean;

    procedure GetSelectionFilter(): Text
    var
        Currency: Record Currency;
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        CurrPage.SetSelectionFilter(Currency);
        exit(SelectionFilterManagement.GetSelectionFilterForCurrency(Currency));
    end;

    procedure GetCurrency(var CurrencyCode: Code[10])
    begin
        CurrencyCode := Rec.Code;
    end;

    local procedure DrillDownActionOnPage()
    var
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        CurrExchRate.SetRange("Currency Code", Rec.Code);
        PAGE.RunModal(0, CurrExchRate);
        CurrPage.Update(false);
    end;
}
