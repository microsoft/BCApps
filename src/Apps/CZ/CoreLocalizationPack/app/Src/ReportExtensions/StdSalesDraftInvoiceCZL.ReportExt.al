// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.HumanResources.Employee;
using Microsoft.Utilities;
using System.Security.User;

reportextension 11707 "Std. Sales - Draft Invoice CZL" extends "Standard Sales - Draft Invoice"
{
    dataset
    {
        modify(Header)
        {
            trigger OnAfterAfterGetRecord()
            begin
                FormatDocumentFieldsCZL(Header);
                GetEmployeeInfoCZL(Header);

                if Header."Currency Code" = '' then begin
                    CurrencyCZL.InitRoundingPrecision();
                    CurrencyCodeCZL := GeneralLedgerSetupCZL."LCY Code";
                end else begin
                    if not CurrencyCZL.Get(Header."Currency Code") then
                        CurrencyCZL.InitRoundingPrecision();
                    CurrencyCodeCZL := Header."Currency Code";
                end;

                if (Header."VAT Currency Factor CZL" <> 0) and (Header."VAT Currency Factor CZL" <> 1) then begin
                    CurrencyExchangeRateCZL.FindCurrency(Header."Document Date", Header."Currency Code", 1);
                    CalculatedExchRateCZL := Round(1 / Header."VAT Currency Factor CZL" * CurrencyExchangeRateCZL."Exchange Rate Amount", 0.00001);
                    ExchRateTextCZL := StrSubstNo(ExchRateLbl, CalculatedExchRateCZL, GeneralLedgerSetupCZL."LCY Code",
                                        CurrencyExchangeRateCZL."Exchange Rate Amount", Header."Currency Code");
                end else
                    CalculatedExchRateCZL := 1;
            end;
        }
        add(Header)
        {
            column(VendorLbl_CZL; VendorLbl)
            {
            }
            column(CustomerLbl_CZL; CustomerLbl)
            {
            }
            column(ShipToLbl_CZL; ShipToLbl)
            {
            }
            column(SalespersonLbl_CZL; SalespersonLbl)
            {
            }
            column(SalespersonPhoneNo_CZL; SalespersonPurchaser."Phone No.")
            {
            }
            column(SalespersonEMail_CZL; SalespersonPurchaser."E-Mail")
            {
            }
            column(UoMLbl_CZL; UoMLbl)
            {
            }
            column(CreatorLbl_CZL; CreatorLbl)
            {
            }
            column(VATIdentLbl_CZL; VATIdentLbl)
            {
            }
            column(VATLbl_CZL; VATLbl)
            {
            }
            column(DocumentNoLbl_CZL; DocumentNoLbl)
            {
            }
            column(PmntSymbol1_CZL; PaymentSymbolLabelCZL[1])
            {
            }
            column(PmntSymbol2_CZL; PaymentSymbolCZL[1])
            {
            }
            column(PmntSymbol3_CZL; PaymentSymbolLabelCZL[2])
            {
            }
            column(PmntSymbol4_CZL; PaymentSymbolCZL[2])
            {
            }
            column(DocFooterText_CZL; DocFooterTextCZL)
            {
            }
            column(CalculatedExchRate_CZL; CalculatedExchRateCZL)
            {
            }
            column(ExchRateText_CZL; ExchRateTextCZL)
            {
            }
            column(CurrencyCode_CZL; CurrencyCodeCZL)
            {
            }
            column(BankAccountNo_CZL; Header."Bank Account No. CZL")
            {
            }
            column(BankAccountNoCaption_CZL; Header.FieldCaption("Bank Account No. CZL"))
            {
            }
            column(IBAN_CZL; Header."IBAN CZL")
            {
            }
            column(IBANCaption_CZL; Header.FieldCaption("IBAN CZL"))
            {
            }
            column(BIC_CZL; Header."SWIFT Code CZL")
            {
            }
            column(BICCaption_CZL; Header.FieldCaption("SWIFT Code CZL"))
            {
            }
            column(VATDate_CZL; Format(Header."VAT Reporting Date"))
            {
            }
            column(VATDateCaption_CZL; Header.FieldCaption("VAT Reporting Date"))
            {
            }
            column(DocumentDate_CZL; Format(Header."Document Date"))
            {
            }
            column(DueDate_CZL; Format(Header."Due Date"))
            {
            }
            column(RegistrationNo_CZL; Header."Registration Number")
            {
            }
            column(RegistrationNoCaption_CZL; Header.FieldCaption("Registration Number"))
            {
            }
            column(ReasonCode_CZL; ReasonCodeDescriptionCZL)
            {
            }
            column(CopyNo_CZL; CopyNoCZL)
            {
            }
            column(LCYCode_CZL; GeneralLedgerSetupCZL."LCY Code")
            {
            }
            column(EmployeeFullName_CZL; EmployeeFullNameCZL)
            {
            }
            column(EmployeePhoneNo_CZL; EmployeePhoneNoCZL)
            {
            }
            column(EmployeeEMail_CZL; EmployeeEMailCZL)
            {
            }
        }
    }

    rendering
    {
        layout("StdSalesDraftInvoice.rdl CZL")
        {
            Type = RDLC;
            LayoutFile = './Src/ReportExtensions/StdSalesDraftInvoice.rdl';
            Caption = 'Standard Sales Draft Invoice CZ (RDLC)';
            Summary = 'The Standard Sales Draft Invoice CZ (RDLC) provides a detailed layout.';
        }
    }

    trigger OnPreReport()
    begin
        GeneralLedgerSetupCZL.Get();
    end;

    var
        CurrencyCZL: Record Currency;
        CurrencyExchangeRateCZL: Record "Currency Exchange Rate";
        GeneralLedgerSetupCZL: Record "General Ledger Setup";
        FormatDocumentMgtCZL: Codeunit "Format Document Mgt. CZL";
        PaymentSymbolCZL: array[2] of Text;
        PaymentSymbolLabelCZL: array[2] of Text;
        DocFooterTextCZL: Text[1000];
        ExchRateTextCZL: Text[50];
        ReasonCodeDescriptionCZL: Text[100];
        CurrencyCodeCZL: Code[10];
        EmployeeFullNameCZL: Text[100];
        EmployeePhoneNoCZL: Text[30];
        EmployeeEMailCZL: Text[80];
        CalculatedExchRateCZL: Decimal;
        CopyNoCZL: Integer;
        ExchRateLbl: Label 'Exchange Rate %1 %2 / %3 %4', Comment = '%1 = Calculated Exchange Rate, %2 = LCY Code, %3 = Exchange Rate, %4 = Currency Code';
        VendorLbl: Label 'Vendor';
        CustomerLbl: Label 'Customer';
        ShipToLbl: Label 'Ship-to';
        SalespersonLbl: Label 'Salesperson';
        UoMLbl: Label 'UoM';
        CreatorLbl: Label 'Posted by';
        VATIdentLbl: Label 'VAT Recapitulation';
        VATLbl: Label 'VAT';
        DocumentNoLbl: Label 'No.';

    local procedure FormatDocumentFieldsCZL(SalesHeader: Record "Sales Header")
    var
        ReasonCode: Record "Reason Code";
    begin
        if SalesHeader."Reason Code" = '' then
            ReasonCodeDescriptionCZL := ''
        else begin
            ReasonCode.Get(SalesHeader."Reason Code");
            ReasonCodeDescriptionCZL := ReasonCode.Description;
        end;
        FormatDocumentMgtCZL.SetPaymentSymbols(
          PaymentSymbolCZL, PaymentSymbolLabelCZL,
          SalesHeader."Variable Symbol CZL", SalesHeader.FieldCaption("Variable Symbol CZL"),
          SalesHeader."Constant Symbol CZL", SalesHeader.FieldCaption("Constant Symbol CZL"),
          SalesHeader."Specific Symbol CZL", SalesHeader.FieldCaption("Specific Symbol CZL"));
        DocFooterTextCZL := FormatDocumentMgtCZL.GetDocumentFooterText(SalesHeader."Language Code");

        CopyNoCZL := 1;
    end;

    local procedure GetEmployeeInfoCZL(SalesHeader: Record "Sales Header")
    var
        UserSetup: Record "User Setup";
        Employee: Record Employee;
    begin
        EmployeeFullNameCZL := '';
        EmployeePhoneNoCZL := '';
        EmployeeEMailCZL := '';
        if UserSetup.Get(SalesHeader."Assigned User ID") then
            if Employee.Get(UserSetup."Employee No. CZL") then begin
                EmployeeFullNameCZL := CopyStr(Employee.FullName(), 1, MaxStrLen(EmployeeFullNameCZL));
                EmployeePhoneNoCZL := Employee."Phone No.";
                EmployeeEMailCZL := Employee."Company E-Mail";
            end;
    end;
}