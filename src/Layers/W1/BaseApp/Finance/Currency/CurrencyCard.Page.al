// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Currency;

using Microsoft.Finance.GeneralLedger.Reports;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Integration.Dataverse;
#if not CLEAN28
using Microsoft.Purchases.Reports;
using Microsoft.Sales.Reports;
#endif

/// <summary>
/// Provides a detailed card interface for managing currency configuration and settings.
/// Supports currency setup, exchange rate management, rounding configurations, and G/L account mappings.
/// </summary>
/// <remarks>
/// Source Table: Currency (4). Key features include currency definition, rounding precision settings,
/// exchange rate access, and G/L account configuration for currency gains/losses posting.
/// </remarks>
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
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                }
                field("ISO Code"; Rec."ISO Code")
                {
                    ApplicationArea = Suite;
                }
                field("ISO Numeric Code"; Rec."ISO Numeric Code")
                {
                    ApplicationArea = Suite;
                }
                field(Symbol; Rec.Symbol)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the symbol for this currency that you wish to appear on checks and charts, $ for USD, CAD or MXP for example.';
                }
                field("Unrealized Gains Acc."; Rec."Unrealized Gains Acc.")
                {
                    ApplicationArea = Suite;
                }
                field("Realized Gains Acc."; Rec."Realized Gains Acc.")
                {
                    ApplicationArea = Suite;
                }
                field("Unrealized Losses Acc."; Rec."Unrealized Losses Acc.")
                {
                    ApplicationArea = Suite;
                }
                field("Realized Losses Acc."; Rec."Realized Losses Acc.")
                {
                    ApplicationArea = Suite;
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
                }
                field("Last Date Adjusted"; Rec."Last Date Adjusted")
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                }
                field("Payment Tolerance %"; Rec."Payment Tolerance %")
                {
                    ApplicationArea = Suite;
                }
                field("Max. Payment Tolerance Amount"; Rec."Max. Payment Tolerance Amount")
                {
                    ApplicationArea = Suite;
                }
            }
            group(Rounding)
            {
                Caption = 'Rounding';
                field("Invoice Rounding Precision"; Rec."Invoice Rounding Precision")
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                }
                field("Invoice Rounding Type"; Rec."Invoice Rounding Type")
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                }
                field("Amount Rounding Precision"; Rec."Amount Rounding Precision")
                {
                    ApplicationArea = Suite;
                }
                field("Amount Decimal Places"; Rec."Amount Decimal Places")
                {
                    ApplicationArea = Suite;
                }
                field("Unit-Amount Rounding Precision"; Rec."Unit-Amount Rounding Precision")
                {
                    ApplicationArea = Suite;
                }
                field("Unit-Amount Decimal Places"; Rec."Unit-Amount Decimal Places")
                {
                    ApplicationArea = Suite;
                }
                field("Appln. Rounding Precision"; Rec."Appln. Rounding Precision")
                {
                    ApplicationArea = Suite;
                }
                field("Conv. LCY Rndg. Debit Acc."; Rec."Conv. LCY Rndg. Debit Acc.")
                {
                    ApplicationArea = Suite;
                }
                field("Conv. LCY Rndg. Credit Acc."; Rec."Conv. LCY Rndg. Credit Acc.")
                {
                    ApplicationArea = Suite;
                }
                field("Max. VAT Difference Allowed"; Rec."Max. VAT Difference Allowed")
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                }
                field("VAT Rounding Type"; Rec."VAT Rounding Type")
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                }
            }
            group(Reporting)
            {
                Caption = 'Reporting';
                field("Realized G/L Gains Account"; Rec."Realized G/L Gains Account")
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
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
#if not CLEAN28
            action("Aged Accounts Receivable")
            {
                ApplicationArea = Suite;
                Caption = 'Aged Accounts Receivable (Obsolete)';
                Image = "Report";
                RunObject = Report "Aged Accounts Receivable";
                ToolTip = 'View an overview of when customer payments are due or overdue, divided into four periods. You must specify the date you want aging calculated from and the length of the period that each column will contain data for.';
                ObsoleteState = Pending;
                ObsoleteReason = 'This report has been replaced by the report Aged Accounts Receivable (Excel). This report will be removed in a future release.';
                ObsoleteTag = '28.0';
            }
            action("Aged Accounts Payable")
            {
                ApplicationArea = Suite;
                Caption = 'Aged Accounts Payable (Obsolete)';
                Image = "Report";
                RunObject = Report "Aged Accounts Payable";
                ToolTip = 'View an overview of when your payables to vendors are due or overdue (divided into four periods). You must specify the date you want aging calculated from and the length of the period that each column will contain data for.';
                ObsoleteState = Pending;
                ObsoleteReason = 'This report has been replaced by the report Aged Accounts Payable (Excel). This report will be removed in a future release.';
                ObsoleteTag = '28.0';
            }
            action("Trial Balance")
            {
                ApplicationArea = Suite;
                Caption = 'Trial Balance (Obsolete)';
                Image = "Report";
                RunObject = Report "Trial Balance";
                ToolTip = 'View a detailed trial balance for selected currency.';
                ObsoleteState = Pending;
                ObsoleteReason = 'This report has been replaced by the report Trial Balance (Excel). This report will be removed in a future release.';
                ObsoleteTag = '28.0';
            }
#endif
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
#if not CLEAN28
                actionref("Aged Accounts Receivable_Promoted"; "Aged Accounts Receivable")
                {
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This report has been replaced by the report Aged Accounts Receivable (Excel). This report will be removed in a future release.';
                    ObsoleteTag = '28.0';
                }
                actionref("Aged Accounts Payable_Promoted"; "Aged Accounts Payable")
                {
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This report has been replaced by the report Aged Accounts Payable (Excel). This report will be removed in a future release.';
                    ObsoleteTag = '28.0';
                }
                actionref("Trial Balance_Promoted"; "Trial Balance")
                {
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This report has been replaced by the report Trial Balance (Excel). This report will be removed in a future release.';
                    ObsoleteTag = '28.0';
                }
#endif
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

