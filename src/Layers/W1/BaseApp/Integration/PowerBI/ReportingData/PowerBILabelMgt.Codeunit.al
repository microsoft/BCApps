// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.PowerBI;

using System.Environment.Configuration;
using System.Integration.PowerBI;

codeunit 6302 "Power BI Label Mgt."
{
    // // Codeunit for generating the static values that Power BI reports use for titles or other
    // // text labels. These values are exposed through a web service for page 6318. This approach
    // // lets reports get values translated for the user's locale rather than hardcoding English.


    trigger OnRun()
    begin
    end;

    var
        CRM_SalesOpportuntiesByCompany_KeyTxt: Label 'CRM_SalesOpportuntiesByCompany', Locked = true;
        CRM_SalesOpportuntiesByCompany_ValueTxt: Label 'Estimated Value by Customer Name';
        CRM_CompletedByStatus_KeyTxt: Label 'CRM_CompletedByStatus', Locked = true;
        CRM_CompletedByStatus_ValueTxt: Label 'Completed by Status & Company Name';
        CRM_OpportunityDashboard_KeyTxt: Label 'CRM_OpportunityDashboard', Locked = true;
        CRM_OpportunityDashboard_ValueTxt: Label 'Opportunity Dashboard';
        CRM_Details1_KeyTxt: Label 'CRM_Details1', Locked = true;
        CRM_Details1_ValueTxt: Label 'Back to Report';
        CRM_Details2_KeyTxt: Label 'CRM_Details2', Locked = true;
        CRM_Details2_ValueTxt: Label 'CRM Details';
        CRM_SnapShot_KeyTxt: Label 'CRM_SnapShot', Locked = true;
        CRM_SnapShot_ValueTxt: Label 'Opportunity Snapshot';
        CRM_OpportunitiesValue_KeyTxt: Label 'CRM_OpportunitiesValue', Locked = true;
        CRM_OpportunitiesValue_ValueTxt: Label 'Opportunities - Calculated Current Value';
        CRM_EstimValueByCompanyName_KeyTxt: Label 'CRM_EstimValueByCompanyName', Locked = true;
        CRM_EstimValueByCompanyName_ValueTxt: Label 'Estimated Value by Company Name';
        CRM_CountByStatus_KeyTxt: Label 'CRM_CountByStatus', Locked = true;
        CRM_CountByStatus_ValueTxt: Label 'Count by Status';
        CRM_CountBySalesPerson_KeyTxt: Label 'CRM_CountBySalesperson', Locked = true;
        CRM_CountBySalesPerson_ValueTxt: Label 'Count by Salesperson Name';
        CRM_OpportunitiesEstim_KeyTxt: Label 'CRM_OpportunitiesEstim', Locked = true;
        CRM_OpportunitiesEstim_ValueTxt: Label 'Opportunities - Estimated Value';
        CRM_DateClosed_KeyTxt: Label 'CRM_DateClosed', Locked = true;
        CRM_DateClosed_ValueTxt: Label 'Date Closed';
        CRM_EstCloseDate_KeyTxt: Label 'CRM_EstCloseDate', Locked = true;
        CRM_EstCloseDate_ValueTxt: Label 'Estimated Close Date';
        Finance_NetChangeMargin_KeyTxt: Label 'Finance_NetChangeMargin', Locked = true;
        Finance_NetChangeMargin_ValueTxt: Label 'Actual Net Change by Date & KPI Name';
        Finance_FinancialDashboard_KeyTxt: Label 'Finance_FinancialDashboard', Locked = true;
        Finance_FinancialDashboard_ValueTxt: Label 'Financial Dashboard';
        Finance_NetChangebyDays_KeyTxt: Label 'Finance_NetChangebyDays', Locked = true;
        Finance_NetChangebyDays_ValueTxt: Label 'Net Change by Date & KPI Name';
        Finance_NetChangeRevenueExpInterest_KeyTxt: Label 'Finance_NetChangeRevenueExpendituresInterest', Locked = true;
        Finance_NetChangeRevenueExpInterest_ValueTxt: Label 'Net Change by Date & KPI Name';
        Finance_MiniTrialBalance_KeyTxt: Label 'Finance_MiniTrialBalance', Locked = true;
        Finance_MiniTrialBalance_ValueTxt: Label 'Mini Trial Balance';
        Finance_KPIDetails1_KeyTxt: Label 'Finance_KPI Details1', Locked = true;
        Finance_KPIDetails1_ValueTxt: Label 'Net Change Details';
        Finance_KPIDetails2_KeyTxt: Label 'Finance_KPI Details2', Locked = true;
        Finance_KPIDetails2_ValueTxt: Label 'Back to Report';
        Sales_ItemSales_KeyTxt: Label 'Sales_ItemSales', Locked = true;
        Sales_ItemSales_ValueTxt: Label 'Top 5 Items Sold by Quantity';
        Sales_ItemSalesDashboard_KeyTxt: Label 'Sales_ItemSalesDashboard', Locked = true;
        Sales_ItemSalesDashboard_ValueTxt: Label 'Item Sales Dashboard';
        Sales_CustomerSales_KeyTxt: Label 'Sales_CustomerSales', Locked = true;
        Sales_CustomerSales_ValueTxt: Label 'Top 5 Customers by Sales Amount';
        Sales_CustomerSalesDashboard_KeyTxt: Label 'Sales_CustomerSalesDashboard', Locked = true;
        Sales_CustomerSalesDashboard_ValueTxt: Label 'Customer Sales Dashboard';
        Sales_CustomerSalesTimeline_KeyTxt: Label 'Sales_CustomerSalesTimeline', Locked = true;
        Sales_CustomerSalesTimeline_ValueTxt: Label 'Sales Timeline';
        Sales_Details_SalesDetails1_KeyTxt: Label 'Sales_Details_SalesDetails1', Locked = true;
        Sales_Details_SalesDetails1_ValueTxt: Label 'Back to Report';
        Sales_Details_SalesDetails2_KeyTxt: Label 'Sales_Details_SalesDetails2', Locked = true;
        Sales_Details_SalesDetails2_ValueTxt: Label 'Sales Details';
        Sales_Top10ItemsByQuantity_KeyTxt: Label 'Sales_Top10ItemSales', Locked = true;
        Sales_Top10ItemsByQuantity_ValueTxt: Label 'Top 10 Items Sold by Quantity';
        Sales_Top5Customers_KeyTxt: Label 'Sales_Top5CustSales', Locked = true;
        Sales_Top5Customers_ValueTxt: Label 'Top 5 Customers by Quantity Sold';
        Sales_QuantityByGeneralPostingGroup_KeyTxt: Label 'Sales_QtyByPostingGroup', Locked = true;
        Sales_QuantityByGeneralPostingGroup_ValueTxt: Label 'Quantity Sold by General Product Posting Group';
        Sales_QuantityBySalesPerson_KeyTxt: Label 'Sales_QtyBySalesPerson', Locked = true;
        Sales_QuantityBySalesPerson_ValueTxt: Label 'Quantity Sold by Salesperson Name';
        Sales_CustomerBalances_KeyTxt: Label 'Sales_CustomerBalances', Locked = true;
        Sales_CustomerBalances_ValueTxt: Label 'Customer Balances';
        Sales_BalanceDue_KeyTxt: Label 'Sales_BalanceDue', Locked = true;
        Sales_BalanceDue_ValueTxt: Label 'Balance Due';
        Sales_AvailableCredit_KeyTxt: Label 'Sales_AvailableCredit', Locked = true;
        Sales_AvailableCredit_ValueTxt: Label 'Available Credit';
        Sales_CreditLimit_KeyTxt: Label 'Sales_CreditLimit', Locked = true;
        Sales_CreditLimit_ValueTxt: Label 'Credit Limit';
        ChartOfAccountAnalysis_KeyTxt: Label 'ChartOfAccountAnalysis', Locked = true;
        ChartOfAccountAnalysis_ValueTxt: Label 'Chart of Account Analysis';
        IncomeStatement_KeyTxt: Label 'IncomeStatement', Locked = true;
        IncomeStatement_ValueTxt: Label 'Income Statement';
        BalanceSheet_KeyTxt: Label 'BalanceSheet', Locked = true;
        BalanceSheet_ValueTxt: Label 'Balance Sheet';
        JobsProfit_KeyTxt: Label 'JobsProfit', Locked = true;
        JobsProfit_ValueTxt: Label 'Cost vs. Invoiced Amount with Profit';
        JobsDashboard_KeyTxt: Label 'JobsDashboard', Locked = true;
        JobsDashboard_ValueTxt: Label 'Jobs Dashboard';
        VendorList_VendorPurchases_KeyTxt: Label 'VendorList_VendorPurchases', Locked = true;
        VendorList_VendorPurchases_ValueTxt: Label 'Vendor Purchases';
        VendorList_PurchaseInvoiceList_KeyTxt: Label 'VendorList_PurchaseInvoiceList', Locked = true;
        VendorList_PurchaseInvoiceList_ValueTxt: Label 'Document Number';

        // Telemetry labels
        LabelsGeneratedTelemetryTxt: Label 'Retrieving Power BI labels for language "%1" (system language is "%2").', Locked = true;

    procedure GetReportLabelsForUserLanguage(var TempPowerBIReportLabels: Record "Power BI Report Labels" temporary; UserSID: Guid)
    var
        UserPersonalization: Record "User Personalization";
        PowerBIServiceMgt: Codeunit "Power BI Service Mgt.";
        LanguageChanged: Boolean;
        PreviousLanguage: Integer;
    begin
        // Web Service sessions run on the language specified in the Accept-Language HTTP header, or en-us if none is specified.
        // Power BI reports using these labels have no mean to specify an Accept-Language header, so we should instead use the user language.
        if UserPersonalization.Get(UserSID) and (UserPersonalization."Language ID" <> 0) then begin
            PreviousLanguage := GlobalLanguage();
            GlobalLanguage(UserPersonalization."Language ID");
            LanguageChanged := true;
        end;

        Session.LogMessage('0000EKF', StrSubstNo(LabelsGeneratedTelemetryTxt, UserPersonalization."Language ID", PreviousLanguage),
            Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiServiceMgt.GetPowerBiTelemetryCategory());

        GetReportLabels(TempPowerBIReportLabels);
        OnAfterGeneratePowerBILabels(TempPowerBIReportLabels);

        if LanguageChanged then
            GlobalLanguage(PreviousLanguage);
    end;

    procedure GetReportLabels(var TempPowerBIReportLabels: Record "Power BI Report Labels" temporary)
    begin
        // Fills the given temp table with all the default key-value pairs hardcoded into this codeunit.
        // Key text should always be locked, and Value text should always be translated.
        InsertLabel(TempPowerBIReportLabels, CRM_SalesOpportuntiesByCompany_KeyTxt, CRM_SalesOpportuntiesByCompany_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, CRM_CompletedByStatus_KeyTxt, CRM_CompletedByStatus_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, CRM_OpportunityDashboard_KeyTxt, CRM_OpportunityDashboard_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, CRM_Details1_KeyTxt, CRM_Details1_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, CRM_Details2_KeyTxt, CRM_Details2_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, CRM_SnapShot_KeyTxt, CRM_SnapShot_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, CRM_OpportunitiesValue_KeyTxt, CRM_OpportunitiesValue_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, CRM_EstimValueByCompanyName_KeyTxt, CRM_EstimValueByCompanyName_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, CRM_CountByStatus_KeyTxt, CRM_CountByStatus_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, CRM_CountBySalesPerson_KeyTxt, CRM_CountBySalesPerson_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, CRM_OpportunitiesEstim_KeyTxt, CRM_OpportunitiesEstim_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, CRM_DateClosed_KeyTxt, CRM_DateClosed_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, CRM_EstCloseDate_KeyTxt, CRM_EstCloseDate_ValueTxt);

        InsertLabel(TempPowerBIReportLabels, Finance_NetChangeMargin_KeyTxt, Finance_NetChangeMargin_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, Finance_FinancialDashboard_KeyTxt, Finance_FinancialDashboard_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, Finance_NetChangebyDays_KeyTxt, Finance_NetChangebyDays_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, Finance_NetChangeRevenueExpInterest_KeyTxt, Finance_NetChangeRevenueExpInterest_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, Finance_MiniTrialBalance_KeyTxt, Finance_MiniTrialBalance_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, Finance_KPIDetails1_KeyTxt, Finance_KPIDetails1_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, Finance_KPIDetails2_KeyTxt, Finance_KPIDetails2_ValueTxt);

        InsertLabel(TempPowerBIReportLabels, Sales_ItemSales_KeyTxt, Sales_ItemSales_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, Sales_ItemSalesDashboard_KeyTxt, Sales_ItemSalesDashboard_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, Sales_CustomerSales_KeyTxt, Sales_CustomerSales_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, Sales_CustomerSalesDashboard_KeyTxt, Sales_CustomerSalesDashboard_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, Sales_CustomerSalesTimeline_KeyTxt, Sales_CustomerSalesTimeline_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, Sales_Details_SalesDetails1_KeyTxt, Sales_Details_SalesDetails1_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, Sales_Details_SalesDetails2_KeyTxt, Sales_Details_SalesDetails2_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, Sales_Top10ItemsByQuantity_KeyTxt, Sales_Top10ItemsByQuantity_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, Sales_Top5Customers_KeyTxt, Sales_Top5Customers_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, Sales_QuantityByGeneralPostingGroup_KeyTxt, Sales_QuantityByGeneralPostingGroup_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, Sales_QuantityBySalesPerson_KeyTxt, Sales_QuantityBySalesPerson_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, Sales_CustomerBalances_KeyTxt, Sales_CustomerBalances_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, Sales_BalanceDue_KeyTxt, Sales_BalanceDue_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, Sales_AvailableCredit_KeyTxt, Sales_AvailableCredit_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, Sales_CreditLimit_KeyTxt, Sales_CreditLimit_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, ChartOfAccountAnalysis_KeyTxt, ChartOfAccountAnalysis_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, IncomeStatement_KeyTxt, IncomeStatement_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, BalanceSheet_KeyTxt, BalanceSheet_ValueTxt);

        InsertLabel(TempPowerBIReportLabels, JobsProfit_KeyTxt, JobsProfit_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, JobsDashboard_KeyTxt, JobsDashboard_ValueTxt);

        InsertLabel(TempPowerBIReportLabels, VendorList_VendorPurchases_KeyTxt, VendorList_VendorPurchases_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, VendorList_PurchaseInvoiceList_KeyTxt, VendorList_PurchaseInvoiceList_ValueTxt);
    end;

    local procedure InsertLabel(var TempPowerBIReportLabels: Record "Power BI Report Labels" temporary; LabelName: Text[100]; LabelText: Text[250])
    begin
        // Inserts the given key-value pair into the temp table.
        TempPowerBIReportLabels."Label ID" := LabelName;
        TempPowerBIReportLabels."Text Value" := LabelText;
        TempPowerBIReportLabels.Insert();
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterGeneratePowerBILabels(var PowerBIReportLabels: Record "Power BI Report Labels" temporary)
    begin
    end;
}

