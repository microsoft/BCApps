// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

using Microsoft.Integration.Dataverse;
using Microsoft.Sales.Document;

page 5380 "CRM Sales Order"
{
    Caption = 'Sales Order - Microsoft Dynamics 365 Sales';
    Editable = false;
    PageType = Document;
    SourceTable = "CRM Salesorder";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(OrderNumber; Rec.OrderNumber)
                {
                    ApplicationArea = Suite;
                    Caption = 'Order ID';
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection. ';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Suite;
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of the record.';
                }
                field(Account; CRMAccountName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Account';
                    ToolTip = 'Specifies the coupled Dynamics 365 Sales account.';

                    trigger OnDrillDown()
                    var
                        CRMAccount: Record "CRM Account";
                    begin
                        CRMAccount.SetRange(StateCode, CRMAccount.StateCode::Active);
                        PAGE.Run(PAGE::"CRM Account List", CRMAccount);
                    end;
                }
                field(Contact; CRMContactName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Contact';
                    ToolTip = 'Specifies the contact person at the customer.';

                    trigger OnDrillDown()
                    var
                        CRMContact: Record "CRM Contact";
                    begin
                        CRMContact.SetRange(AccountId, Rec.AccountId);
                        CRMContact.SetRange(StateCode, CRMContact.StateCode::Active);
                        PAGE.Run(PAGE::"CRM Contact List", CRMContact);
                    end;
                }
                field("Date Fulfilled"; Rec.DateFulfilled)
                {
                    ApplicationArea = Suite;
                    Caption = 'Date Fulfilled';
                    ToolTip = 'Specifies when the sales order was delivered.';
                }
                field(StateCode; Rec.StateCode)
                {
                    ApplicationArea = Suite;
                    Caption = 'Status';
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection.';
                }
                field(StatusCode; Rec.StatusCode)
                {
                    ApplicationArea = Suite;
                    Caption = 'Status Reason';
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection.';
                }
                field(Opportunity; Rec.OpportunityIdName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Opportunity';
                    ToolTip = 'Specifies the sales opportunity that is coupled to this Dynamics 365 Sales opportunity.';

                    trigger OnDrillDown()
                    var
                        CRMOpportunity: Record "CRM Opportunity";
                    begin
                        CRMOpportunity.SetRange(AccountId, Rec.AccountId);
                        PAGE.Run(PAGE::"CRM Opportunity List", CRMOpportunity);
                    end;
                }
                field(Quote; Rec.QuoteIdName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Quote';
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection. ';

                    trigger OnDrillDown()
                    var
                        CRMQuote: Record "CRM Quote";
                    begin
                        CRMQuote.SetRange(AccountId, Rec.AccountId);
                        CRMQuote.SetRange(StateCode, CRMQuote.StateCode::Active);
                        PAGE.Run(PAGE::"CRM Sales Quote List", CRMQuote);
                    end;
                }
            }
            part(Lines; "CRM Sales Order Subform")
            {
                ApplicationArea = Suite;
                Caption = 'Lines';
                Editable = false;
                SubPageLink = SalesOrderId = field(SalesOrderId);
            }
            group(Invoicing)
            {
                Caption = 'Invoicing';
                field(PaymentTermsCode; Rec.PaymentTermsCodeEnum)
                {
                    ApplicationArea = Suite;
                    Caption = 'Payment Terms';
                    ToolTip = 'Specifies the payment terms that you select from on customer cards to define when the customer must pay, such as within 14 days.';
                }
                field("Price List"; Rec.PriceLevelIdName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Price List';
                    ToolTip = 'Specifies a list of your items and their prices, for example, to send to customers. You can create the list for specific customers, campaigns, currencies, or other criteria.';

                    trigger OnDrillDown()
                    var
                        CRMPricelevel: Record "CRM Pricelevel";
                    begin
                        CRMPricelevel.SetRange(TransactionCurrencyId, Rec.TransactionCurrencyId);
                        CRMPricelevel.SetRange(StateCode, CRMPricelevel.StateCode::Active);
                        PAGE.Run(PAGE::"CRM Pricelevel List");
                    end;
                }
                field(IsPriceLocked; Rec.IsPriceLocked)
                {
                    ApplicationArea = Suite;
                    Caption = 'Prices Locked';
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection. ';
                }
                field(TotalAmount; Rec.TotalAmount)
                {
                    ApplicationArea = Suite;
                    Caption = 'Total Amount';
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection. ';
                }
                field(TotalLineItemAmount; Rec.TotalLineItemAmount)
                {
                    ApplicationArea = Suite;
                    Caption = 'Total Detail Amount';
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection. ';
                }
                field(TotalAmountLessFreight; Rec.TotalAmountLessFreight)
                {
                    ApplicationArea = Suite;
                    Caption = 'Total Pre-Freight Amount';
                    ToolTip = 'Specifies data from a corresponding field in a Dynamics 365 Sales entity. ';
                }
                field(TotalDiscountAmount; Rec.TotalDiscountAmount)
                {
                    ApplicationArea = Suite;
                    Caption = 'Total Discount Amount';
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection. ';
                }
                field(TotalTax; Rec.TotalTax)
                {
                    ApplicationArea = Suite;
                    Caption = 'Total Tax';
                    ToolTip = 'Specifies the sum of TAX amounts on all lines in the document.';
                }
                field(Currency; Rec.TransactionCurrencyIdName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Currency';
                    ToolTip = 'Specifies the currency that amounts are shown in.';

                    trigger OnDrillDown()
                    var
                        CRMTransactioncurrency: Record "CRM Transactioncurrency";
                    begin
                        CRMTransactioncurrency.SetRange(StateCode, CRMTransactioncurrency.StateCode::Active);
                        PAGE.Run(PAGE::"CRM TransactionCurrency List", CRMTransactioncurrency);
                    end;
                }
                field(DiscountAmount; Rec.DiscountAmount)
                {
                    ApplicationArea = Suite;
                    Caption = 'Order Discount Amount';
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection. ';
                }
                field(DiscountPercentage; Rec.DiscountPercentage)
                {
                    ApplicationArea = Suite;
                    Caption = 'Order Discount (%)';
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection. ';
                }
                field(BillTo_Name; Rec.BillTo_Name)
                {
                    ApplicationArea = Suite;
                    Caption = 'Bill To Name';
                    ToolTip = 'Specifies the name at the address that the invoice will be sent to.';
                }
                field(BillTo_ContactName; Rec.BillTo_ContactName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Bill To Contact Name';
                    Importance = Additional;
                    ToolTip = 'Specifies the contact person at the address that the invoice will be sent to.';
                }
                field(BillTo_Line1; Rec.BillTo_Line1)
                {
                    ApplicationArea = Suite;
                    Caption = 'Bill To Street 1';
                    Importance = Additional;
                    ToolTip = 'Specifies the street of the address that the invoice will be sent to.';
                }
                field(BillTo_Line2; Rec.BillTo_Line2)
                {
                    ApplicationArea = Suite;
                    Caption = 'Bill To Street 2';
                    Importance = Additional;
                    ToolTip = 'Specifies the additional street information of the address that the invoice will be sent to.';
                }
                field(BillTo_Line3; Rec.BillTo_Line3)
                {
                    ApplicationArea = Suite;
                    Caption = 'Bill To Street 3';
                    Importance = Additional;
                    ToolTip = 'Specifies the additional street information of the address that the invoice will be sent to.';
                }
                field(BillTo_City; Rec.BillTo_City)
                {
                    ApplicationArea = Suite;
                    Caption = 'Bill To City';
                    Importance = Additional;
                    ToolTip = 'Specifies the city of the address that the invoice will be sent to.';
                }
                field(BillTo_StateOrProvince; Rec.BillTo_StateOrProvince)
                {
                    ApplicationArea = Suite;
                    Caption = 'Bill To State/Province';
                    Importance = Additional;
                    ToolTip = 'Specifies the state/province of the address that the invoice will be sent to.';
                }
                field(BillTo_Country; Rec.BillTo_Country)
                {
                    ApplicationArea = Suite;
                    Caption = 'Bill To Country/Region';
                    Importance = Additional;
                    ToolTip = 'Specifies the country/region of the address that the invoice will be sent to.';
                }
                field(BillTo_PostalCode; Rec.BillTo_PostalCode)
                {
                    ApplicationArea = Suite;
                    Caption = 'Bill To ZIP/Postal Code';
                    Importance = Additional;
                    ToolTip = 'Specifies the ZIP/postal code of the address that the invoice will be sent to.';
                }
                field(BillTo_Telephone; Rec.BillTo_Telephone)
                {
                    ApplicationArea = Suite;
                    Caption = 'Bill To Phone';
                    ToolTip = 'Specifies the phone number at the address that the invoice will be sent to.';
                }
                field(BillTo_Fax; Rec.BillTo_Fax)
                {
                    ApplicationArea = Suite;
                    Caption = 'Bill To Fax';
                    Importance = Additional;
                    ToolTip = 'Specifies the fax number at the address that the invoice will be sent to.';
                }
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                field(RequestDeliveryBy; Rec.RequestDeliveryBy)
                {
                    ApplicationArea = Suite;
                    Caption = 'Requested Delivery Date';
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection. ';
                }
                field(ShippingMethodCode; Rec.ShippingMethodCodeEnum)
                {
                    ApplicationArea = Suite;
                    Caption = 'Shipping Method';
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection. ';
                }
                field(FreightTermsCode; Rec.FreightTermsCodeEnum)
                {
                    ApplicationArea = Suite;
                    Caption = 'Freight Terms';
                    ToolTip = 'Specifies the shipment method.';
                }
                field(ShipTo_Name; Rec.ShipTo_Name)
                {
                    ApplicationArea = Suite;
                    Caption = 'Ship To Name';
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection. ';
                }
                field(ShipTo_Line1; Rec.ShipTo_Line1)
                {
                    ApplicationArea = Suite;
                    Caption = 'Ship To Street 1';
                    Importance = Additional;
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection. ';
                }
                field(ShipTo_Line2; Rec.ShipTo_Line2)
                {
                    ApplicationArea = Suite;
                    Caption = 'Ship To Street 2';
                    Importance = Additional;
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection.';
                }
                field(ShipTo_Line3; Rec.ShipTo_Line3)
                {
                    ApplicationArea = Suite;
                    Caption = 'Ship To Street 3';
                    Importance = Additional;
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection.';
                }
                field(ShipTo_City; Rec.ShipTo_City)
                {
                    ApplicationArea = Suite;
                    Caption = 'Ship To City';
                    Importance = Additional;
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection.';
                }
                field(ShipTo_StateOrProvince; Rec.ShipTo_StateOrProvince)
                {
                    ApplicationArea = Suite;
                    Caption = 'Ship To State/Province';
                    Importance = Additional;
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection.';
                }
                field(ShipTo_Country; Rec.ShipTo_Country)
                {
                    ApplicationArea = Suite;
                    Caption = 'Ship To Country/Region';
                    Importance = Additional;
                    ToolTip = 'Specifies the country/region of the address.';
                }
                field(ShipTo_PostalCode; Rec.ShipTo_PostalCode)
                {
                    ApplicationArea = Suite;
                    Caption = 'Ship To ZIP/Postal Code';
                    Importance = Additional;
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection.';
                }
                field(ShipTo_Telephone; Rec.ShipTo_Telephone)
                {
                    ApplicationArea = Suite;
                    Caption = 'Ship To Phone';
                    Importance = Additional;
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection.';
                }
                field(ShipTo_Fax; Rec.ShipTo_Fax)
                {
                    ApplicationArea = Suite;
                    Caption = 'Ship to Fax';
                    Importance = Additional;
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection.';
                }
                field(ShipTo_FreightTermsCode; Rec.ShipTo_FreightTermsCode)
                {
                    ApplicationArea = Suite;
                    Caption = 'Ship To Freight Terms';
                    Importance = Additional;
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group(ActionGroupCRM)
            {
                Caption = 'Dynamics 365 Sales';
                Visible = CRMIntegrationEnabled;
                action(CRMGoToSalesOrderHyperlink)
                {
                    ApplicationArea = Suite;
                    Caption = 'Sales Order';
                    Enabled = CRMIntegrationEnabled;
                    Image = CoupledOrder;
                    ToolTip = 'Open the coupled Dynamics 365 Sales sales order.';
                    Visible = CRMIntegrationEnabled;

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        HyperLink(CRMIntegrationManagement.GetCRMEntityUrlFromCRMID(DATABASE::"CRM Salesorder", Rec.SalesOrderId));
                    end;
                }
            }
            group(ActionGroupNAV)
            {
                Caption = 'Business Central';
                Visible = CRMIntegrationEnabled;
                action(NAVOpenSalesOrderCard)
                {
                    ApplicationArea = Suite;
                    Caption = 'Sales Order';
                    Enabled = CRMIsCoupledToRecord;
                    Image = "Order";
                    ToolTip = 'Open the coupled Dynamics 365 Sales sales order.';
                    Visible = CRMIntegrationEnabled;

                    trigger OnAction()
                    var
                        SalesHeader: Record "Sales Header";
                        CRMSalesOrderToSalesOrder: Codeunit "CRM Sales Order to Sales Order";
                    begin
                        if CRMSalesOrderToSalesOrder.GetCoupledSalesHeader(Rec, SalesHeader) then
                            PAGE.RunModal(PAGE::"Sales Order", SalesHeader)
                        else
                            Message(GetLastErrorText);
                        RecalculateRecordCouplingStatus();
                    end;
                }
                action(CreateInNAV)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Create in Business Central';
                    Enabled = CRMIntegrationEnabled and (not CRMIsCoupledToRecord);
                    Image = New;
                    ToolTip = 'Create a sales order in Dynamics 365 that is coupled to the Dynamics 365 Sales entity.';

                    trigger OnAction()
                    var
                        SalesHeader: Record "Sales Header";
                        CRMSalesorder: Record "CRM Salesorder";
                        CRMProductName: Codeunit "CRM Product Name";
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        CRMCouplingManagement: Codeunit "CRM Coupling Management";
                        CRMSalesOrderToSalesOrder: Codeunit "CRM Sales Order to Sales Order";
                    begin
                        if Rec.IsEmpty() then
                            exit;

                        if BidirectionalSalesOrderIntEnabled then begin
                            CRMSalesOrder.SetRange(SalesOrderId, Rec.SalesOrderId);
                            CRMIntegrationManagement.CreateNewRecordsFromSelectedCRMRecords(CRMSalesorder)
                        end else begin
                            Session.LogMessage('0000KVP', StrSubstNo(StartingToCreateSalesOrderTelemetryMsg, CRMProductName.CDSServiceName(), Rec.SalesOrderId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CrmTelemetryCategoryTok);
                            if CRMSalesOrderToSalesOrder.CreateInNAV(Rec, SalesHeader) then begin
                                Session.LogMessage('0000KVQ', StrSubstNo(CommittingAfterCreateSalesOrderTelemetryMsg, CRMProductName.CDSServiceName(), Rec.SalesOrderId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CrmTelemetryCategoryTok);
                                Commit();
                                CRMIsCoupledToRecord := CRMCouplingManagement.IsRecordCoupledToNAV(Rec.SalesOrderId, DATABASE::"Sales Header") and CRMIntegrationEnabled;
                                PAGE.RunModal(PAGE::"Sales Order", SalesHeader);
                            end;
                        end;
                        RecalculateRecordCouplingStatus();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(CreateInNAV_Promoted; CreateInNAV)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        RecalculateRecordCouplingStatus();
    end;

    trigger OnOpenPage()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        CRMIntegrationEnabled := CRMConnectionSetup.IsEnabled();
        BidirectionalSalesOrderIntEnabled := CRMConnectionSetup.IsBidirectionalSalesOrderIntEnabled();
        SetCRMAccountAndContactName();
    end;

    var
        CRMIntegrationEnabled: Boolean;
        CRMIsCoupledToRecord: Boolean;
        BidirectionalSalesOrderIntEnabled: Boolean;
        CRMAccountName: Text[160];
        CRMContactName: Text[160];
        CrmTelemetryCategoryTok: Label 'AL CRM Integration', Locked = true;
        StartingToCreateSalesOrderTelemetryMsg: Label 'Starting to create sales order from %1 order %2 via a page action.', Locked = true;
        CommittingAfterCreateSalesOrderTelemetryMsg: Label 'Committing after processing %1 order %2 via a page action.', Locked = true;

    local procedure SetCRMAccountAndContactName()
    var
        CRMAccount: Record "CRM Account";
        CRMContact: Record "CRM Contact";
        CRMSalesOrderToSalesOrder: Codeunit "CRM Sales Order to Sales Order";
    begin
        if CRMSalesOrderToSalesOrder.GetCRMAccountOfCRMSalesOrder(Rec, CRMAccount) then
            CRMAccountName := CRMAccount.Name;

        if CRMSalesOrderToSalesOrder.GetCRMContactOfCRMSalesOrder(Rec, CRMContact) then
            CRMContactName := CRMContact.FullName;
    end;

    local procedure RecalculateRecordCouplingStatus()
    var
        CRMSalesOrderToSalesOrder: Codeunit "CRM Sales Order to Sales Order";
    begin
        CRMIsCoupledToRecord := CRMIntegrationEnabled;
        if CRMIsCoupledToRecord then
            CRMIsCoupledToRecord := CRMSalesOrderToSalesOrder.CRMIsCoupledToValidRecord(Rec, DATABASE::"Sales Header");
    end;
}

