// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Sales.Customer;
using Microsoft.Service.History;

tableextension 10790 "Service Header ES" extends "Service Header"
{
    fields
    {
        modify("Due Date")
        {
            trigger OnAfterValidate()
            var
                PaymentTerms: Record "Payment Terms";
            begin
                if PaymentTerms.Get("Payment Terms Code") then
                    PaymentTerms.VerifyMaxNoDaysTillDueDate("Due Date", "Document Date", CopyStr(FieldCaption("Due Date"), 1, 50));
            end;
        }

        field(10705; "Corrected Invoice No."; Code[20])
        {
            Caption = 'Corrected Invoice No.';
            DataClassification = CustomerContent;

            trigger OnLookup()
            var
                ServiceInvoiceHeader: Record "Service Invoice Header";
                PostedServiceInvoices: Page "Posted Service Invoices";
            begin
                ServiceInvoiceHeader.SetCurrentKey("No.");
                ServiceInvoiceHeader.SetRange("Bill-to Customer No.", "Bill-to Customer No.");

                PostedServiceInvoices.SetTableView(ServiceInvoiceHeader);
                PostedServiceInvoices.SetRecord(ServiceInvoiceHeader);
                PostedServiceInvoices.LookupMode(true);
                if PostedServiceInvoices.RunModal() = ACTION::LookupOK then begin
                    PostedServiceInvoices.GetRecord(ServiceInvoiceHeader);
                    Validate("Corrected Invoice No.", ServiceInvoiceHeader."No.");
                end;
                Clear(PostedServiceInvoices);
            end;

            trigger OnValidate()
            var
                ServiceInvoiceHeader: Record "Service Invoice Header";
                DoesNotExistErr: Label 'The %1 does not exist. \Identification fields and values:\%1 = %2', Comment = '%1 - field caption, %2 - field value';
            begin
                if "Corrected Invoice No." <> '' then begin
                    ServiceInvoiceHeader.SetCurrentKey("No.");
                    ServiceInvoiceHeader.SetRange("Bill-to Customer No.", "Bill-to Customer No.");
                    ServiceInvoiceHeader.SetRange("No.", "Corrected Invoice No.");
                    if ServiceInvoiceHeader.IsEmpty() then
                        Error(DoesNotExistErr, FieldCaption("Corrected Invoice No."), "Corrected Invoice No.");
                end;
                OnAfterValidateCorrectedInvoiceNoOnSII(Rec);
            end;
        }
        field(10711; "Correction Type"; Option)
        {
            Caption = 'Correction Type';
            DataClassification = CustomerContent;
            OptionCaption = ' ,Replacement,Difference,Removal';
            OptionMembers = " ",Replacement,Difference,Removal;
        }
        field(7000000; "Applies-to Bill No."; Code[20])
        {
            Caption = 'Applies-to Bill No.';
            DataClassification = CustomerContent;
        }
        field(7000001; "Cust. Bank Acc. Code"; Code[20])
        {
            Caption = 'Cust. Bank Acc. Code';
            DataClassification = CustomerContent;
            TableRelation = "Customer Bank Account".Code where("Customer No." = field("Bill-to Customer No."));
        }
#if not CLEANSCHEMA25
        field(7000003; "Pay-at Code"; Code[10])
        {
            Caption = 'Pay-at Code';
            DataClassification = CustomerContent;
            ObsoleteReason = 'Address is taken from the fields Bill-to Address, Bill-to City, etc.';
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
        }
#endif
    }

    /// <summary>
    /// Validates payment terms and calculates due date and payment discount date based on document type and payment terms configuration.
    /// </summary>
    procedure ValidatePaymentTerms()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PaymentTerms: Record "Payment Terms";
        AdjustDueDate: Codeunit "Due Date-Adjust";
    begin
        GeneralLedgerSetup.GetRecordOnce();
        if ("Document Type" <> "Document Type"::"Credit Memo") or
           GeneralLedgerSetup.ShouldCalculatePaymentDiscountOnLines()
        then
            if ("Payment Terms Code" <> '') and ("Document Date" <> 0D) then begin
                PaymentTerms.Get("Payment Terms Code");
                "Due Date" := CalcDate(PaymentTerms."Due Date Calculation", "Document Date");
                AdjustDueDate.SalesAdjustDueDate(
                  "Due Date", "Document Date", PaymentTerms.CalculateMaxDueDate("Document Date"), "Bill-to Customer No.");
                "Pmt. Discount Date" := CalcDate(PaymentTerms."Due Date Calculation", "Document Date");
            end else begin
                "Due Date" := "Document Date";
                AdjustDueDate.SalesAdjustDueDate("Due Date", "Document Date", 99991231D, "Bill-to Customer No.");
                "Pmt. Discount Date" := "Document Date";
            end;
        if ("Document Type" = "Document Type"::"Credit Memo") and ("Payment Terms Code" <> '') then begin
            if PaymentTerms.Code <> "Payment Terms Code" then
                PaymentTerms.Get("Payment Terms Code");
            if not PaymentTerms."Calc. Pmt. Disc. on Cr. Memos" then
                "Pmt. Discount Date" := 0D;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateCorrectedInvoiceNoOnSII(var ServiceHeader: Record "Service Header")
    begin
    end;
}
