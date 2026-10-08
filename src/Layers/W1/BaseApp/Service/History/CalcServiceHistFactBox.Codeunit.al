// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

using Microsoft.Service.Document;

codeunit 9086 "Calc. Service Hist Fact Box"
{
    trigger OnRun()
    var
        ServShptHeader: Record "Service Shipment Header";
        ServInvHeader: Record "Service Invoice Header";
        ServCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceHeaderDocTypeCount: Query "Service Header Doc. Type Count";
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        No: Code[20];
    begin
        Params := Page.GetBackgroundParameters();

        // Sanity check.
        if
            (Params.ContainsKey(GetCustomerNoLabel()) and Params.ContainsKey(GetBillToCustomerNoLbl())) or
            (not Params.ContainsKey(GetCustomerNoLabel()) and not Params.ContainsKey(GetBillToCustomerNoLbl()))
         then
            exit;

        // Setup filters.
        if Params.ContainsKey(GetCustomerNoLabel()) then begin
            No := CopyStr(Params.Get(GetCustomerNoLabel()), 1, MaxStrLen(No));
            ServiceHeaderDocTypeCount.SetRange(Customer_No, No);
            ServShptHeader.SetRange("Customer No.", No);
            ServInvHeader.SetRange("Customer No.", No);
            ServCrMemoHeader.SetRange("Customer No.", No);
        end else begin
            No := CopyStr(Params.Get(GetBillToCustomerNoLbl()), 1, MaxStrLen(No));
            ServiceHeaderDocTypeCount.SetRange(Bill_to_Customer_No, No);
            ServShptHeader.SetRange("Bill-to Customer No.", No);
            ServInvHeader.SetRange("Bill-to Customer No.", No);
            ServCrMemoHeader.SetRange("Bill-to Customer No.", No);
        end;

        ServiceHeaderDocTypeCount.SetFilter(Document_Type, '=Quote|=Order|=Invoice|=Credit Memo');
        ServiceHeaderDocTypeCount.Open();

        while ServiceHeaderDocTypeCount.Read() do
            case ServiceHeaderDocTypeCount.Document_Type of
                ServiceHeaderDocTypeCount.Document_Type::Quote:
                    Results.Add(GetNoOfQuotesLbl(), Format(ServiceHeaderDocTypeCount.DocTypeCount));
                ServiceHeaderDocTypeCount.Document_Type::Order:
                    Results.Add(GetNoOfOrdersLbl(), Format(ServiceHeaderDocTypeCount.DocTypeCount));
                ServiceHeaderDocTypeCount.Document_Type::Invoice:
                    Results.Add(GetNoOfInvoicesLbl(), Format(ServiceHeaderDocTypeCount.DocTypeCount));
                ServiceHeaderDocTypeCount.Document_Type::"Credit Memo":
                    Results.Add(GetNoOfCreditMemosLbl(), Format(ServiceHeaderDocTypeCount.DocTypeCount));
            end;

        ServiceHeaderDocTypeCount.Close();

        Results.Add(GetNoOfPostedShipmentsLbl(), Format(ServShptHeader.Count()));
        Results.Add(GetNoOfPostedInvoicesLbl(), Format(ServInvHeader.Count()));
        Results.Add(GetNoOfPostedCreditMemosLbl(), Format(ServCrMemoHeader.Count()));

        Page.SetBackgroundTaskResult(Results);
    end;

    var
        CustomerNoLbl: label 'Customer No.', Locked = true;
        BillToCustomerNoLbl: label 'Bill-to Customer No.', Locked = true;
        NoOfQuotesLbl: Label 'NoOfQuotes', Locked = true;
        NoOfOrdersLbl: Label 'NoOfOrders', Locked = true;
        NoOfInvoicesLbl: Label 'NoOfInvoices', Locked = true;
        NoOfCreditMemosLbl: Label 'NoOfCreditMemos', Locked = true;
        NoOfPostedShipmentsLbl: Label 'NoOfPostedShipments', Locked = true;
        NoOfPostedInvoicesLbl: Label 'NoOfPostedInvoices', Locked = true;
        NoOfPostedCreditMemosLbl: Label 'NoOfPostedCreditMemos', Locked = true;

    internal procedure GetCustomerNoLabel(): Text
    begin
        exit(CustomerNoLbl);
    end;

    internal procedure GetBillToCustomerNoLbl(): Text
    begin
        exit(BillToCustomerNoLbl);
    end;

    internal procedure GetNoOfQuotesLbl(): Text
    begin
        exit(NoOfQuotesLbl);
    end;

    internal procedure GetNoOfOrdersLbl(): Text
    begin
        exit(NoOfOrdersLbl);
    end;

    internal procedure GetNoOfInvoicesLbl(): Text
    begin
        exit(NoOfInvoicesLbl);
    end;

    internal procedure GetNoOfCreditMemosLbl(): Text
    begin
        exit(NoOfCreditMemosLbl);
    end;

    internal procedure GetNoOfPostedShipmentsLbl(): Text
    begin
        exit(NoOfPostedShipmentsLbl);
    end;

    internal procedure GetNoOfPostedInvoicesLbl(): Text
    begin
        exit(NoOfPostedInvoicesLbl);
    end;

    internal procedure GetNoOfPostedCreditMemosLbl(): Text
    begin
        exit(NoOfPostedCreditMemosLbl);
    end;
}
