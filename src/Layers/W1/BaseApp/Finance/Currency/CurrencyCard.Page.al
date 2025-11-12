// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Currency;

using Microsoft.Finance.GeneralLedger.Reports;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Integration.Dataverse;
using Microsoft.Purchases.Reports;
using Microsoft.Sales.Reports;

page 495 "Currency Card"
{
    Caption = 'Currency Card';
    PageType = Card;
    SourceTable = Currency;
    AdditionalSearchTerms = 'Foreign Currency, Monetary Page, Exchange Page, Forex, Money Page, Cash Page, Trade Currencies, Financial Unit Page, Transaction Money Page, Business Currency Page, Capital Type Page';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies a currency code that you can select. The code must comply with ISO 4217.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
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
                    ToolTip = 'Specifies the symbol for this currency that you wish to appear on checks and charts, $ for USD, CAD or MXP for example.';
                }
                field("Unrealized Gains Acc."; Rec."Unrealized Gains Acc.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the general ledger account number to which unrealized exchange rate gains will be posted when the Adjust Exchange Rates batch job is run.';
                }
                field("Realized Gains Acc."; Rec."Realized Gains Acc.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the general ledger account number to which realized exchange rate gains will be posted.';
                }
                field("Unrealized Losses Acc."; Rec."Unrealized Losses Acc.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the general ledger account number to which unrealized exchange rate losses will be posted when the Adjust Exchange Rates batch job is run.';
                }
                field("Realized Losses Acc."; Rec."Realized Losses Acc.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the general ledger account number to which realized exchange rate losses will be posted.';
                }
                field("EMU Currency"; Rec."EMU Currency")
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies whether the currency is an EMU currency, for example EUR.';
                }
                field("Last Date Modified"; Rec."Last Date Modified")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the last date on which any information in the Currency table was modified.';
                }
                field("Last Date Adjusted"; Rec."Last Date Adjusted")
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies when the exchange rates were last adjusted, that is, the last date on which the Adjust Exchange Rates batch job was run.';
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
            }
            group(Rounding)
            {
                Caption = 'Rounding';
                field("Invoice Rounding Precision"; Rec."Invoice Rounding Precision")
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the size of the interval to be used when rounding amounts in this currency. You can specify invoice rounding for each currency in the Currency table.';
                }
                field("Invoice Rounding Type"; Rec."Invoice Rounding Type")
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies whether an invoice amount will be rounded up or down. The program uses this information together with the interval for rounding that you have specified in the Invoice Rounding Precision field.';
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
                    Importance = Promoted;
                    ToolTip = 'Specifies the maximum VAT correction amount allowed for the currency.';
                }
                field("VAT Rounding Type"; Rec."VAT Rounding Type")
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies how the program will round VAT when calculated for this currency.';
                }
            }
            group(Reporting)
            {
                Caption = 'Reporting';
                field("Realized G/L Gains Account"; Rec."Realized G/L Gains Account")
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the general ledger account to post exchange rate gains to, for currency adjustments between LCY and the additional reporting currency.';
                }
                field("Realized G/L Losses Account"; Rec."Realized G/L Losses Account")
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the general ledger account to post exchange rate losses to, for currency adjustments between LCY and the additional reporting currency.';
                }
                field("Residual Gains Account"; Rec."Residual Gains Account")
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the general ledger account to post residual amounts to that are gains, if you post in the general ledger application area in both LCY and an additional reporting currency.';
                }
                field("Residual Losses Account"; Rec."Residual Losses Account")
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the general ledger account to post residual amounts to that are gains, if you post in the general ledger application area in both LCY and an additional reporting currency.';
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
        }
        area(reporting)
        {
            action("Foreign Currency Balance")
            {
                ApplicationArea = Suite;
                Caption = 'Foreign Currency Balance';
                Image = "Report";
                RunObject = Report "Foreign Currency Balance";
                ToolTip = 'View the balances for all customers and vendors in both foreign currencies and in local currency (LCY). The report displays two LCY balances. One is the foreign currency balance converted to LCY by using the exchange rate at the time of the transaction. The other is the foreign currency balance converted to LCY by using the exchange rate of the work date.';
            }
            action("Aged Accounts Receivable")
            {
                ApplicationArea = Suite;
                Caption = 'Aged Accounts Receivable';
                Image = "Report";
                RunObject = Report "Aged Accounts Receivable";
                ToolTip = 'View an overview of when customer payments are due or overdue, divided into four periods. You must specify the date you want aging calculated from and the length of the period that each column will contain data for.';
            }
            action("Aged Accounts Payable")
            {
                ApplicationArea = Suite;
                Caption = 'Aged Accounts Payable';
                Image = "Report";
                RunObject = Report "Aged Accounts Payable";
                ToolTip = 'View an overview of when your payables to vendors are due or overdue (divided into four periods). You must specify the date you want aging calculated from and the length of the period that each column will contain data for.';
            }
            action("Trial Balance")
            {
                ApplicationArea = Suite;
                Caption = 'Trial Balance';
                Image = "Report";
                RunObject = Report "Trial Balance";
                ToolTip = 'View a detailed trial balance for selected currency.';
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
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Process;
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
                        //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                        //PromotedCategory = Process;
                        ToolTip = 'Create or modify the coupling to a Dataverse Transaction Currency.';

                        trigger OnAction()
                        var
                            CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        begin
                            CRMIntegrationManagement.DefineCoupling(Rec.RecordId);
                        end;
                    }
                    action(DeleteCRMCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = D;
                        ApplicationArea = Suite;
                        Caption = 'Delete Coupling';
                        Enabled = CRMIsCoupledToRecord;
                        Image = UnLinkAccount;
                        //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                        //PromotedCategory = Process;
                        ToolTip = 'Delete the coupling to a Dataverse Transaction Currency.';

                        trigger OnAction()
                        var
                            CRMCouplingManagement: Codeunit "CRM Coupling Management";
                        begin
                            CRMCouplingManagement.RemoveCoupling(Rec.RecordId);
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

                actionref("Change Payment &Tolerance_Promoted"; "Change Payment &Tolerance")
                {
                }
                actionref("Exch. &Rates_Promoted"; "Exch. &Rates")
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Navigate', Comment = 'Generated from the PromotedActionCategories property index 3.';

            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';

                actionref("Foreign Currency Balance_Promoted"; "Foreign Currency Balance")
                {
                }
                actionref("Aged Accounts Receivable_Promoted"; "Aged Accounts Receivable")
                {
                }
                actionref("Aged Accounts Payable_Promoted"; "Aged Accounts Payable")
                {
                }
                actionref("Trial Balance_Promoted"; "Trial Balance")
                {
                }
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
        if CRMIntegrationEnabled or CDSIntegrationEnabled then begin
            CRMIsCoupledToRecord := CRMCouplingManagement.IsRecordCoupledToCRM(Rec.RecordId);
            if Rec.Code <> xRec.Code then
                CRMIntegrationManagement.SendResultNotification(Rec);
        end;
    end;

    trigger OnOpenPage()
    begin
        CRMIntegrationEnabled := CRMIntegrationManagement.IsCRMIntegrationEnabled();
        CDSIntegrationEnabled := CRMIntegrationManagement.IsCDSIntegrationEnabled();
    end;

    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        CRMIntegrationEnabled: Boolean;
        CDSIntegrationEnabled: Boolean;
        CRMIsCoupledToRecord: Boolean;
}

