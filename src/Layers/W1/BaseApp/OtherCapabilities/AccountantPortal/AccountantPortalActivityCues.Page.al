namespace Microsoft.AccountantPortal;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.RoleCenters;
using System.Visualization;
using System.Automation;
using System.Text;

page 1314 "AccountantPortal Activity Cues"
{
    Caption = 'AccountantPortal Activity Cues';
    PageType = List;
    SourceTable = "Activities Cue";

    layout
    {
        area(content)
        {
            group("Overdue Purchase Invoice Amount")
            {
                field(OverduePurchInvoiceAmount; OverduePurchInvoiceAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'OverduePurchInvoiceAmount', Locked = true;
                    ToolTip = 'Specifies the sum of your overdue payments to vendors.';
                }

                field(OverduePurchInvoiceAmountDecimal; OverduePurchInvoiceAmountDecimal)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'OverduePurchInvoiceAmountDecimal', Locked = true;
                    ToolTip = 'Specifies the sum of your overdue payments to vendors.';
                }
                field(OverduePurchInvoiceStyle; OverduePurchInvoiceStyle)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'OverduePurchInvoiceStyle', Locked = true;
                    ToolTip = 'Specifies the sum of your overdue payments to vendors.';
                }

                field(CurrencySymbol; CurrencySymbol)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'CurrencySymbol', Locked = true;
                    ToolTip = 'Specifies the currency symbol.';
                }
            }
            group("Overdue Sales Invoice Amount")
            {
                field(OverdueSalesInvoiceAmount; OverdueSalesInvoiceAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'OverdueSalesInvoiceAmount', Locked = true;
                    ToolTip = 'Specifies the sum of overdue payments from customers.';
                }

                field(OverdueSalesInvoiceAmountDecimal; OverdueSalesInvoiceAmountDecimal)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'OverdueSalesInvoiceAmountDecimal', Locked = true;
                    ToolTip = 'Specifies the sum of overdue payments from customers.';
                }
                field(OverdueSalesInvoiceStyle; OverdueSalesInvoiceStyle)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'OverdueSalesInvoiceStyle', Locked = true;
                    ToolTip = 'Specifies the sum of overdue payments from customers.';
                }
            }
            group("NonApplied Payments")
            {
                field(NonAppliedPaymentsAmount; NonAppliedPaymentsAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'NonAppliedPaymentsAmount', Locked = true;
                    ToolTip = 'Specifies imported bank transactions for payments that are not yet reconciled in the Payment Reconciliation Journal window.';
                }
                field(NonAppliedPaymentsStyle; NonAppliedPaymentsStyle)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'NonAppliedPaymentsStyle', Locked = true;
                    ToolTip = 'Specifies imported bank transactions for payments that are not yet reconciled in the Payment Reconciliation Journal window.';
                }
            }
            group("Purchase Inv. Due Next Week")
            {
                field(PurchInvoicesDueNextWeekAmount; PurchInvoicesDueNextWeekAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'PurchInvoicesDueNextWeekAmount', Locked = true;
                    ToolTip = 'Specifies the number of payments to vendors that are due next week.';
                }
                field(PurchInvoicesDueNextWeekStyle; PurchInvoicesDueNextWeekStyle)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'PurchInvoicesDueNextWeekStyle', Locked = true;
                    ToolTip = 'Specifies the number of payments to vendors that are due next week.';
                }
            }
            group("Sales Inv. Due Next Week")
            {
                field(SalesInvoicesDueNextWeekAmount; SalesInvoicesDueNextWeekAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'SalesInvoicesDueNextWeekAmount', Locked = true;
                    ToolTip = 'Specifies the number of payments from customers that are due next week.';
                }
                field(SalesInvoicesDueNextWeekStyle; SalesInvoicesDueNextWeekStyle)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'SalesInvoicesDueNextWeekStyle', Locked = true;
                    ToolTip = 'Specifies the number of payments from customers that are due next week.';
                }
            }
            group("Ongoing Purchase Invoice")
            {
                field(OngoingPurchaseInvoicesAmount; OngoingPurchaseInvoicesAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'OngoingPurchaseInvoicesAmount', Locked = true;
                    ToolTip = 'Specifies purchases invoices that are not posted or only partially posted.';
                }
                field(OngoingPurchaseInvoicesStyle; OngoingPurchaseInvoicesStyle)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'OngoingPurchaseInvoicesStyle', Locked = true;
                    ToolTip = 'Specifies purchases invoices that are not posted or only partially posted.';
                }
            }
            group("Ongoing Sales Invoice")
            {
                field(OngoingSalesInvoicesAmount; OngoingSalesInvoicesAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'OngoingSalesInvoicesAmount', Locked = true;
                    ToolTip = 'Specifies sales invoices that are not yet posted or only partially posted.';
                }
                field(OngoingSalesInvoicesStyle; OngoingSalesInvoicesStyle)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'OngoingSalesInvoicesStyle', Locked = true;
                    ToolTip = 'Specifies sales invoices that are not yet posted or only partially posted.';
                }
            }
            group("Sales this Month")
            {
                field(SalesThisMonthAmount; SalesThisMonthAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'SalesThisMonthAmount', Locked = true;
                    ToolTip = 'Specifies the sum of sales in the current month.';
                }
                field(SalesThisMonthStyle; SalesThisMonthStyle)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'SalesThisMonthStyle', Locked = true;
                    ToolTip = 'Specifies the sum of sales in the current month.';
                }
            }
            group("Top 10 Cust Sales YTD")
            {
                Caption = 'Top 10 Cust Sales YTD', Locked = true;
                field(Top10CustomerSalesYTDAmount; Top10CustomerSalesYTDAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Top10CustomerSalesYTDAmount', Locked = true;
                    ToolTip = 'Specifies the sum of the top 10 sales in the current year.';
                }
                field(Top10CustomerSalesYTDStyle; Top10CustomerSalesYTDStyle)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Top10CustomerSalesYTDStyle', Locked = true;
                    ToolTip = 'Specifies the sum of the top 10 sales in the current year.';
                }
            }
            group("Avg. Collection Days")
            {
                field(AverageCollectionDaysAmount; AverageCollectionDaysAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'AverageCollectionDaysAmount', Locked = true;
                    ToolTip = 'Specifies how long customers took to pay invoices in the last three months. This is the average number of days from when invoices are issued to when customers pay the invoices.';
                }
                field(AverageCollectionDaysStyle; AverageCollectionDaysStyle)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'AverageCollectionDaysStyle', Locked = true;
                    ToolTip = 'Specifies how long customers took to pay invoices in the last three months. This is the average number of days from when invoices are issued to when customers pay the invoices.';
                }
            }
            group("Ongoing Sales Quote")
            {
                field(OngoingSalesQuotesAmount; OngoingSalesQuotesAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'OngoingSalesQuotesAmount', Locked = true;
                    ToolTip = 'Specifies sales quotes that have not yet been converted to invoices or orders.';
                }
                field(OngoingSalesQuotesStyle; OngoingSalesQuotesStyle)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'OngoingSalesQuotesStyle', Locked = true;
                    ToolTip = 'Specifies sales quotes that have not yet been converted to invoices or orders.';
                }
            }
            group("Ongoing Sales Order")
            {
                field(OngoingSalesOrdersAmount; OngoingSalesOrdersAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'OngoingSalesOrdersAmount', Locked = true;
                    ToolTip = 'Specifies sales orders that are not yet posted or only partially posted.';
                }
                field(OngoingSalesOrdersStyle; OngoingSalesOrdersStyle)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'OngoingSalesOrdersStyle', Locked = true;
                    ToolTip = 'Specifies sales orders that are not yet posted or only partially posted.';
                }
            }
            group(RequestToApprove)
            {
                field(RequeststoApproveAmount; RequeststoApproveAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'RequeststoApproveAmount', Locked = true;
                    ToolTip = 'Specifies the number of approval requests that require your approval.';
                }
                field(RequeststoApproveStyle; RequeststoApproveStyle)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'RequeststoApproveStyle', Locked = true;
                    ToolTip = 'Specifies the number of approval requests that require your approval.';
                }
            }
            group(PurchOrders)
            {
                field(PurchaseOrdersAmount; PurchaseOrdersAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'PurchaseOrdersAmount', Locked = true;
                    ToolTip = 'Specifies purchases orders that are not posted or only partially posted.';
                }
                field(PurchaseOrdersStyle; PurchaseOrdersStyle)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'PurchaseOrdersStyle', Locked = true;
                    ToolTip = 'Specifies purchases orders that are not posted or only partially posted.';
                }
            }
            group(SalesInvPendDocExchange)
            {
                field(SalesInvPendDocExchangeAmount; SalesInvPendDocExchangeAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'SalesInvPendDocExchangeAmount', Locked = true;
                    ToolTip = 'Specifies sales invoices that await sending to the customer through the document exchange service.';
                }
                field(SalesInvPendDocExchangeStyle; SalesInvPendDocExchangeStyle)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'SalesInvPendDocExchangeStyle', Locked = true;
                    ToolTip = 'Specifies sales invoices that await sending to the customer through the document exchange service.';
                }
            }
            group(SalesCRPendDocExchange)
            {
                field(SalesCrMPendDocExchangeAmount; SalesCrMPendDocExchangeAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'SalesCrMPendDocExchangeAmount', Locked = true;
                    ToolTip = 'Specifies sales credit memos that await sending to the customer through the document exchange service.';
                }
                field(SalesCrMPendDocExchangeStyle; SalesCrMPendDocExchangeStyle)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'SalesCrMPendDocExchangeStyle', Locked = true;
                    ToolTip = 'Specifies sales credit memos that await sending to the customer through the document exchange service.';
                }
            }
            group("Incoming Documents")
            {
                field(MyIncomingDocumentsAmount; MyIncomingDocumentsAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'MyIncomingDocumentsAmount', Locked = true;
                    ToolTip = 'Specifies incoming documents that are assigned to you.';
                }
                field(MyIncomingDocumentsStyle; MyIncomingDocumentsStyle)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'MyIncomingDocumentsStyle', Locked = true;
                    ToolTip = 'Specifies incoming documents that are assigned to you.';
                }
            }
            group(IncDocAwaitingVerification)
            {
                field(IncDocAwaitingVerifAmount; IncDocAwaitingVerifAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'IncDocAwaitingVerifAmount', Locked = true;
                    ToolTip = 'Specifies incoming documents in OCR processing that require you to log on to the OCR service website to manually verify the OCR values before the documents can be received.';
                }
                field(IncDocAwaitingVerifStyle; IncDocAwaitingVerifStyle)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'IncDocAwaitingVerifStyle', Locked = true;
                    ToolTip = 'Specifies incoming documents in OCR processing that require you to log on to the OCR service website to manually verify the OCR values before the documents can be received.';
                }
            }
            group(ContactName)
            {
                field(ContactNameAmount; ContactNameAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'ContactNameAmount', Locked = true;
                    ToolTip = 'Specifies the name of the contact person in your company.';
                }
                field(ContactNameStyle; ContactNameStyle)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'ContactNameStyle', Locked = true;
                    ToolTip = 'Specifies the name of the contact person in your company.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        SetAccountantPortalAmountFields();
        GetCompanyContactName();
    end;

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
            Commit();
        end;
        Rec.SetFilter("Due Date Filter", '>=%1', Today);
        Rec.SetFilter("Due Next Week Filter", '%1..%2', CalcDate('<1D>', Today), CalcDate('<1W>', Today));
        Rec.SetFilter("Overdue Date Filter", '<%1', Today);
    end;

    var
        ActivitiesMgt: Codeunit "Activities Mgt.";
        OverduePurchInvoiceAmount: Text;
        OverduePurchInvoiceStyle: Enum "Cues And KPIs Style";
        OverdueSalesInvoiceAmount: Text;
        OverdueSalesInvoiceStyle: Enum "Cues And KPIs Style";
        NonAppliedPaymentsAmount: Text;
        NonAppliedPaymentsStyle: Enum "Cues And KPIs Style";
        PurchInvoicesDueNextWeekAmount: Text;
        PurchInvoicesDueNextWeekStyle: Enum "Cues And KPIs Style";
        SalesInvoicesDueNextWeekAmount: Text;
        SalesInvoicesDueNextWeekStyle: Enum "Cues And KPIs Style";
        OngoingPurchaseInvoicesAmount: Text;
        OngoingPurchaseInvoicesStyle: Enum "Cues And KPIs Style";
        OngoingSalesInvoicesAmount: Text;
        OngoingSalesInvoicesStyle: Enum "Cues And KPIs Style";
        SalesThisMonthAmount: Text;
        SalesThisMonthStyle: Enum "Cues And KPIs Style";
        Top10CustomerSalesYTDAmount: Text;
        Top10CustomerSalesYTDStyle: Enum "Cues And KPIs Style";
        AverageCollectionDaysAmount: Text;
        AverageCollectionDaysStyle: Enum "Cues And KPIs Style";
        OngoingSalesQuotesAmount: Text;
        OngoingSalesQuotesStyle: Enum "Cues And KPIs Style";
        OngoingSalesOrdersAmount: Text;
        OngoingSalesOrdersStyle: Enum "Cues And KPIs Style";
        RequeststoApproveAmount: Text;
        RequeststoApproveStyle: Enum "Cues And KPIs Style";
        PurchaseOrdersAmount: Text;
        PurchaseOrdersStyle: Enum "Cues And KPIs Style";
        SalesInvPendDocExchangeAmount: Text;
        SalesInvPendDocExchangeStyle: Enum "Cues And KPIs Style";
        SalesCrMPendDocExchangeAmount: Text;
        SalesCrMPendDocExchangeStyle: Enum "Cues And KPIs Style";
        MyIncomingDocumentsAmount: Text;
        MyIncomingDocumentsStyle: Enum "Cues And KPIs Style";
        IncDocAwaitingVerifAmount: Text;
        IncDocAwaitingVerifStyle: Enum "Cues And KPIs Style";
        ContactNameAmount: Text;
        ContactNameStyle: Enum "Cues And KPIs Style";

        OverduePurchInvoiceAmountDecimal: Decimal;
        OverdueSalesInvoiceAmountDecimal: Decimal;

        CurrencySymbol: Text[10];

    local procedure SetAccountantPortalAmountFields()
    var
        ActivitiesCue: Record "Activities Cue";
        GeneralLedgerSetup: Record "General Ledger Setup";
        ApprovalActivitiesCue: Record "Approvals Activities Cue";
        AcctWebServicesMgt: Codeunit "Acct. WebServices Mgt.";
        CuesAndKpis: Codeunit "Cues And KPIs";
        StringConversionManagement: Codeunit StringConversionManagement;
        Justification: Option Right,Left;
        TempString: Text[250];
        UnlimitedTempString: Text;
    begin
        CurrencySymbol := '';
        if GeneralLedgerSetup.Get() then
            CurrencySymbol := GeneralLedgerSetup.GetCurrencySymbol();

        Rec."Overdue Purch. Invoice Amount" := ActivitiesMgt.OverduePurchaseInvoiceAmount(true, false);
        OverduePurchInvoiceAmountDecimal := Rec."Overdue Purch. Invoice Amount";
        UnlimitedTempString := AcctWebServicesMgt.FormatAmountString(Rec."Overdue Purch. Invoice Amount");
        TempString := CopyStr(UnlimitedTempString, 1, 250);
        OverduePurchInvoiceAmount := StringConversionManagement.GetPaddedString(TempString, 30, ' ', Justification::Right);
        CuesAndKpis.SetCueStyle(Database::"Activities Cue", ActivitiesCue.FieldNo("Overdue Purch. Invoice Amount"), Rec."Overdue Purch. Invoice Amount", OverduePurchInvoiceStyle);

        Rec."Overdue Sales Invoice Amount" := ActivitiesMgt.OverdueSalesInvoiceAmount(true, false);
        OverdueSalesInvoiceAmountDecimal := Rec."Overdue Sales Invoice Amount";
        UnlimitedTempString := AcctWebServicesMgt.FormatAmountString(Rec."Overdue Sales Invoice Amount");
        TempString := CopyStr(UnlimitedTempString, 1, 250);
        OverdueSalesInvoiceAmount := StringConversionManagement.GetPaddedString(TempString, 30, ' ', Justification::Right);
        CuesAndKpis.SetCueStyle(Database::"Activities Cue", ActivitiesCue.FieldNo("Overdue Sales Invoice Amount"), Rec."Overdue Sales Invoice Amount", OverdueSalesInvoiceStyle);

        Rec.CalcFields("Non-Applied Payments");
        TempString := Format(Rec."Non-Applied Payments");
        NonAppliedPaymentsAmount := StringConversionManagement.GetPaddedString(TempString, 30, ' ', Justification::Right);
        CuesAndKpis.SetCueStyle(Database::"Activities Cue", ActivitiesCue.FieldNo("Non-Applied Payments"), Rec."Non-Applied Payments", NonAppliedPaymentsStyle);

        Rec.CalcFields("Purch. Invoices Due Next Week");
        TempString := Format(Rec."Purch. Invoices Due Next Week");
        PurchInvoicesDueNextWeekAmount := StringConversionManagement.GetPaddedString(TempString, 30, ' ', Justification::Right);
        CuesAndKpis.SetCueStyle(Database::"Activities Cue", ActivitiesCue.FieldNo("Purch. Invoices Due Next Week"), Rec."Purch. Invoices Due Next Week", PurchInvoicesDueNextWeekStyle);

        Rec.CalcFields("Sales Invoices Due Next Week");
        TempString := Format(Rec."Sales Invoices Due Next Week");
        SalesInvoicesDueNextWeekAmount := StringConversionManagement.GetPaddedString(TempString, 30, ' ', Justification::Right);
        CuesAndKpis.SetCueStyle(Database::"Activities Cue", ActivitiesCue.FieldNo("Sales Invoices Due Next Week"), Rec."Sales Invoices Due Next Week", SalesInvoicesDueNextWeekStyle);

        Rec.CalcFields("Ongoing Purchase Invoices");
        TempString := Format(Rec."Ongoing Purchase Invoices");
        OngoingPurchaseInvoicesAmount := StringConversionManagement.GetPaddedString(TempString, 30, ' ', Justification::Right);
        CuesAndKpis.SetCueStyle(Database::"Activities Cue", ActivitiesCue.FieldNo("Ongoing Purchase Invoices"), Rec."Ongoing Purchase Invoices", OngoingPurchaseInvoicesStyle);

        Rec.CalcFields("Ongoing Sales Invoices");
        TempString := Format(Rec."Ongoing Sales Invoices");
        OngoingSalesInvoicesAmount := StringConversionManagement.GetPaddedString(TempString, 30, ' ', Justification::Right);
        CuesAndKpis.SetCueStyle(Database::"Activities Cue", ActivitiesCue.FieldNo("Ongoing Sales Invoices"), Rec."Ongoing Sales Invoices", OngoingSalesInvoicesStyle);

        Rec."Sales This Month" := ActivitiesMgt.CalcSalesThisMonthAmount(true);
        UnlimitedTempString := AcctWebServicesMgt.FormatAmountString(Rec."Sales This Month");
        TempString := CopyStr(UnlimitedTempString, 1, 250);
        SalesThisMonthAmount := StringConversionManagement.GetPaddedString(TempString, 30, ' ', Justification::Right);
        CuesAndKpis.SetCueStyle(Database::"Activities Cue", ActivitiesCue.FieldNo("Sales This Month"), Rec."Sales This Month", SalesThisMonthStyle);

        Rec."Top 10 Customer Sales YTD" := ActivitiesMgt.CalcTop10CustomerSalesYTD();
        UnlimitedTempString := AcctWebServicesMgt.FormatAmountString(Rec."Top 10 Customer Sales YTD");
        TempString := CopyStr(UnlimitedTempString, 1, 250);
        Top10CustomerSalesYTDAmount := StringConversionManagement.GetPaddedString(TempString, 30, ' ', Justification::Right);
        CuesAndKpis.SetCueStyle(Database::"Activities Cue", ActivitiesCue.FieldNo("Top 10 Customer Sales YTD"), Rec."Top 10 Customer Sales YTD", Top10CustomerSalesYTDStyle);

        Rec."Average Collection Days" := ActivitiesMgt.CalcAverageCollectionDays(false);
        TempString := Format(Rec."Average Collection Days");
        AverageCollectionDaysAmount := StringConversionManagement.GetPaddedString(TempString, 30, ' ', Justification::Right);
        CuesAndKpis.SetCueStyle(Database::"Activities Cue", ActivitiesCue.FieldNo("Average Collection Days"), Rec."Average Collection Days", AverageCollectionDaysStyle);

        Rec.CalcFields("Ongoing Sales Quotes");
        TempString := Format(Rec."Ongoing Sales Quotes");
        OngoingSalesQuotesAmount := StringConversionManagement.GetPaddedString(TempString, 30, ' ', Justification::Right);
        CuesAndKpis.SetCueStyle(Database::"Activities Cue", ActivitiesCue.FieldNo("Ongoing Sales Quotes"), Rec."Ongoing Sales Quotes", OngoingSalesQuotesStyle);

        Rec.CalcFields("Ongoing Sales Orders");
        TempString := Format(Rec."Ongoing Sales Orders");
        OngoingSalesOrdersAmount := StringConversionManagement.GetPaddedString(TempString, 30, ' ', Justification::Right);
        CuesAndKpis.SetCueStyle(Database::"Activities Cue", ActivitiesCue.FieldNo("Ongoing Sales Orders"), Rec."Ongoing Sales Orders", OngoingSalesOrdersStyle);

        Rec.CalcFields("Purchase Orders");
        TempString := Format(Rec."Purchase Orders");
        PurchaseOrdersAmount := StringConversionManagement.GetPaddedString(TempString, 30, ' ', Justification::Right);
        CuesAndKpis.SetCueStyle(Database::"Activities Cue", ActivitiesCue.FieldNo("Purchase Orders"), Rec."Purchase Orders", PurchaseOrdersStyle);

        Rec.CalcFields("Sales Inv. - Pending Doc.Exch.");
        TempString := Format(Rec."Sales Inv. - Pending Doc.Exch.");
        SalesInvPendDocExchangeAmount := StringConversionManagement.GetPaddedString(TempString, 30, ' ', Justification::Right);
        CuesAndKpis.SetCueStyle(Database::"Activities Cue", ActivitiesCue.FieldNo("Sales Inv. - Pending Doc.Exch."), Rec."Sales Inv. - Pending Doc.Exch.", SalesInvPendDocExchangeStyle);

        Rec.CalcFields("Sales CrM. - Pending Doc.Exch.");
        TempString := Format(Rec."Sales CrM. - Pending Doc.Exch.");
        SalesCrMPendDocExchangeAmount := StringConversionManagement.GetPaddedString(TempString, 30, ' ', Justification::Right);
        CuesAndKpis.SetCueStyle(Database::"Activities Cue", ActivitiesCue.FieldNo("Sales CrM. - Pending Doc.Exch."), Rec."Sales CrM. - Pending Doc.Exch.", SalesCrMPendDocExchangeStyle);

        Rec.CalcFields("My Incoming Documents");
        TempString := Format(Rec."My Incoming Documents");
        MyIncomingDocumentsAmount := StringConversionManagement.GetPaddedString(TempString, 30, ' ', Justification::Right);
        CuesAndKpis.SetCueStyle(Database::"Activities Cue", ActivitiesCue.FieldNo("My Incoming Documents"), Rec."My Incoming Documents", MyIncomingDocumentsStyle);

        Rec.CalcFields("Inc. Doc. Awaiting Verfication");
        TempString := Format(Rec."Inc. Doc. Awaiting Verfication");
        IncDocAwaitingVerifAmount := StringConversionManagement.GetPaddedString(TempString, 30, ' ', Justification::Right);
        CuesAndKpis.SetCueStyle(Database::"Activities Cue", ActivitiesCue.FieldNo("Inc. Doc. Awaiting Verfication"), Rec."Inc. Doc. Awaiting Verfication", IncDocAwaitingVerifStyle);

        ApprovalActivitiesCue.SetRange("User ID Filter", UserId);
        ApprovalActivitiesCue.CalcFields("Requests to Approve");
        TempString := Format(ApprovalActivitiesCue."Requests to Approve");
        RequestsToApproveAmount := StringConversionManagement.GetPaddedString(TempString, 30, ' ', Justification::Right);
        CuesAndKpis.SetCueStyle(Database::"Approvals Activities Cue", ApprovalActivitiesCue.FieldNo("Requests to Approve"), ApprovalActivitiesCue."Requests to Approve", RequestsToApproveStyle);
    end;

    local procedure GetCompanyContactName()
    var
        CompanyInformation: Record "Company Information";
    begin
        ContactNameStyle := ContactNameStyle::None;
        if CompanyInformation.Get() then
            ContactNameAmount := CompanyInformation."Contact Person";
    end;
}

