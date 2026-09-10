// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Bank.BankAccount;
using Microsoft.CRM.Team;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.HumanResources.Employee;
using Microsoft.Sales.Setup;
using Microsoft.Utilities;
using System.Security.User;

reportextension 11708 "Std. Sales - Pro Forma Inv CZL" extends "Standard Sales - Pro Forma Inv"
{
    dataset
    {
        modify(Header)
        {
            trigger OnAfterAfterGetRecord()
            begin
                FormatDocumentFieldsCZL(Header);
                FormatShipToAddressCZL(Header);
                GetSalespersonInfoCZL(Header);
                GetEmployeeInfoCZL(Header);
                CalcVATAmountLinesCZL(Header);

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
            column(SalespersonPhoneNo_CZL; SalespersonPhoneNoCZL)
            {
            }
            column(SalespersonEMail_CZL; SalespersonEMailCZL)
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
            column(VATBaseLbl_CZL; VATBaseLbl)
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
            column(DocumentDateCaption_CZL; Header.FieldCaption("Document Date"))
            {
            }
            column(DueDateCaption_CZL; Header.FieldCaption("Due Date"))
            {
            }
            column(PaymentTermsLbl_CZL; PaymentTermsLbl)
            {
            }
            column(PaymentTermsDesc_CZL; PaymentTermsDescriptionCZL)
            {
            }
            column(PaymentMethodLbl_CZL; PaymentMethodLbl)
            {
            }
            column(PaymentMethodDesc_CZL; PaymentMethodDescriptionCZL)
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
            column(CompanyLogoPosition_CZL; CompanyLogoPositionCZL)
            {
            }
            column(ShipToAddress1_CZL; ShipToAddrCZL[1])
            {
            }
            column(ShipToAddress2_CZL; ShipToAddrCZL[2])
            {
            }
            column(ShipToAddress3_CZL; ShipToAddrCZL[3])
            {
            }
            column(ShipToAddress4_CZL; ShipToAddrCZL[4])
            {
            }
            column(ShipToAddress5_CZL; ShipToAddrCZL[5])
            {
            }
            column(ShipToAddress6_CZL; ShipToAddrCZL[6])
            {
            }
        }
        add(Line)
        {
            column(UnitOfMeasure_CZL; Line."Unit of Measure")
            {
            }
            column(Type_Line_CZL; Format(Line.Type, 0, 2))
            {
            }
            column(LineNo_Line_CZL; Line."Line No.")
            {
            }
            column(ItemNo_Line_CZL; Line."No.")
            {
            }
            column(LineDiscountPct_CZL; Line."Line Discount %")
            {
            }
            column(ItemNoCaption_CZL; Line.FieldCaption("No."))
            {
            }
            column(DescriptionCaption_CZL; Line.FieldCaption(Description))
            {
            }
        }
        addbefore(Totals)
        {
            dataitem(VATAmountLineCZL; "VAT Amount Line")
            {
                DataItemTableView = sorting("VAT Identifier", "VAT Calculation Type", "Tax Group Code", "Use Tax", Positive);
                UseTemporary = true;
                column(VATIdentifier_VatAmountLine_CZL; "VAT Identifier")
                {
                }
                column(VATPct_VatAmountLine_CZL; "VAT %")
                {
                    DecimalPlaces = 0 : 5;
                }
                column(VATBase_VatAmountLine_CZL; "VAT Base")
                {
                    AutoFormatExpression = Header."Currency Code";
                    AutoFormatType = 1;
                }
                column(VATAmount_VatAmountLine_CZL; "VAT Amount")
                {
                    AutoFormatExpression = Header."Currency Code";
                    AutoFormatType = 1;
                }
                column(VATBaseLCY_VatAmountLine_CZL; VATBaseLCYCZL)
                {
                    AutoFormatType = 1;
                }
                column(VATAmountLCY_VatAmountLine_CZL; VATAmountLCYCZL)
                {
                    AutoFormatType = 1;
                }

                trigger OnAfterGetRecord()
                begin
                    VATBaseLCYCZL :=
                      GetBaseLCY(
                        Header."Posting Date", Header."Currency Code",
                        Header."Currency Factor");
                    VATAmountLCYCZL :=
                      GetAmountLCY(
                        Header."Posting Date", Header."Currency Code",
                        Header."Currency Factor");
                end;

                trigger OnPreDataItem()
                begin
                    Clear(VATBaseLCYCZL);
                    Clear(VATAmountLCYCZL);
                end;
            }
        }
    }

    rendering
    {
        layout("StdSalesProFormaInv.rdl CZL")
        {
            Type = RDLC;
            LayoutFile = './Src/ReportExtensions/StdSalesProFormaInv.rdl';
            Caption = 'Standard Sales Pro Forma Invoice CZ (RDLC)';
            Summary = 'The Standard Sales Pro Forma Invoice CZ (RDLC) provides a detailed layout.';
        }
    }

    trigger OnPreReport()
    begin
        GeneralLedgerSetupCZL.Get();
        SalesSetupCZL.Get();
        CompanyLogoPositionCZL := SalesSetupCZL."Logo Position on Documents";
    end;

    var
        CurrencyCZL: Record Currency;
        CurrencyExchangeRateCZL: Record "Currency Exchange Rate";
        GeneralLedgerSetupCZL: Record "General Ledger Setup";
        SalesSetupCZL: Record "Sales & Receivables Setup";
        FormatDocumentMgtCZL: Codeunit "Format Document Mgt. CZL";
        FormatAddressCZL: Codeunit "Format Address";
        PaymentSymbolCZL: array[2] of Text;
        PaymentSymbolLabelCZL: array[2] of Text;
        ShipToAddrCZL: array[8] of Text[100];
        DocFooterTextCZL: Text[1000];
        ExchRateTextCZL: Text[50];
        ReasonCodeDescriptionCZL: Text[100];
        PaymentTermsDescriptionCZL: Text[100];
        PaymentMethodDescriptionCZL: Text[100];
        CurrencyCodeCZL: Code[10];
        SalespersonPhoneNoCZL: Text[30];
        SalespersonEMailCZL: Text[80];
        EmployeeFullNameCZL: Text[100];
        EmployeePhoneNoCZL: Text[30];
        EmployeeEMailCZL: Text[80];
        CalculatedExchRateCZL: Decimal;
        VATBaseLCYCZL: Decimal;
        VATAmountLCYCZL: Decimal;
        CompanyLogoPositionCZL: Integer;
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
        PaymentTermsLbl: Label 'Payment Terms';
        PaymentMethodLbl: Label 'Payment Method';
        DocumentNoLbl: Label 'No.';
        VATBaseLbl: Label 'VAT Base';

    local procedure FormatDocumentFieldsCZL(SalesHeader: Record "Sales Header")
    var
        PaymentTerms: Record "Payment Terms";
        PaymentMethod: Record "Payment Method";
        ReasonCode: Record "Reason Code";
        FormatDocument: Codeunit "Format Document";
    begin
        FormatDocument.SetPaymentTerms(PaymentTerms, SalesHeader."Payment Terms Code", SalesHeader."Language Code");
        PaymentTermsDescriptionCZL := PaymentTerms.Description;
        FormatDocument.SetPaymentMethod(PaymentMethod, SalesHeader."Payment Method Code", SalesHeader."Language Code");
        PaymentMethodDescriptionCZL := PaymentMethod.Description;
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

    local procedure CalcVATAmountLinesCZL(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        VATAmountLineCZL.DeleteAll();
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.CalcVATAmountLines(0, SalesHeader, SalesLine, VATAmountLineCZL);
    end;

    local procedure FormatShipToAddressCZL(SalesHeader: Record "Sales Header")
    var
        CustAddr: array[8] of Text[100];
    begin
        FormatAddressCZL.SalesHeaderBillTo(CustAddr, SalesHeader);
        FormatAddressCZL.SalesHeaderShipTo(ShipToAddrCZL, CustAddr, SalesHeader);
    end;

    local procedure GetSalespersonInfoCZL(SalesHeader: Record "Sales Header")
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        SalespersonPhoneNoCZL := '';
        SalespersonEMailCZL := '';
        if SalespersonPurchaser.Get(SalesHeader."Salesperson Code") then begin
            SalespersonPhoneNoCZL := SalespersonPurchaser."Phone No.";
            SalespersonEMailCZL := SalespersonPurchaser."E-Mail";
        end;
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
