namespace Microsoft.AccountantPortal;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.RoleCenters;
using Microsoft.Projects.TimeSheet;
using Microsoft.RoleCenters;
using System.Automation;
using System.Security.User;
using System.Text;
using System.Visualization;

page 1315 "Accountant Portal Finance Cues"
{
    Caption = 'Accountant Portal Finance Cues';
    PageType = List;
    SourceTable = "Finance Cue";

    layout
    {
        area(content)
        {
            group(OverduePurchaseDocuments)
            {
                Caption = 'OverduePurchaseDocuments', Locked = true;
                field(OverduePurchaseDocumentsAmount; OverduePurchaseDocumentsAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'OverduePurchaseDocumentsAmount', Locked = true;
                    ToolTip = 'Specifies the number of purchase invoices where your payment is late.';
                }
                field(OverduePurchaseDocumentsStyle; OverduePurchaseDocumentsStyle)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'OverduePurchaseDocumentsStyle', Locked = true;
                    ToolTip = 'Specifies the number of purchase invoices where your payment is late.';
                }

                field(CurrencySymbol; CurrencySymbol)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'CurrencySymbol', Locked = true;
                    ToolTip = 'Specifies the currency symbol.';
                }
            }

            group(PurchaseDiscountsNextWeek)
            {
                Caption = 'PurchaseDiscountsNextWeek', Locked = true;
                field(PurchaseDiscountsNextWeekAmount; PurchaseDiscountsNextWeekAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'PurchaseDiscountsNextWeekAmount', Locked = true;
                    ToolTip = 'Specifies the number of purchase discounts that are available next week, for example, because the discount expires after next week.';
                }
                field(PurchaseDiscountsNextWeekStyle; PurchaseDiscountsNextWeekStyle)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'PurchaseDiscountsNextWeekStyle', Locked = true;
                    ToolTip = 'Specifies the number of purchase discounts that are available next week, for example, because the discount expires after next week.';
                }
            }
            group(OverdueSalesDocuments)
            {
                Caption = 'OverdueSalesDocuments', Locked = true;
                field(OverdueSalesDocumentsAmount; OverdueSalesDocumentsAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'OverdueSalesDocumentsAmount', Locked = true;
                    ToolTip = 'Specifies the number of invoices where the customer is late with payment.';
                }
                field(OverdueSalesDocumentsStyle; OverdueSalesDocumentsStyle)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'OverdueSalesDocumentsStyle', Locked = true;
                    ToolTip = 'Specifies the number of invoices where the customer is late with payment.';
                }
            }
            group(PurchaseDocumentsDueToday)
            {
                Caption = 'PurchaseDocumentsDueToday', Locked = true;
                field(PurchaseDocumentsDueTodayAmount; PurchaseDocumentsDueTodayAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'PurchaseDocumentsDueTodayAmount', Locked = true;
                    ToolTip = 'Specifies the number of purchase invoices that are due for payment today.';
                }
                field(PurchaseDocumentsDueTodayStyle; PurchaseDocumentsDueTodayStyle)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'PurchaseDocumentsDueTodayStyle', Locked = true;
                    ToolTip = 'Specifies the number of purchase invoices that are due for payment today.';
                }
            }
            group(VendorsPaymentsOnHold)
            {
                Caption = 'VendorsPaymentsOnHold', Locked = true;
                field(VendorsPaymentsOnHoldAmount; VendorsPaymentsOnHoldAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'VendorsPaymentsOnHoldAmount', Locked = true;
                    ToolTip = 'Specifies the number of vendor to whom your payment is on hold.';
                }
                field(VendorsPaymentsOnHoldStyle; VendorsPaymentsOnHoldStyle)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'VendorsPaymentsOnHoldStyle', Locked = true;
                    ToolTip = 'Specifies the number of vendor to whom your payment is on hold.';
                }
            }
            group(POsPendingApproval)
            {
                Caption = 'POsPendingApproval', Locked = true;
                field(POsPendingApprovalAmount; POsPendingApprovalAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'POsPendingApprovalAmount', Locked = true;
                    ToolTip = 'Specifies the number of purchase orders that are pending approval.';
                }
                field(POsPendingApprovalStyle; POsPendingApprovalStyle)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'POsPendingApprovalStyle', Locked = true;
                    ToolTip = 'Specifies the number of purchase orders that are pending approval.';
                }
            }
            group(SOsPendingApproval)
            {
                Caption = 'SOsPendingApproval', Locked = true;
                field(SOsPendingApprovalAmount; SOsPendingApprovalAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'SOsPendingApprovalAmount', Locked = true;
                    ToolTip = 'Specifies the number of sales orders that are pending approval.';
                }
                field(SOsPendingApprovalStyle; SOsPendingApprovalStyle)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'SOsPendingApprovalStyle', Locked = true;
                    ToolTip = 'Specifies the number of sales orders that are pending approval.';
                }
            }
            group(ApprovedSalesOrders)
            {
                Caption = 'ApprovedSalesOrders', Locked = true;
                field(ApprovedSalesOrdersAmount; ApprovedSalesOrdersAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'ApprovedSalesOrdersAmount', Locked = true;
                    ToolTip = 'Specifies the number of approved sales orders in the company.';
                }
                field(ApprovedSalesOrdersStyle; ApprovedSalesOrdersStyle)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'ApprovedSalesOrdersStyle', Locked = true;
                    ToolTip = 'Specifies the number of approved sales orders in the company.';
                }
            }
            group(ApprovedPurchaseOrders)
            {
                Caption = 'ApprovedPurchaseOrders', Locked = true;
                field(ApprovedPurchaseOrdersAmount; ApprovedPurchaseOrdersAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'ApprovedPurchaseOrdersAmount', Locked = true;
                    ToolTip = 'Specifies the number of approved purchase orders in the company.';
                }
                field(ApprovedPurchaseOrdersStyle; ApprovedPurchaseOrdersStyle)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'ApprovedPurchaseOrdersStyle', Locked = true;
                    ToolTip = 'Specifies the number of approved purchase orders in the company.';
                }
            }
            group(PurchaseReturnOrders)
            {
                Caption = 'PurchaseReturnOrders', Locked = true;
                field(PurchaseReturnOrdersAmount; PurchaseReturnOrdersAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'PurchaseReturnOrdersAmount', Locked = true;
                    ToolTip = 'Specifies the number of purchase return orders in the company.';
                }
                field(PurchaseReturnOrdersStyle; PurchaseReturnOrdersStyle)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'PurchaseReturnOrdersStyle', Locked = true;
                    ToolTip = 'Specifies the number of purchase return orders in the company.';
                }
            }
            group(SalesReturnOrdersAll)
            {
                Caption = 'SalesReturnOrdersAll', Locked = true;
                field(SalesReturnOrdersAllAmount; SalesReturnOrdersAllAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'SalesReturnOrdersAllAmount', Locked = true;
                    ToolTip = 'Specifies the number of sales return orders in the company.';
                }
                field(SalesReturnOrdersAllStyle; SalesReturnOrdersAllStyle)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'SalesReturnOrdersAllStyle', Locked = true;
                    ToolTip = 'Specifies the number of sales return orders in the company.';
                }
            }
            group(CustomersBlocked)
            {
                Caption = 'CustomersBlocked', Locked = true;
                field(CustomersBlockedAmount; CustomersBlockedAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'CustomersBlockedAmount', Locked = true;
                    ToolTip = 'Specifies the number of customers with a status of Blocked in the company.';
                }
                field(CustomersBlockedStyle; CustomersBlockedStyle)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'CustomersBlockedStyle', Locked = true;
                    ToolTip = 'Specifies the number of customers with a status of Blocked in the company.';
                }
            }
            group(NewIncomingDocuments)
            {
                Caption = 'NewIncomingDocuments', Locked = true;
                field(NewIncomingDocumentsAmount; NewIncomingDocumentsAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'NewIncomingDocumentsAmount', Locked = true;
                    ToolTip = 'Specifies the number of new incoming documents in the company. The documents are filtered by today''s date.';
                }
                field(NewIncomingDocumentsStyle; NewIncomingDocumentsStyle)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'NewIncomingDocumentsStyle', Locked = true;
                    ToolTip = 'Specifies the number of new incoming documents in the company. The documents are filtered by today''s date.';
                }
            }
            group(ApprovedIncomingDocuments)
            {
                Caption = 'ApprovedIncomingDocuments', Locked = true;
                field(ApprovedIncomingDocumentsAmount; ApprovedIncomingDocumentsAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'ApprovedIncomingDocumentsAmount', Locked = true;
                    ToolTip = 'Specifies the number of approved incoming documents in the company. The documents are filtered by today''s date.';
                }
                field(ApprovedIncomingDocumentsStyle; ApprovedIncomingDocumentsStyle)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'ApprovedIncomingDocumentsStyle', Locked = true;
                    ToolTip = 'Specifies the number of approved incoming documents in the company. The documents are filtered by today''s date.';
                }
            }
            group(OCRPending)
            {
                Caption = 'OCRPending', Locked = true;
                field(OCRPendingAmount; OCRPendingAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'OCRPendingAmount', Locked = true;
                    ToolTip = 'Specifies the number of incoming document records whose creation by the OCR service is pending.';
                }
                field(OCRPendingStyle; OCRPendingStyle)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'OCRPendingStyle', Locked = true;
                    ToolTip = 'Specifies the number of incoming document records whose creation by the OCR service is pending.';
                }
            }
            group(OCRCompleted)
            {
                Caption = 'OCRCompleted', Locked = true;
                field(OCRCompletedAmount; OCRCompletedAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'OCRCompletedAmount', Locked = true;
                    ToolTip = 'Specifies that incoming document records that have been created by the OCR service.';
                }
                field(OCRCompletedStyle; OCRCompletedStyle)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'OCRCompletedStyle', Locked = true;
                    ToolTip = 'Specifies that incoming document records that have been created by the OCR service.';
                }
            }
            group(RequestsToApprove)
            {
                Caption = 'RequestsToApprove', Locked = true;
                field(RequeststoApproveAmount; RequeststoApproveAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'RequeststoApproveAmount', Locked = true;
                    ToolTip = 'Specifies the number of requests that need approval.';
                }
                field(RequestsToApproveStyle; RequestsToApproveStyle)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'RequestsToApproveStyle', Locked = true;
                    ToolTip = 'Specifies the number of requests that need approval.';
                }
            }
            group(RequestsSentForApproval)
            {
                Caption = 'RequestsSentForApproval', Locked = true;
                field(RequestsSentForApprovalAmount; RequestsSentForApprovalAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'RequestsSentForApprovalAmount', Locked = true;
                    ToolTip = 'Specifies the number of requests that have been sent for approval.';
                }
                field(RequestsSentForApprovalStyle; RequestsSentForApprovalStyle)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'RequestsSentForApprovalStyle', Locked = true;
                    ToolTip = 'Specifies the number of requests that have been sent for approval.';
                }
            }
            group(CashAccountsBalance)
            {
                Caption = 'CashAccountsBalance', Locked = true;
                field(CashAccountsBalanceAmount; CashAccountsBalanceAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'CashAccountsBalanceAmount', Locked = true;
                    ToolTip = 'Specifies the sum total of the cash accounts in the company.';
                }
                field(CashAccountsBalanceStyle; CashAccountsBalanceStyle)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'CashAccountsBalanceStyle', Locked = true;
                    ToolTip = 'Specifies the sum total of the cash accounts in the company.';
                }

                field(CashAccountsBalanceAmountDecimal; CashAccountsBalanceAmountDecimal)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'CashAccountsBalanceStyle', Locked = true;
                    ToolTip = 'Specifies the sum total of the cash accounts in the company.';
                }
            }
            group(LastDepreciatedPostedDate)
            {
                Caption = 'LastDepreciatedPostedDate', Locked = true;
                field(LastDepreciatedPostedDateAmount; LastDepreciatedPostedDateAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'LastDepreciatedPostedDateAmount', Locked = true;
                    ToolTip = 'Specifies the last depreciation posted date.';
                }
                field(LastDepreciatedPostedDateStyle; LastDepreciatedPostedDateStyle)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'LastDepreciatedPostedDateStyle', Locked = true;
                    ToolTip = 'Specifies the last depreciation posted date.';
                }
            }
            group(LastLoginDate)
            {
                Caption = 'LastLoginDate', Locked = true;
                field(LastLoginDateAmount; LastLoginDateAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'LastLoginDateAmount', Locked = true;
                    ToolTip = 'Specifies the last login date for the user.';
                }
                field(LastLoginDateStyle; LastLoginDateStyle)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'LastLoginDateStyle', Locked = true;
                    ToolTip = 'Specifies the last login date for the user.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        SetAccountantPortalFields();
        GetLastLoginDate();
    end;

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
            Commit();
        end;
        Rec.SetFilter("Due Date Filter", '<=%1', Today);
        Rec.SetFilter("Overdue Date Filter", '<%1', Today);
        Rec.SetFilter("Due Next Week Filter", '%1..%2', CalcDate('<1D>', Today), CalcDate('<1W>', Today));
    end;

    var
        ActivitiesMgt: Codeunit "Activities Mgt.";
        OverduePurchaseDocumentsAmount: Text;
        OverduePurchaseDocumentsStyle: Enum "Cues And KPIs Style";
        PurchaseDiscountsNextWeekAmount: Text;
        PurchaseDiscountsNextWeekStyle: Enum "Cues And KPIs Style";
        OverdueSalesDocumentsAmount: Text;
        OverdueSalesDocumentsStyle: Enum "Cues And KPIs Style";
        PurchaseDocumentsDueTodayAmount: Text;
        PurchaseDocumentsDueTodayStyle: Enum "Cues And KPIs Style";
        VendorsPaymentsOnHoldAmount: Text;
        VendorsPaymentsOnHoldStyle: Enum "Cues And KPIs Style";
        POsPendingApprovalAmount: Text;
        POsPendingApprovalStyle: Enum "Cues And KPIs Style";
        SOsPendingApprovalAmount: Text;
        SOsPendingApprovalStyle: Enum "Cues And KPIs Style";
        ApprovedSalesOrdersAmount: Text;
        ApprovedSalesOrdersStyle: Enum "Cues And KPIs Style";
        ApprovedPurchaseOrdersAmount: Text;
        ApprovedPurchaseOrdersStyle: Enum "Cues And KPIs Style";
        PurchaseReturnOrdersAmount: Text;
        PurchaseReturnOrdersStyle: Enum "Cues And KPIs Style";
        SalesReturnOrdersAllAmount: Text;
        SalesReturnOrdersAllStyle: Enum "Cues And KPIs Style";
        CustomersBlockedAmount: Text;
        CustomersBlockedStyle: Enum "Cues And KPIs Style";
        NewIncomingDocumentsAmount: Text;
        NewIncomingDocumentsStyle: Enum "Cues And KPIs Style";
        ApprovedIncomingDocumentsAmount: Text;
        ApprovedIncomingDocumentsStyle: Enum "Cues And KPIs Style";
        OCRPendingAmount: Text;
        OCRPendingStyle: Enum "Cues And KPIs Style";
        OCRCompletedAmount: Text;
        OCRCompletedStyle: Enum "Cues And KPIs Style";
        RequeststoApproveAmount: Text;
        RequestsToApproveStyle: Enum "Cues And KPIs Style";
        RequestsSentForApprovalAmount: Text;
        RequestsSentForApprovalStyle: Enum "Cues And KPIs Style";
        CashAccountsBalanceAmount: Text;
        CashAccountsBalanceStyle: Enum "Cues And KPIs Style";
        LastDepreciatedPostedDateAmount: Text;
        LastDepreciatedPostedDateStyle: Enum "Cues And KPIs Style";
        LastLoginDateAmount: Text;
        LastLoginDateStyle: Enum "Cues And KPIs Style";
        CashAccountsBalanceAmountDecimal: Decimal;
        CurrencySymbol: Text[10];

    local procedure SetAccountantPortalFields()
    var
        FinanceCue: Record "Finance Cue";
        GeneralLedgerSetup: Record "General Ledger Setup";
        ApprovalActivitiesCue: Record "Approvals Activities Cue";
        CuesAndKpis: Codeunit "Cues and KPIs";
        AcctWebServicesMgt: Codeunit "Acct. WebServices Mgt.";
        StringConversionManagement: Codeunit StringConversionManagement;
        Justification: Option Right,Left;
        TempString: Text[250];
        UnlimitedTempString: Text;
    begin
        CurrencySymbol := '';
        if GeneralLedgerSetup.Get() then
            CurrencySymbol := GeneralLedgerSetup.GetCurrencySymbol();

        Rec.CalcFields("Overdue Purchase Documents");
        TempString := Format(Rec."Overdue Purchase Documents");
        OverduePurchaseDocumentsAmount := StringConversionManagement.GetPaddedString(TempString, 30, ' ', Justification::Right);
        CuesAndKpis.SetCueStyle(Database::"Finance Cue", FinanceCue.FieldNo("Overdue Purchase Documents"), Rec."Overdue Purchase Documents", OverduePurchaseDocumentsStyle);

        Rec.CalcFields("Purchase Discounts Next Week");
        TempString := Format(Rec."Purchase Discounts Next Week");
        PurchaseDiscountsNextWeekAmount := StringConversionManagement.GetPaddedString(TempString, 30, ' ', Justification::Right);
        CuesAndKpis.SetCueStyle(Database::"Finance Cue", FinanceCue.FieldNo("Purchase Discounts Next Week"), Rec."Purchase Discounts Next Week", PurchaseDiscountsNextWeekStyle);

        Rec.CalcFields("Overdue Sales Documents");
        TempString := Format(Rec."Overdue Sales Documents");
        OverdueSalesDocumentsAmount := StringConversionManagement.GetPaddedString(TempString, 30, ' ', Justification::Right);
        CuesAndKpis.SetCueStyle(Database::"Finance Cue", FinanceCue.FieldNo("Overdue Sales Documents"), Rec."Overdue Sales Documents", OverdueSalesDocumentsStyle);

        Rec.CalcFields("Purchase Documents Due Today");
        TempString := Format(Rec."Purchase Documents Due Today");
        PurchaseDocumentsDueTodayAmount := StringConversionManagement.GetPaddedString(TempString, 30, ' ', Justification::Right);
        CuesAndKpis.SetCueStyle(Database::"Finance Cue", FinanceCue.FieldNo("Purchase Documents Due Today"), Rec."Purchase Documents Due Today", PurchaseDocumentsDueTodayStyle);

        Rec.CalcFields("Vendors - Payment on Hold");
        TempString := Format(Rec."Vendors - Payment on Hold");
        VendorsPaymentsOnHoldAmount := StringConversionManagement.GetPaddedString(TempString, 30, ' ', Justification::Right);
        CuesAndKpis.SetCueStyle(Database::"Finance Cue", FinanceCue.FieldNo("Vendors - Payment on Hold"), Rec."Vendors - Payment on Hold", VendorsPaymentsOnHoldStyle);

        Rec.CalcFields("POs Pending Approval");
        TempString := Format(Rec."POs Pending Approval");
        POsPendingApprovalAmount := StringConversionManagement.GetPaddedString(TempString, 30, ' ', Justification::Right);
        CuesAndKpis.SetCueStyle(Database::"Finance Cue", FinanceCue.FieldNo("POs Pending Approval"), Rec."POs Pending Approval", POsPendingApprovalStyle);

        Rec.CalcFields("SOs Pending Approval");
        TempString := Format(Rec."SOs Pending Approval");
        SOsPendingApprovalAmount := StringConversionManagement.GetPaddedString(TempString, 30, ' ', Justification::Right);
        CuesAndKpis.SetCueStyle(Database::"Finance Cue", FinanceCue.FieldNo("SOs Pending Approval"), Rec."SOs Pending Approval", SOsPendingApprovalStyle);

        Rec.CalcFields("Approved Sales Orders");
        TempString := Format(Rec."Approved Sales Orders");
        ApprovedSalesOrdersAmount := StringConversionManagement.GetPaddedString(TempString, 30, ' ', Justification::Right);
        CuesAndKpis.SetCueStyle(Database::"Finance Cue", FinanceCue.FieldNo("Approved Sales Orders"), Rec."Approved Sales Orders", ApprovedSalesOrdersStyle);

        Rec.CalcFields("Approved Purchase Orders");
        TempString := Format(Rec."Approved Purchase Orders");
        ApprovedPurchaseOrdersAmount := StringConversionManagement.GetPaddedString(TempString, 30, ' ', Justification::Right);
        CuesAndKpis.SetCueStyle(Database::"Finance Cue", FinanceCue.FieldNo("Approved Purchase Orders"), Rec."Approved Purchase Orders", ApprovedPurchaseOrdersStyle);

        Rec.CalcFields("Purchase Return Orders");
        TempString := Format(Rec."Purchase Return Orders");
        PurchaseReturnOrdersAmount := StringConversionManagement.GetPaddedString(TempString, 30, ' ', Justification::Right);
        CuesAndKpis.SetCueStyle(Database::"Finance Cue", FinanceCue.FieldNo("Purchase Return Orders"), Rec."Purchase Return Orders", PurchaseReturnOrdersStyle);

        Rec.CalcFields("Sales Return Orders - All");
        TempString := Format(Rec."Sales Return Orders - All");
        SalesReturnOrdersAllAmount := StringConversionManagement.GetPaddedString(TempString, 30, ' ', Justification::Right);
        CuesAndKpis.SetCueStyle(Database::"Finance Cue", FinanceCue.FieldNo("Sales Return Orders - All"), Rec."Sales Return Orders - All", SalesReturnOrdersAllStyle);

        Rec.CalcFields("Customers - Blocked");
        TempString := Format(Rec."Customers - Blocked");
        CustomersBlockedAmount := StringConversionManagement.GetPaddedString(TempString, 30, ' ', Justification::Right);
        CuesAndKpis.SetCueStyle(Database::"Finance Cue", FinanceCue.FieldNo("Customers - Blocked"), Rec."Customers - Blocked", CustomersBlockedStyle);

        Rec.CalcFields("New Incoming Documents");
        TempString := Format(Rec."New Incoming Documents");
        NewIncomingDocumentsAmount := StringConversionManagement.GetPaddedString(TempString, 30, ' ', Justification::Right);
        CuesAndKpis.SetCueStyle(Database::"Finance Cue", FinanceCue.FieldNo("New Incoming Documents"), Rec."New Incoming Documents", NewIncomingDocumentsStyle);

        Rec.CalcFields("Approved Incoming Documents");
        TempString := Format(Rec."Approved Incoming Documents");
        ApprovedIncomingDocumentsAmount := StringConversionManagement.GetPaddedString(TempString, 30, ' ', Justification::Right);
        CuesAndKpis.SetCueStyle(Database::"Finance Cue", FinanceCue.FieldNo("Approved Incoming Documents"), Rec."Approved Incoming Documents", ApprovedIncomingDocumentsStyle);

        Rec.CalcFields("OCR Pending");
        TempString := Format(Rec."OCR Pending");
        OCRPendingAmount := StringConversionManagement.GetPaddedString(TempString, 30, ' ', Justification::Right);
        CuesAndKpis.SetCueStyle(Database::"Finance Cue", FinanceCue.FieldNo("OCR Pending"), Rec."OCR Pending", OCRPendingStyle);

        Rec.CalcFields("OCR Completed");
        TempString := Format(Rec."OCR Completed");
        OCRCompletedAmount := StringConversionManagement.GetPaddedString(TempString, 30, ' ', Justification::Right);
        CuesAndKpis.SetCueStyle(Database::"Finance Cue", FinanceCue.FieldNo("OCR Completed"), Rec."OCR Completed", OCRCompletedStyle);

        Rec."Cash Accounts Balance" := ActivitiesMgt.CalcCashAccountsBalances();
        CashAccountsBalanceAmountDecimal := Rec."Cash Accounts Balance";
        UnlimitedTempString := AcctWebServicesMgt.FormatAmountString(Rec."Cash Accounts Balance");
        TempString := CopyStr(UnlimitedTempString, 1, 250);
        CashAccountsBalanceAmount := StringConversionManagement.GetPaddedString(TempString, 30, ' ', Justification::Right);
        CuesAndKpis.SetCueStyle(Database::"Finance Cue", FinanceCue.FieldNo("Cash Accounts Balance"), Rec."Cash Accounts Balance", CashAccountsBalanceStyle);

        Rec.CalcFields("Last Depreciated Posted Date");
        TempString := Format(Rec."Last Depreciated Posted Date");
        LastDepreciatedPostedDateAmount := StringConversionManagement.GetPaddedString(TempString, 30, ' ', Justification::Right);
        LastDepreciatedPostedDateStyle := LastDepreciatedPostedDateStyle::None;

        ApprovalActivitiesCue.SetRange("User ID Filter", UserId);
        ApprovalActivitiesCue.CalcFields("Requests to Approve");
        TempString := Format(ApprovalActivitiesCue."Requests to Approve");
        RequeststoApproveAmount := StringConversionManagement.GetPaddedString(TempString, 30, ' ', Justification::Right);
        CuesAndKpis.SetCueStyle(Database::"Approvals Activities Cue", ApprovalActivitiesCue.FieldNo("Requests to Approve"), ApprovalActivitiesCue."Requests to Approve", RequestsToApproveStyle);

        ApprovalActivitiesCue.CalcFields("Requests Sent for Approval");
        TempString := Format(ApprovalActivitiesCue."Requests Sent for Approval");
        RequestsSentForApprovalAmount := StringConversionManagement.GetPaddedString(TempString, 30, ' ', Justification::Right);
        CuesAndKpis.SetCueStyle(Database::"Approvals Activities Cue", ApprovalActivitiesCue.FieldNo("Requests Sent for Approval"), ApprovalActivitiesCue."Requests Sent for Approval", RequestsSentForApprovalStyle);
    end;

    local procedure GetLastLoginDate()
    var
        GLSetup: Record "General Ledger Setup";
        UserSetup: Record "User Setup";
        UserTimeRegister: Record "User Time Register";
        UserSetupFound: Boolean;
        RegisterTime: Boolean;
    begin
        LastLoginDateStyle := LastLoginDateStyle::None;
        if UserId <> '' then begin
            if UserSetup.Get(UserId) then begin
                UserSetupFound := true;
                RegisterTime := UserSetup."Register Time";
            end;
            if not UserSetupFound then
                if GLSetup.Get() then
                    RegisterTime := GLSetup."Register Time";

            if RegisterTime then begin
                UserTimeRegister.SetRange("User ID", UserId);
                if UserTimeRegister.FindFirst() then
                    LastLoginDateAmount := Format(UserTimeRegister.Date)
                else
                    LastLoginDateAmount := Format(Today);
            end else
                LastLoginDateAmount := Format(Today);
        end;
    end;
}

