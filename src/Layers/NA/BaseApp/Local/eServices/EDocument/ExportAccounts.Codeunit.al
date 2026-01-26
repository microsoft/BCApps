// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Check;
using Microsoft.Bank.Ledger;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using System.IO;
using System.Utilities;

codeunit 27000 "Export Accounts"
{

    var
        TempErrorMessage: Record "Error Message" temporary;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CompanyInfoGlobal: Record "Company Information";
        XmlHelper: Codeunit "Export Accounts Xml Helper";
        GLAccountNames: Dictionary of [Text, Text];
        CustPostGroupReceivableAcc: Dictionary of [Text, Text];
        VendPostGroupPayablesAcc: Dictionary of [Text, Text];
        TestFileName: Text;
        ProgressDialog: Dialog;
        GLAccountTypeErr: Label 'Debit/Credit ''%1'' is not supported in %2.', Comment = '%1 - G/L Account option Both, %2 - G/L Account Record ID';
        InvalidMonthErr: Label 'The Month must be in the range 1-12.';
        InvalidYearErr: Label 'The Year must be in the range 2000-2999.';
        MissingUpdateDateErr: Label 'You need to specify an update date before export.';
        MissingOrderNumberErr: Label 'You need to specify an Order Number before export.';
        NoSATAccountDefinedErr: Label 'You need to specify SAT Account Code on G/L Accounts before export.';
        GLEntryProcessTxt: label 'G/L Entries processed: #1####\', Comment = '#1 - progress in percents';
        NamespaceTxt: Label 'http://www.sat.gob.mx/esquemas/ContabilidadE/1_3/', Locked = true;
        CatalogoNamespaceTxt: Label 'CatalogoCuentas', Locked = true;
        BalanzaNamespaceTxt: Label 'BalanzaComprobacion', Locked = true;
        PolizasNamespaceTxt: Label 'PolizasPeriodo', Locked = true;
        AuxiliaryAccountNamespaceTxt: Label 'AuxiliarCtas', Locked = true;
        CatalogoNodeTxt: Label 'Catalogo', Locked = true;
        BalanzaNodeTxt: Label 'Balanza', Locked = true;
        PolizasNodeTxt: Label 'Polizas', Locked = true;
        AuxiliaryAccountNodeTxt: Label 'AuxiliarCtas', Locked = true;

    procedure ExportChartOfAccounts(Year: Integer; Month: Integer)
    var
        GLAccount: Record "G/L Account";
        AdditionalAttributes: Dictionary of [Text, Text];
    begin
        TempErrorMessage.ClearLog();
        ClearGlobalVariables();
        GLAccount.SetFilter("SAT Account Code", '<>%1', '');

        CreateXMLHeader(CatalogoNodeTxt, CatalogoNamespaceTxt, Year, Month, '1.3', AdditionalAttributes);
        if GLAccount.FindSet() then
            repeat
                TempErrorMessage.LogIfEmpty(GLAccount, GLAccount.FieldNo(Name), TempErrorMessage."Message Type"::Error);

                GLAccount.CalcFields("Debit Amount", "Credit Amount");
                XmlHelper.AddNewNode('Ctas');
                XmlHelper.AddAttribute('CodAgrup', GLAccount."SAT Account Code");
                XmlHelper.AddAttribute('NumCta', GLAccount."No.");
                XmlHelper.AddAttribute('Desc', GLAccount.Name);
                XmlHelper.AddAttribute('Nivel', Format(GLAccount.Indentation + 1));
                case GLAccount."Debit/Credit" of
                    GLAccount."Debit/Credit"::Debit:
                        XmlHelper.AddAttribute('Natur', 'D');
                    GLAccount."Debit/Credit"::Credit:
                        XmlHelper.AddAttribute('Natur', 'A');
                    else
                        TempErrorMessage.LogMessage(
                          GLAccount, GLAccount.FieldNo("Debit/Credit"), TempErrorMessage."Message Type"::Error,
                          StrSubstNo(GLAccountTypeErr, GLAccount."Debit/Credit", GLAccount.RecordId));
                end;
                XmlHelper.FinalizeNode();
            until GLAccount.Next() = 0
        else
            TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, NoSATAccountDefinedErr);

        if not TempErrorMessage.HasErrors(true) then
            SaveXMLToClient(Year, Month, 'CT');
        TempErrorMessage.ShowErrorMessages(false);
    end;

    procedure ExportBalanceSheet(Year: Integer; Month: Integer; DeliveryType: Option Normal,Complementary; UpdateDate: Date; ClosingBalanceSheet: Boolean)
    var
        GLAccount: Record "G/L Account";
        GLAccountBalanceIni: Record "G/L Account";
        GLAccountBalanceFin: Record "G/L Account";
        AdditionalAttributes: Dictionary of [Text, Text];
        StartDate: Date;
        EndDate: Date;
        FileType: Text;
    begin
        TempErrorMessage.ClearLog();
        ClearGlobalVariables();

        if not ClosingBalanceSheet then begin
            StartDate := DMY2Date(1, Month, Year);
            EndDate := CalcDate('<CM>', StartDate);
        end else begin
            StartDate := DMY2Date(1, 1, Year);
            EndDate := ClosingDate(CalcDate('<CY>', DMY2Date(1, 1, Year)));
            Month := 13;
        end;

        CreateXMLHeader(BalanzaNodeTxt, BalanzaNamespaceTxt, Year, Month, '1.3', AdditionalAttributes);

        GLAccount.SetRange("Date Filter", StartDate, EndDate);
        GLAccount.SetFilter("SAT Account Code", '<>%1', '');

        if DeliveryType = DeliveryType::Normal then
            XmlHelper.AddAttribute('TipoEnvio', 'N')
        else begin
            XmlHelper.AddAttribute('TipoEnvio', 'C');
            if UpdateDate = 0D then
                TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, MissingUpdateDateErr);
            XmlHelper.AddAttribute('FechaModBal', FormatDate(UpdateDate));
        end;

        if GLAccount.FindSet() then
            repeat
                GLAccount.CalcFields("Debit Amount", "Credit Amount");

                GLAccountBalanceIni.Get(GLAccount."No.");
                GLAccountBalanceIni.SetFilter("Date Filter", '..%1', ClosingDate(StartDate - 1));
                GLAccountBalanceIni.CalcFields("Balance at Date");

                GLAccountBalanceFin.Get(GLAccount."No.");
                GLAccountBalanceFin.SetFilter("Date Filter", '..%1', EndDate);
                GLAccountBalanceFin.CalcFields("Balance at Date");

                XmlHelper.AddNewNode('Ctas');
                XmlHelper.AddAttribute('NumCta', GLAccount."No.");
                XmlHelper.AddAttribute('SaldoIni', FormatDecimal(GLAccountBalanceIni."Balance at Date"));
                XmlHelper.AddAttribute('Debe', FormatDecimal(GLAccount."Debit Amount"));
                XmlHelper.AddAttribute('Haber', FormatDecimal(GLAccount."Credit Amount"));
                XmlHelper.AddAttribute('SaldoFin', FormatDecimal(GLAccountBalanceFin."Balance at Date"));
                XmlHelper.FinalizeNode();
            until GLAccount.Next() = 0;

        if DeliveryType = DeliveryType::Normal then
            FileType := 'BN'
        else
            FileType := 'BC';

        if not TempErrorMessage.HasErrors(true) then
            SaveXMLToClient(Year, Month, FileType);

        TempErrorMessage.ShowErrorMessages(false);
    end;

    procedure ExportTransactions(Year: Integer; Month: Integer; RequestType: Option AF,FC,DE,CO; OrderNumber: Text[13]; ProcessNumber: Text[14])
    var
        GLEntry: Record "G/L Entry";
        StartDate: Date;
        EndDate: Date;
        PrevTransactionNo: Integer;
        AdditionalAttributes: Dictionary of [Text, Text];
        TotalCount: Integer;
        Count: Integer;
    begin
        TempErrorMessage.ClearLog();
        ClearGlobalVariables();
        StartDate := DMY2Date(1, Month, Year);
        EndDate := CalcDate('<CM>', StartDate);

        AdditionalAttributes.Add('TipoSolicitud', Format(RequestType));
        if RequestType in [RequestType::AF, RequestType::FC] then begin
            if OrderNumber <> '' then
                AdditionalAttributes.Add('NumOrden', OrderNumber)
            else
                TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, MissingOrderNumberErr);
        end else
            if ProcessNumber <> '' then
                AdditionalAttributes.Add('NumTramite', ProcessNumber)
            else
                TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, MissingOrderNumberErr);

        CreateXMLHeader(PolizasNodeTxt, PolizasNamespaceTxt, Year, Month, '1.3', AdditionalAttributes);
        LoadCustomerPostingGroups();
        LoadVendorPostingGroups();

        GLEntry.SetCurrentKey("Transaction No.");
        GLEntry.SetRange("Posting Date", StartDate, EndDate);

        TotalCount := GLEntry.Count();
        OpenProgressDialog(GLEntryProcessTxt);

        PrevTransactionNo := 0;
        GLEntry.SetLoadFields("Transaction No.", "Posting Date", "Source Code", "G/L Account No.", "Debit Amount", "Credit Amount", Description, "Document Type");
        if GLEntry.FindSet() then begin
            repeat
                Count += 1;
                if Count mod 100 = 0 then
                    UpdateProgressDialog(1, Format(Round(Count / TotalCount * 100, 1)));

                if GLEntry."Transaction No." <> PrevTransactionNo then begin
                    if PrevTransactionNo <> 0 then
                        XmlHelper.FinalizeNode();    // close previous Poliza node
                    PrevTransactionNo := GLEntry."Transaction No.";
                    CreatePolizaNode(GLEntry);
                end;
                CreateTransaccionNode(GLEntry);
            until GLEntry.Next() = 0;
            XmlHelper.FinalizeNode();
        end;

        CloseProgressDialog();

        if not TempErrorMessage.HasErrors(true) then
            SaveXMLToClient(Year, Month, 'PL');

        TempErrorMessage.ShowErrorMessages(false);
    end;

    procedure ExportAuxiliaryAccounts(Year: Integer; Month: Integer; RequestType: Option AF,FC,DE,CO; OrderNumber: Text[13]; ProcessNumber: Text[14])
    var
        GLAccount: Record "G/L Account";
        GLAccountBalanceIni: Record "G/L Account";
        GLAccountBalanceFin: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        AdditionalAttributes: Dictionary of [Text, Text];
        StartDate: Date;
        EndDate: Date;
    begin
        TempErrorMessage.ClearLog();
        ClearGlobalVariables();
        StartDate := DMY2Date(1, Month, Year);
        EndDate := CalcDate('<CM>', StartDate);

        GLAccount.SetRange("Date Filter", StartDate, EndDate);
        GLAccount.SetFilter("SAT Account Code", '<>%1', '');

        AdditionalAttributes.Add('TipoSolicitud', Format(RequestType));
        if RequestType in [RequestType::AF, RequestType::FC] then begin
            if OrderNumber <> '' then
                AdditionalAttributes.Add('NumOrden', OrderNumber)
            else
                TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, MissingOrderNumberErr);
        end else
            if ProcessNumber <> '' then
                AdditionalAttributes.Add('NumTramite', ProcessNumber)
            else
                TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, MissingOrderNumberErr);

        CreateXMLHeader(AuxiliaryAccountNodeTxt, AuxiliaryAccountNamespaceTxt, Year, Month, '1.3', AdditionalAttributes);

        if GLAccount.FindSet() then
            repeat
                GLEntry.SetRange("G/L Account No.", GLAccount."No.");
                GLEntry.SetRange("Posting Date", StartDate, EndDate);
                if GLEntry.FindSet() then begin
                    GLAccountBalanceIni.Get(GLAccount."No.");
                    GLAccountBalanceIni.SetFilter("Date Filter", '..%1', ClosingDate(StartDate - 1));
                    GLAccountBalanceIni.CalcFields("Balance at Date");

                    GLAccountBalanceFin.Get(GLAccount."No.");
                    GLAccountBalanceFin.SetFilter("Date Filter", '..%1', EndDate);
                    GLAccountBalanceFin.CalcFields("Balance at Date");

                    TempErrorMessage.LogIfEmpty(GLAccount, GLAccount.FieldNo(Name), TempErrorMessage."Message Type"::Error);

                    XmlHelper.AddNewNode('Cuenta');
                    XmlHelper.AddAttribute('NumCta', GLAccount."No.");
                    XmlHelper.AddAttribute('DesCta', GLAccount.Name);
                    XmlHelper.AddAttribute('SaldoIni', FormatDecimal(GLAccountBalanceIni."Balance at Date"));
                    XmlHelper.AddAttribute('SaldoFin', FormatDecimal(GLAccountBalanceFin."Balance at Date"));

                    repeat
                        TempErrorMessage.LogIfEmpty(GLEntry, GLEntry.FieldNo(Description), TempErrorMessage."Message Type"::Warning);
                        XmlHelper.AddNewNode('DetalleAux');
                        XmlHelper.AddAttribute('Fecha', FormatDate(GLEntry."Posting Date"));
                        XmlHelper.AddAttribute('NumUnIdenPol', Format(GLEntry."Transaction No."));
                        XmlHelper.AddAttribute('Concepto', GLEntry.Description);
                        XmlHelper.AddAttribute('Debe', FormatDecimal(GLEntry."Debit Amount"));
                        XmlHelper.AddAttribute('Haber', FormatDecimal(GLEntry."Credit Amount"));
                        XmlHelper.FinalizeNode();
                    until GLEntry.Next() = 0;
                    XmlHelper.FinalizeNode();
                end;
            until GLAccount.Next() = 0;

        if not TempErrorMessage.HasErrors(true) then
            SaveXMLToClient(Year, Month, 'XC');

        TempErrorMessage.ShowErrorMessages(false);
    end;

    local procedure CreateXMLHeader(RootNodeName: Text; NodeNameSpace: Text; Year: Integer; Month: Integer; Version: Text; AdditionalAttributes: Dictionary of [Text, Text])
    var
        FullNameSpace: Text;
        SchemaLocation: Text;
        XmlAttributeName: Text;
        XmlAttributes: Dictionary of [Text, Text];
    begin
        GetCompanyInformation();

        TempErrorMessage.LogIfEmpty(CompanyInfoGlobal, CompanyInfoGlobal.FieldNo("RFC Number"), TempErrorMessage."Message Type"::Error);
        if (Month < 1) or (Month > 13) then
            TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, InvalidMonthErr);
        if (Year < 2000) or (Month > 2999) then
            TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, InvalidYearErr);

        FullNameSpace := NamespaceTxt + NodeNameSpace;
        SchemaLocation := FullNameSpace + ' ' + FullNameSpace + '/' + NodeNameSpace + '_1_3.xsd';

        XmlAttributes.Add('Version', Version);
        XmlAttributes.Add('RFC', CompanyInfoGlobal."RFC Number");
        XmlAttributes.Add('Mes', Format(Month, 2, '<Integer,2><Filler Character,0>'));
        XmlAttributes.Add('Anio', Format(Year));

        foreach XmlAttributeName in AdditionalAttributes.Keys() do
            XmlAttributes.Add(XmlAttributeName, AdditionalAttributes.Get(XmlAttributeName));

        XmlHelper.Initialize(RootNodeName, '', FullNameSpace, SchemaLocation, XmlAttributes);
    end;

    local procedure CreatePolizaNode(var GLEntry: Record "G/L Entry")
    begin
        TempErrorMessage.LogIfEmpty(GLEntry, GLEntry.FieldNo("Source Code"), TempErrorMessage."Message Type"::Warning);

        XmlHelper.AddNewNode('Poliza');
        XmlHelper.AddAttribute('NumUnIdenPol', Format(GLEntry."Transaction No."));
        XmlHelper.AddAttribute('Fecha', FormatDate(GLEntry."Posting Date"));
        XmlHelper.AddAttribute('Concepto', GLEntry."Source Code");
    end;

    local procedure CreateTransaccionNode(var GLEntry: Record "G/L Entry")
    var
        GLAccount: Record "G/L Account";
        GLAccountNo: Text;
        GLAccountName: Text;
    begin
        GLAccountNo := GLEntry."G/L Account No.";
        if not GLAccountNames.Get(GLAccountNo, GLAccountName) then begin
            GLAccount.SetLoadFields(Name);
            GLAccount.Get(GLAccountNo);
            TempErrorMessage.LogIfEmpty(GLAccount, GLAccount.FieldNo(Name), TempErrorMessage."Message Type"::Error);
            GLAccountNames.Add(GLAccount."No.", GLAccount.Name);
            GLAccountName := GLAccount.Name;
        end;

        TempErrorMessage.LogIfEmpty(GLEntry, GLEntry.FieldNo(Description), TempErrorMessage."Message Type"::Warning);

        XmlHelper.AddNewNode('Transaccion');
        XmlHelper.AddAttribute('NumCta', GLAccountNo);
        XmlHelper.AddAttribute('DesCta', GLAccountName);
        XmlHelper.AddAttribute('Concepto', GLEntry.Description);
        XmlHelper.AddAttribute('Debe', FormatDecimal(GLEntry."Debit Amount"));
        XmlHelper.AddAttribute('Haber', FormatDecimal(GLEntry."Credit Amount"));

        CreateCustomerReceipts(GLEntry, false);
        CreateVendorReceipts(GLEntry, false);

        CreateTransfers(GLEntry);
        XmlHelper.FinalizeNode();
    end;

    local procedure CreateVendorReceipts(var GLEntry: Record "G/L Entry"; IsAuxiliary: Boolean)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        AppliedVendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        VendorLedgerEntry.SetRange("Transaction No.", GLEntry."Transaction No.");

        if VendorLedgerEntry.FindSet() then
            repeat
                VendorPostingGroup.Get(VendorLedgerEntry."Vendor Posting Group");
                if VendorPostingGroup."Payables Account" = GLEntry."G/L Account No." then
                    if VendorLedgerEntry."Document Type" in [VendorLedgerEntry."Document Type"::Payment,
                                                             VendorLedgerEntry."Document Type"::Refund]
                    then begin
                        FindAppliedVendorReceipts(AppliedVendorLedgerEntry, VendorLedgerEntry."Entry No.", VendorLedgerEntry."Closed by Entry No.");
                        if AppliedVendorLedgerEntry.FindSet() then
                            repeat
                                CreateReceipt(AppliedVendorLedgerEntry, IsAuxiliary);
                            until AppliedVendorLedgerEntry.Next() = 0;
                    end else
                        CreateReceipt(VendorLedgerEntry, IsAuxiliary);
            until VendorLedgerEntry.Next() = 0;
    end;

    local procedure CreateCustomerReceipts(var GLEntry: Record "G/L Entry"; IsAuxiliary: Boolean)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        AppliedCustLedgerEntry: Record "Cust. Ledger Entry";
        CustReceivablesAccount: Text;
    begin
        CustLedgerEntry.SetRange("Transaction No.", GLEntry."Transaction No.");

        CustLedgerEntry.SetLoadFields("Customer Posting Group", "Document Type", "Closed by Entry No.");
        if CustLedgerEntry.FindSet() then
            repeat
                CustReceivablesAccount := CustPostGroupReceivableAcc.Get(CustLedgerEntry."Customer Posting Group");
                if GLEntry."G/L Account No." = CustReceivablesAccount then
                    if CustLedgerEntry."Document Type" in [CustLedgerEntry."Document Type"::Payment,
                                                           CustLedgerEntry."Document Type"::Refund]
                    then begin
                        FindAppliedCustomerReceipts(AppliedCustLedgerEntry, CustLedgerEntry."Entry No.", CustLedgerEntry."Closed by Entry No.");
                        if AppliedCustLedgerEntry.FindSet() then
                            repeat
                                CreateReceipt(AppliedCustLedgerEntry, IsAuxiliary);
                            until AppliedCustLedgerEntry.Next() = 0;
                    end else
                        CreateReceipt(CustLedgerEntry, IsAuxiliary);
            until CustLedgerEntry.Next() = 0;
    end;

    local procedure FindAppliedVendorReceipts(var AppliedVendorLedgerEntry: Record "Vendor Ledger Entry"; EntryNo: Integer; ClosedByEntryNo: Integer)
    var
        TempAppliedVendLedgerEntry: Record "Vendor Ledger Entry" temporary;
        VendEntryApplyPostedEntries: Codeunit "VendEntry-Apply Posted Entries";
    begin
        AppliedVendorLedgerEntry.Reset();

        VendEntryApplyPostedEntries.GetAppliedVendLedgerEntries(TempAppliedVendLedgerEntry, EntryNo);
        if TempAppliedVendLedgerEntry.FindSet() then
            repeat
                AppliedVendorLedgerEntry."Entry No." := TempAppliedVendLedgerEntry."Entry No.";
                if AppliedVendorLedgerEntry.Find('=') then
                    AppliedVendorLedgerEntry.Mark(true);
            until TempAppliedVendLedgerEntry.Next() = 0;

        if ClosedByEntryNo <> 0 then begin
            AppliedVendorLedgerEntry."Entry No." := ClosedByEntryNo;
            AppliedVendorLedgerEntry.Mark(true);
        end;

        AppliedVendorLedgerEntry.SetCurrentKey("Closed by Entry No.");
        AppliedVendorLedgerEntry.SetRange("Closed by Entry No.", EntryNo);
        if AppliedVendorLedgerEntry.FindSet() then
            repeat
                AppliedVendorLedgerEntry.Mark(true);
            until AppliedVendorLedgerEntry.Next() = 0;

        AppliedVendorLedgerEntry.SetCurrentKey("Entry No.");
        AppliedVendorLedgerEntry.SetRange("Closed by Entry No.");
        AppliedVendorLedgerEntry.MarkedOnly(true);
    end;

    local procedure FindAppliedCustomerReceipts(var AppliedCustLedgerEntry: Record "Cust. Ledger Entry"; EntryNo: Integer; ClosedByEntryNo: Integer)
    var
        TempAppliedCustLedgerEntry: Record "Cust. Ledger Entry" temporary;
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
    begin
        AppliedCustLedgerEntry.Reset();

        CustEntryApplyPostedEntries.GetAppliedCustLedgerEntries(TempAppliedCustLedgerEntry, EntryNo);
        if TempAppliedCustLedgerEntry.FindSet() then
            repeat
                AppliedCustLedgerEntry."Entry No." := TempAppliedCustLedgerEntry."Entry No.";
                if AppliedCustLedgerEntry.Find('=') then
                    AppliedCustLedgerEntry.Mark(true);
            until TempAppliedCustLedgerEntry.Next() = 0;

        if ClosedByEntryNo <> 0 then begin
            AppliedCustLedgerEntry."Entry No." := ClosedByEntryNo;
            AppliedCustLedgerEntry.Mark(true);
        end;

        AppliedCustLedgerEntry.SetCurrentKey("Closed by Entry No.");
        AppliedCustLedgerEntry.SetRange("Closed by Entry No.", EntryNo);
        AppliedCustLedgerEntry.SetLoadFields("Closed by Entry No.");
        if AppliedCustLedgerEntry.FindSet() then
            repeat
                AppliedCustLedgerEntry.Mark(true);
            until AppliedCustLedgerEntry.Next() = 0;

        AppliedCustLedgerEntry.SetCurrentKey("Entry No.");
        AppliedCustLedgerEntry.SetRange("Closed by Entry No.");
        AppliedCustLedgerEntry.MarkedOnly(true);
    end;

    local procedure CreateReceipt(LedgerEntry: Variant; IsAuxiliary: Boolean)
    var
        PaymentMethod: Record "Payment Method";
        LedgerEntryRecordRef: RecordRef;
        AmountFieldRef: FieldRef;
        CountryRegion: Code[10];
        DocumentNo: Code[20];
        RFCNo: Code[13];
        CurrencyCode: Code[10];
        PaymentMethodCode: Code[10];
        UUIDCFDI: Text;
        VATRegistrationNo: Text[20];
        CustVendName: Text;
        Amount: Decimal;
        AdjustedCurrencyFactor: Decimal;
    begin
        GetCompanyInformation();

        LedgerEntryRecordRef.GetTable(LedgerEntry);
        FindCustVendDetails(LedgerEntryRecordRef, CountryRegion, RFCNo, VATRegistrationNo, CustVendName);
        AmountFieldRef := LedgerEntryRecordRef.Field(13);
        AmountFieldRef.CalcField();
        Amount := AmountFieldRef.Value();
        CurrencyCode := LedgerEntryRecordRef.Field(11).Value();
        AdjustedCurrencyFactor := LedgerEntryRecordRef.Field(73).Value();
        PaymentMethodCode := LedgerEntryRecordRef.Field(172).Value();

        DocumentNo := LedgerEntryRecordRef.Field(6).Value();
        if (CountryRegion = CompanyInfoGlobal."Country/Region Code") or (CountryRegion = '') then begin
            UUIDCFDI := FindUUIDCFDI(LedgerEntryRecordRef);

            if UUIDCFDI <> '' then begin
                if IsAuxiliary then
                    XmlHelper.AddNewNode('ComprNal')
                else
                    XmlHelper.AddNewNode('CompNal');
                XmlHelper.AddAttribute('UUID_CFDI', UUIDCFDI);
            end else begin
                if IsAuxiliary then
                    XmlHelper.AddNewNode('ComprNalOtr')
                else
                    XmlHelper.AddNewNode('CompNalOtr');
                TempErrorMessage.LogIfInvalidCharacters(LedgerEntryRecordRef, 6, TempErrorMessage."Message Type"::Warning, '0123456789');
                DocumentNo := DelChr(DocumentNo, '=', DelChr(DocumentNo, '=', '0123456789'));
                XmlHelper.AddAttribute('CFD_CBB_NumFol', DocumentNo);
            end;
            XmlHelper.AddAttribute('RFC', RFCNo);
        end else begin
            if IsAuxiliary then
                XmlHelper.AddNewNode('ComprExt')
            else
                XmlHelper.AddNewNode('CompExt');
            XmlHelper.AddAttribute('NumFactExt', DocumentNo);
            XmlHelper.AddAttribute('TaxID', VATRegistrationNo);
        end;

        if IsAuxiliary and PaymentMethod.Get(PaymentMethodCode) then begin
            TempErrorMessage.LogIfEmpty(
              PaymentMethod, PaymentMethod.FieldNo("SAT Payment Method Code"), TempErrorMessage."Message Type"::Error);
            XmlHelper.AddAttribute('MetPagoAux', PaymentMethod."SAT Payment Method Code");
        end;

        if LedgerEntryRecordRef.Number = DATABASE::"Vendor Ledger Entry" then
            Amount := -Amount;
        XmlHelper.AddAttribute('MontoTotal', FormatDecimal(Amount));
        if CurrencyCode <> '' then begin
            XmlHelper.AddAttribute('Moneda', CurrencyCode);
            XmlHelper.AddAttribute('TipCamb', FormatDecimal(1 / AdjustedCurrencyFactor));
        end;
        XmlHelper.FinalizeNode();
    end;

    local procedure CreateTransfers(var GLEntry: Record "G/L Entry")
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CheckLedgerEntry: Record "Check Ledger Entry";
        BankAccountPostingGroup: Record "Bank Account Posting Group";
        PaymentHandled: Boolean;
    begin
        BankAccountLedgerEntry.SetCurrentKey("Transaction No.");
        CheckLedgerEntry.SetCurrentKey("Bank Account Ledger Entry No.");

        BankAccountLedgerEntry.SetRange("Transaction No.", GLEntry."Transaction No.");
        BankAccountLedgerEntry.SetFilter("Credit Amount", '>0');
        if BankAccountLedgerEntry.FindSet() then
            repeat
                BankAccountPostingGroup.Get(BankAccountLedgerEntry."Bank Acc. Posting Group");
                if BankAccountPostingGroup."G/L Account No." = GLEntry."G/L Account No." then begin
                    CheckLedgerEntry.SetRange("Bank Account Ledger Entry No.", BankAccountLedgerEntry."Entry No.");
                    if CheckLedgerEntry.FindSet() then
                        repeat
                            PaymentHandled := CreateChequeNode(CheckLedgerEntry) or PaymentHandled;
                        until CheckLedgerEntry.Next() = 0
                    else
                        PaymentHandled := CreateTransferenciaNode(BankAccountLedgerEntry) or PaymentHandled
                end else
                    PaymentHandled := true;
            until BankAccountLedgerEntry.Next() = 0;

        if (not PaymentHandled) and
            (GLEntry."Credit Amount" > 0) and
            (GLEntry."Document Type" = GLEntry."Document Type"::Payment)
        then begin
            CreateOtrMetodoPagoNode(DATABASE::"Cust. Ledger Entry", GLEntry."Transaction No.");
            CreateOtrMetodoPagoNode(DATABASE::"Vendor Ledger Entry", GLEntry."Transaction No.");
        end
    end;

    local procedure CreateChequeNode(var CheckLedgerEntry: Record "Check Ledger Entry"): Boolean
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        Vendor: Record Vendor;
        Customer: Record Customer;
        BankAccount: Record "Bank Account";
        RecipientBankAccount: Record "Bank Account";
        Benef: Text[300];
        RFC: Text[30];
        ExchangeRate: Decimal;
    begin
        BankAccount.SetLoadFields("Bank Code", Name, "Bank Account No.");
        BankAccount.Get(CheckLedgerEntry."Bank Account No.");

        TempErrorMessage.LogIfEmpty(CheckLedgerEntry, CheckLedgerEntry.FieldNo("Check No."), TempErrorMessage."Message Type"::Warning);
        TempErrorMessage.LogIfEmpty(CheckLedgerEntry, CheckLedgerEntry.FieldNo("Check Date"), TempErrorMessage."Message Type"::Warning);
        TempErrorMessage.LogIfEmpty(BankAccount, BankAccount.FieldNo("Bank Code"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(BankAccount, BankAccount.FieldNo("Bank Account No."), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(BankAccount, BankAccount.FieldNo(Name), TempErrorMessage."Message Type"::Error);

        case CheckLedgerEntry."Bal. Account Type" of
            CheckLedgerEntry."Bal. Account Type"::Vendor:
                begin
                    Vendor.SetLoadFields(Name, "RFC No.");
                    Vendor.Get(CheckLedgerEntry."Bal. Account No.");
                    TempErrorMessage.LogIfEmpty(Vendor, Vendor.FieldNo(Name), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(Vendor, Vendor.FieldNo("RFC No."), TempErrorMessage."Message Type"::Error);
                    Benef := Vendor.Name;
                    RFC := Vendor."RFC No.";
                end;
            CheckLedgerEntry."Bal. Account Type"::Customer:
                begin
                    Customer.SetLoadFields(Name, "RFC No.");
                    Customer.Get(CheckLedgerEntry."Bal. Account No.");
                    TempErrorMessage.LogIfEmpty(Customer, Customer.FieldNo(Name), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(Customer, Customer.FieldNo("RFC No."), TempErrorMessage."Message Type"::Error);
                    Benef := Customer.Name;
                    RFC := Customer."RFC No.";
                end;
            CheckLedgerEntry."Bal. Account Type"::"Bank Account":
                begin
                    GetCompanyInformation();
                    RecipientBankAccount.SetLoadFields(Name);
                    RecipientBankAccount.Get(CheckLedgerEntry."Bal. Account No.");
                    TempErrorMessage.LogIfEmpty(RecipientBankAccount, RecipientBankAccount.FieldNo(Name), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(CompanyInfoGlobal, CompanyInfoGlobal.FieldNo("RFC Number"), TempErrorMessage."Message Type"::Error);
                    Benef := RecipientBankAccount.Name;
                    RFC := CompanyInfoGlobal."RFC Number";
                end;
        end;

        XmlHelper.AddNewNode('Cheque');
        XmlHelper.AddAttribute('Num', CheckLedgerEntry."Check No.");
        XmlHelper.AddAttribute('BanEmisNal', BankAccount."Bank Code");
        XmlHelper.AddAttribute('BanEmisExt', BankAccount.Name);
        XmlHelper.AddAttribute('CtaOri', BankAccount."Bank Account No.");
        XmlHelper.AddAttribute('Fecha', FormatDate(CheckLedgerEntry."Check Date"));
        XmlHelper.AddAttribute('Benef', Benef);
        XmlHelper.AddAttribute('RFC', RFC);
        XmlHelper.AddAttribute('Monto', FormatDecimal(CheckLedgerEntry.Amount));

        BankAccountLedgerEntry.SetLoadFields("Currency Code");
        BankAccountLedgerEntry.Get(CheckLedgerEntry."Bank Account Ledger Entry No.");
        if BankAccountLedgerEntry."Currency Code" <> '' then begin
            ExchangeRate := CurrencyExchangeRate.ExchangeRate(CheckLedgerEntry."Posting Date", BankAccountLedgerEntry."Currency Code");
            XmlHelper.AddAttribute('Moneda', BankAccountLedgerEntry."Currency Code");
            XmlHelper.AddAttribute('TipCamb', FormatDecimal(1 / ExchangeRate));
        end;
        XmlHelper.FinalizeNode();

        exit(true);
    end;

    local procedure CreateTransferenciaNode(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"): Boolean
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Customer: Record Customer;
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        CustomerBankAccount: Record "Customer Bank Account";
        VendorBankAccount: Record "Vendor Bank Account";
        RecipientBankAccount: Record "Bank Account";
        CtaDest: Text[50];
        BancoDestNal: Code[3];
        BancoDestExt: Text;
        Benef: Text[300];
        RFC: Text[30];
        ExchangeRate: Decimal;
    begin
        case BankAccountLedgerEntry."Bal. Account Type" of
            BankAccountLedgerEntry."Bal. Account Type"::Customer:
                begin
                    CustLedgerEntry.SetCurrentKey("Transaction No.");
                    CustLedgerEntry.SetRange("Transaction No.", BankAccountLedgerEntry."Transaction No.");
                    CustLedgerEntry.SetFilter("Recipient Bank Account", '<>%1', '');
                    CustLedgerEntry.SetLoadFields("Transaction No.", "Recipient Bank Account", "Customer No.");
                    if not CustLedgerEntry.FindFirst() then
                        exit(false);
                    Customer.SetLoadFields(Name, "RFC No.");
                    Customer.Get(CustLedgerEntry."Customer No.");
                    CustomerBankAccount.SetLoadFields("Bank Account No.", "Bank Code", Name);
                    CustomerBankAccount.Get(Customer."No.", CustLedgerEntry."Recipient Bank Account");

                    TempErrorMessage.LogIfEmpty(
                      CustomerBankAccount, CustomerBankAccount.FieldNo("Bank Account No."), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(
                      CustomerBankAccount, CustomerBankAccount.FieldNo("Bank Code"), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(CustomerBankAccount, CustomerBankAccount.FieldNo(Name), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(Customer, Customer.FieldNo(Name), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(Customer, Customer.FieldNo("RFC No."), TempErrorMessage."Message Type"::Error);

                    CtaDest := CustomerBankAccount."Bank Account No.";
                    BancoDestNal := CustomerBankAccount."Bank Code";
                    BancoDestExt := CustomerBankAccount.Name;
                    Benef := Customer.Name;
                    RFC := Customer."RFC No.";
                end;
            BankAccountLedgerEntry."Bal. Account Type"::Vendor:
                begin
                    VendorLedgerEntry.SetCurrentKey("Transaction No.");
                    VendorLedgerEntry.SetRange("Transaction No.", BankAccountLedgerEntry."Transaction No.");
                    VendorLedgerEntry.SetFilter("Recipient Bank Account", '<>%1', '');
                    VendorLedgerEntry.SetLoadFields("Transaction No.", "Recipient Bank Account", "Vendor No.");
                    if not VendorLedgerEntry.FindFirst() then
                        exit(false);
                    Vendor.SetLoadFields(Name, "RFC No.");
                    Vendor.Get(VendorLedgerEntry."Vendor No.");
                    VendorBankAccount.SetLoadFields("Bank Account No.", "Bank Code", Name);
                    VendorBankAccount.Get(Vendor."No.", VendorLedgerEntry."Recipient Bank Account");

                    TempErrorMessage.LogIfEmpty(
                      VendorBankAccount, VendorBankAccount.FieldNo("Bank Account No."), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(
                      VendorBankAccount, VendorBankAccount.FieldNo("Bank Code"), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(VendorBankAccount, VendorBankAccount.FieldNo(Name), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(Vendor, Vendor.FieldNo(Name), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(Vendor, Vendor.FieldNo("RFC No."), TempErrorMessage."Message Type"::Error);

                    CtaDest := VendorBankAccount."Bank Account No.";
                    BancoDestNal := VendorBankAccount."Bank Code";
                    BancoDestExt := VendorBankAccount.Name;
                    Benef := Vendor.Name;
                    RFC := Vendor."RFC No.";
                end;
            BankAccountLedgerEntry."Bal. Account Type"::"Bank Account":
                begin
                    RecipientBankAccount.SetLoadFields("Bank Account No.", "Bank Code", Name);
                    if not RecipientBankAccount.Get(BankAccountLedgerEntry."Bal. Account No.") then
                        exit(false);
                    GetCompanyInformation();

                    TempErrorMessage.LogIfEmpty(
                      RecipientBankAccount, RecipientBankAccount.FieldNo("Bank Account No."), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(
                      RecipientBankAccount, RecipientBankAccount.FieldNo("Bank Code"), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(
                      RecipientBankAccount, RecipientBankAccount.FieldNo(Name), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(CompanyInfoGlobal, CompanyInfoGlobal.FieldNo(Name), TempErrorMessage."Message Type"::Error);
                    TempErrorMessage.LogIfEmpty(
                      CompanyInfoGlobal, CompanyInfoGlobal.FieldNo("RFC Number"), TempErrorMessage."Message Type"::Error);

                    CtaDest := RecipientBankAccount."Bank Account No.";
                    BancoDestNal := RecipientBankAccount."Bank Code";
                    BancoDestExt := RecipientBankAccount.Name;
                    Benef := CompanyInfoGlobal.Name;
                    RFC := CompanyInfoGlobal."RFC Number";
                end;
            else
                exit(false);
        end;

        BankAccount.SetLoadFields("Bank Account No.", "Bank Code", Name);
        BankAccount.Get(BankAccountLedgerEntry."Bank Account No.");

        TempErrorMessage.LogIfEmpty(BankAccount, BankAccount.FieldNo("Bank Account No."), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(BankAccount, BankAccount.FieldNo("Bank Code"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(BankAccount, BankAccount.FieldNo(Name), TempErrorMessage."Message Type"::Error);

        XmlHelper.AddNewNode('Transferencia');
        XmlHelper.AddAttribute('CtaOri', BankAccount."Bank Account No.");
        XmlHelper.AddAttribute('BancoOriNal', BankAccount."Bank Code");
        XmlHelper.AddAttribute('BancoOriExt', BankAccount.Name);
        XmlHelper.AddAttribute('CtaDest', CtaDest);
        XmlHelper.AddAttribute('BancoDestNal', BancoDestNal);
        XmlHelper.AddAttribute('BancoDestExt', BancoDestExt);
        XmlHelper.AddAttribute('Fecha', FormatDate(BankAccountLedgerEntry."Posting Date"));
        XmlHelper.AddAttribute('Benef', Benef);
        XmlHelper.AddAttribute('RFC', RFC);
        XmlHelper.AddAttribute('Monto', FormatDecimal(BankAccountLedgerEntry."Credit Amount"));

        if BankAccountLedgerEntry."Currency Code" <> '' then begin
            ExchangeRate :=
              CurrencyExchangeRate.ExchangeRate(BankAccountLedgerEntry."Posting Date", BankAccountLedgerEntry."Currency Code");
            XmlHelper.AddAttribute('Moneda', BankAccountLedgerEntry."Currency Code");
            XmlHelper.AddAttribute('TipCamb', FormatDecimal(1 / ExchangeRate));
        end;
        XmlHelper.FinalizeNode();

        exit(true);
    end;

    local procedure CreateOtrMetodoPagoNode(LedgerEntryTableNo: Integer; TransactionNo: Integer)
    var
        PaymentMethod: Record "Payment Method";
        PaymentMethodFieldRef: FieldRef;
        LedgerEntryRecordRef: RecordRef;
        TransactionNoFieldRef: FieldRef;
        AmountFieldRef: FieldRef;
        CountryRegion: Code[10];
        RFCNo: Code[13];
        CurrencyCode: Code[10];
        VATRegistrationNo: Text[20];
        Amount: Decimal;
        AdjustedCurrencyFactor: Decimal;
        Name: Text;
        PostingDate: Date;
    begin
        LedgerEntryRecordRef.Open(LedgerEntryTableNo);
        TransactionNoFieldRef := LedgerEntryRecordRef.Field(53);
        TransactionNoFieldRef.SetRange(TransactionNo);
        PaymentMethodFieldRef := LedgerEntryRecordRef.Field(172);
        PaymentMethodFieldRef.SetFilter('<> %1', '');
        if LedgerEntryRecordRef.FindSet() then
            repeat
                PaymentMethod.Get(PaymentMethodFieldRef.Value);

                TempErrorMessage.LogIfEmpty(
                  PaymentMethod, PaymentMethod.FieldNo("SAT Payment Method Code"), TempErrorMessage."Message Type"::Error);

                FindCustVendDetails(LedgerEntryRecordRef, CountryRegion, RFCNo, VATRegistrationNo, Name);
                AmountFieldRef := LedgerEntryRecordRef.Field(13);
                AmountFieldRef.CalcField();
                Amount := AmountFieldRef.Value();
                CurrencyCode := LedgerEntryRecordRef.Field(11).Value();
                AdjustedCurrencyFactor := LedgerEntryRecordRef.Field(73).Value();
                PostingDate := LedgerEntryRecordRef.Field(4).Value();

                XmlHelper.AddNewNode('OtrMetodoPago');
                XmlHelper.AddAttribute('MetPagoPol', PaymentMethod."SAT Payment Method Code");
                XmlHelper.AddAttribute('Fecha', FormatDate(PostingDate));
                XmlHelper.AddAttribute('Benef', Name);
                XmlHelper.AddAttribute('RFC', RFCNo);

                XmlHelper.AddAttribute('Monto', FormatDecimal(Abs(Amount)));
                if CurrencyCode <> '' then begin
                    XmlHelper.AddAttribute('Moneda', CurrencyCode);
                    XmlHelper.AddAttribute('TipCamb', FormatDecimal(1 / AdjustedCurrencyFactor));
                end;
                XmlHelper.FinalizeNode();
            until LedgerEntryRecordRef.Next() = 0;
    end;

    local procedure FindUUIDCFDI(CustVendLedgerEntry: Variant) UUID: Text
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        SourceCodeSetup: Record "Source Code Setup";
        RecordRef: RecordRef;
        DocumentType: Enum "Gen. Journal Document Type";
        DocumentNo: Code[20];
        SourceCode: Code[10];
    begin
        SourceCodeSetup.Get();
        RecordRef.GetTable(CustVendLedgerEntry);
        DocumentType := RecordRef.Field(5).Value();
        DocumentNo := RecordRef.Field(6).Value();
        SourceCode := RecordRef.Field(28).Value();
        case SourceCode of
            SourceCodeSetup.Sales:
                case DocumentType of
                    DocumentType::Invoice:
                        if SalesInvoiceHeader.Get(DocumentNo) then
                            exit(SalesInvoiceHeader."Fiscal Invoice Number PAC");
                    DocumentType::"Credit Memo":
                        if SalesCrMemoHeader.Get(DocumentNo) then
                            exit(SalesCrMemoHeader."Fiscal Invoice Number PAC");
                end;
            SourceCodeSetup.Purchases:
                case DocumentType of
                    DocumentType::Invoice:
                        if PurchInvHeader.Get(DocumentNo) then
                            exit(PurchInvHeader."Fiscal Invoice Number PAC");
                    DocumentType::"Credit Memo":
                        if PurchCrMemoHdr.Get(DocumentNo) then
                            exit(PurchCrMemoHdr."Fiscal Invoice Number PAC");
                end;
            else
                OnFindUUIDCFDI(SourceCode, SourceCodeSetup, DocumentType, DocumentNo, UUID);
        end;
    end;

    local procedure FindCustVendDetails(LedgerEntryRecordRef: RecordRef; var CountryRegion: Code[10]; var RFCNo: Code[13]; var VATRegistrationNo: Text[20]; var Name: Text)
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        CustVendNo: Code[20];
    begin
        CustVendNo := LedgerEntryRecordRef.Field(3).Value();
        if LedgerEntryRecordRef.Number = DATABASE::"Cust. Ledger Entry" then begin
            Customer.SetLoadFields(Name, "VAT Registration No.", "RFC No.", "Country/Region Code");
            Customer.Get(CustVendNo);

            TempErrorMessage.LogIfEmpty(Customer, Customer.FieldNo(Name), TempErrorMessage."Message Type"::Error);
            TempErrorMessage.LogIfEmpty(Customer, Customer.FieldNo("VAT Registration No."), TempErrorMessage."Message Type"::Error);
            TempErrorMessage.LogIfEmpty(Customer, Customer.FieldNo("RFC No."), TempErrorMessage."Message Type"::Error);

            CountryRegion := Customer."Country/Region Code";
            RFCNo := Customer."RFC No.";
            VATRegistrationNo := Customer."VAT Registration No.";
            Name := Customer.Name;
        end else begin
            Vendor.SetLoadFields(Name, "VAT Registration No.", "RFC No.", "Country/Region Code");
            Vendor.Get(CustVendNo);

            TempErrorMessage.LogIfEmpty(Vendor, Vendor.FieldNo(Name), TempErrorMessage."Message Type"::Error);
            TempErrorMessage.LogIfEmpty(Vendor, Vendor.FieldNo("VAT Registration No."), TempErrorMessage."Message Type"::Error);
            TempErrorMessage.LogIfEmpty(Vendor, Vendor.FieldNo("RFC No."), TempErrorMessage."Message Type"::Error);

            CountryRegion := Vendor."Country/Region Code";
            RFCNo := Vendor."RFC No.";
            VATRegistrationNo := Vendor."VAT Registration No.";
            Name := Vendor.Name;
        end;
    end;

    local procedure SaveXMLToClient(Year: Integer; Month: Integer; Type: Text): Boolean
    var
        DataCompression: Codeunit "Data Compression";
        XMLTempBlob: Codeunit "Temp Blob";
        ZipTempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
        BlobInStream: InStream;
        ZipInStream: InStream;
        ZipOutStream: OutStream;
        Result: Boolean;
        ClientFileName: Text;
    begin
        XmlHelper.WriteXmlDocToTempBlob(XMLTempBlob);
        XMLTempBlob.CreateInStream(BlobInStream);

        if TestFileName <> '' then
            exit(FileMgt.DownloadFromStreamHandler(BlobInStream, '', '', '', TestFileName));

        GetCompanyInformation();
        ClientFileName := CompanyInfoGlobal."RFC Number" + Format(Year) +
          Format(Month, 2, '<Integer,2><Filler Character,0>') + Type;

        DataCompression.CreateZipArchive();
        DataCompression.AddEntry(BlobInStream, ClientFileName + '.xml');
        ZipTempBlob.CreateOutStream(ZipOutStream);
        DataCompression.SaveZipArchive(ZipOutStream);
        DataCompression.CloseZipArchive();
        ZipTempBlob.CreateInStream(ZipInStream);
        ClientFileName += '.zip';
        Result := FileMgt.DownloadFromStreamHandler(ZipInStream, '', '', '', ClientFileName);
        exit(Result);
    end;

    local procedure LoadCustomerPostingGroups()
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        Clear(CustPostGroupReceivableAcc);
        CustomerPostingGroup.SetLoadFields("Receivables Account");
        if CustomerPostingGroup.FindSet() then
            repeat
                CustPostGroupReceivableAcc.Add(CustomerPostingGroup.Code, CustomerPostingGroup."Receivables Account");
            until CustomerPostingGroup.Next() = 0;
    end;

    local procedure LoadVendorPostingGroups()
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        Clear(VendPostGroupPayablesAcc);
        VendorPostingGroup.SetLoadFields("Payables Account");
        if VendorPostingGroup.FindSet() then
            repeat
                VendPostGroupPayablesAcc.Add(VendorPostingGroup.Code, VendorPostingGroup."Payables Account");
            until VendorPostingGroup.Next() = 0;
    end;

    local procedure GetCompanyInformation()
    begin
        if IsNullGuid(CompanyInfoGlobal.SystemId) then
            CompanyInfoGlobal.Get();
    end;

    local procedure ClearGlobalVariables()
    begin
        Clear(CompanyInfoGlobal);
        Clear(CustPostGroupReceivableAcc);
        Clear(VendPostGroupPayablesAcc);
        Clear(GLAccountNames);
    end;

    local procedure FormatDecimal(Amount: Decimal): Text
    begin
        exit(Format(Amount, 0, '<Precision,2:2><Standard Format,9>'));
    end;

    local procedure FormatDate(InputDate: Date): Text
    begin
        exit(Format(InputDate, 0, 9));
    end;

    local procedure OpenProgressDialog(DialogContent: Text)
    begin
        if GuiAllowed() then
            ProgressDialog.Open(DialogContent);
    end;

    local procedure CloseProgressDialog()
    begin
        if GuiAllowed() then
            ProgressDialog.Close();
    end;

    local procedure UpdateProgressDialog(Number: Integer; NewText: Text)
    begin
        if GuiAllowed() then
            ProgressDialog.Update(Number, NewText + '%');
    end;

    procedure InitializeRequest(FileName: Text)
    begin
        TestFileName := FileName;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindUUIDCFDI(SourceCode: Code[10]; SourceCodeSetup: Record "Source Code Setup"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; var UUID: Text)
    begin
    end;
}

