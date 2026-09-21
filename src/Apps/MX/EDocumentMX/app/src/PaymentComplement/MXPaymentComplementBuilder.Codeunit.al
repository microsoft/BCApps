// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.EServices.EDocument.Interfactura;

using Microsoft.Bank.BankAccount;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Foundation.Company;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using Microsoft.Service.History;
using System.Security.Encryption;
using System.Utilities;
using System.Xml;

codeunit 3356 "MX Payment Complement Builder"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure Build(Payment: Record "Cust. Ledger Entry"; var TempBlob: Codeunit "Temp Blob")
    var
        Customer: Record Customer;
        Company: Record "Company Information";
        Setup: Record "MX Connection Setup";
        GLSetup: Record "General Ledger Setup";
        XmlDoc: XmlDocument;
        Root: XmlElement;
        Helper: Codeunit "CFDI XML Helper MX";
        Signer: Codeunit "Digital Sign MX";
        Certificate: Text;
        CertificateNo: Text[250];
        Original: Text;
        OutStream: OutStream;
    begin
        Customer.Get(Payment."Customer No.");
        Company.Get();
        Setup.Get();
        GLSetup.Get();
        GetCertificate(Setup.Id, Certificate, CertificateNo);
        XmlDocument.ReadFrom(XmlHeaderTok, XmlDoc);
        XmlDoc.GetRoot(Root);
        Root.SetAttribute('Version', '4.0');
        Root.SetAttribute('Folio', Payment."Document No.");
        Root.SetAttribute('Fecha', FormatDateTime(Payment."Posting Date"));
        Root.SetAttribute('Sello', '');
        Root.SetAttribute('NoCertificado', CertificateNo);
        Root.SetAttribute('Certificado', Certificate);
        Root.SetAttribute('SubTotal', '0');
        Root.SetAttribute('Moneda', 'XXX');
        Root.SetAttribute('Total', '0');
        Root.SetAttribute('TipoDeComprobante', 'P');
        Root.SetAttribute('Exportacion', Customer."CFDI Export Code");
        Root.SetAttribute('LugarExpedicion', Company."SAT Postal Code");
        AddParty(Root, 'Emisor', Company."RFC Number", Company.Name, Company."SAT Tax Regime Classification", '', Helper);
        AddParty(Root, 'Receptor', Customer."RFC No.", Customer."CFDI Customer Name", Customer."SAT Tax Regime Classification", Customer."Post Code", Helper);
        AddConcept(Root, Helper);
        AddPagos(Root, Payment, GLSetup."LCY Code", Helper);
        Original := Signer.CreatePaymentOriginalString(XmlDoc);
        Root.SetAttribute('Sello', Signer.CreateDigitalSignature(Original, Setup.Id));
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        XmlDoc.WriteTo(OutStream);
    end;

    local procedure AddParty(Root: XmlElement; Name: Text; RFC: Text; PartyName: Text; Regime: Text; PostCode: Text; Helper: Codeunit "CFDI XML Helper MX")
    var
        Node, Child : XmlNode;
    begin
        Node := Root.AsXmlNode();
        Helper.AddElementCFDI(Node, Name, '', Child);
        Helper.AddAttribute(Child, 'Rfc', RFC);
        Helper.AddAttribute(Child, 'Nombre', PartyName);
        Helper.AddAttribute(Child, 'RegimenFiscal', Regime);
        if Name = 'Receptor' then begin Helper.AddAttribute(Child, 'DomicilioFiscalReceptor', PostCode); Helper.AddAttribute(Child, 'RegimenFiscalReceptor', Regime); Helper.AddAttribute(Child, 'UsoCFDI', 'CP01'); end;
    end;

    local procedure AddConcept(Root: XmlElement; Helper: Codeunit "CFDI XML Helper MX")
    var
        Node, Concepts, Concept : XmlNode;
    begin
        Node := Root.AsXmlNode();
        Helper.AddElementCFDI(Node, 'Conceptos', '', Concepts);
        Helper.AddElementCFDI(Concepts, 'Concepto', '', Concept);
        Helper.AddAttribute(Concept, 'ClaveProdServ', '84111506');
        Helper.AddAttribute(Concept, 'Cantidad', '1');
        Helper.AddAttribute(Concept, 'ClaveUnidad', 'ACT');
        Helper.AddAttribute(Concept, 'Descripcion', 'Pago');
        Helper.AddAttribute(Concept, 'ValorUnitario', '0');
        Helper.AddAttribute(Concept, 'Importe', '0');
        Helper.AddAttribute(Concept, 'ObjetoImp', '01');
    end;

    local procedure AddPagos(Root: XmlElement; Payment: Record "Cust. Ledger Entry"; LCY: Code[10]; Helper: Codeunit "CFDI XML Helper MX")
    var
        Dom: Codeunit "XML DOM Management";
        Detail: Record "Detailed Cust. Ledg. Entry";
        Applied: Record "Cust. Ledger Entry";
        CustomerBankAccount: Record "Customer Bank Account";
        WriteBack: Codeunit "CFDI Write-Back MX";
        Node, Complement, Pagos, Totals, Pago, Related : XmlNode; Amount: Decimal;
        EquivalenciaDR: Decimal;
        BalanceBefore: Decimal;
        BalanceAfter: Decimal;
        PartialNo: Integer;
        Base16: Decimal;
        Tax16: Decimal;
        Base8: Decimal;
        Tax8: Decimal;
        Base0: Decimal;
        Tax0: Decimal;
        BaseExempt: Decimal;
    begin
        Payment.CalcFields(Amount, "Amount (LCY)");
        Amount := Abs(Payment.Amount);
        Node := Root.AsXmlNode();
        Helper.AddElementCFDI(Node, 'Complemento', '', Complement);
        Dom.AddElementWithPrefix(Complement, 'Pagos', '', 'pago20', PagosNamespaceTok, Pagos);
        Helper.AddAttribute(Pagos, 'Version', '2.0');
        Dom.AddElementWithPrefix(Pagos, 'Totales', '', 'pago20', PagosNamespaceTok, Totals);
        Helper.AddAttribute(Totals, 'MontoTotalPagos', Helper.FormatAmount(Amount));
        Dom.AddElementWithPrefix(Pagos, 'Pago', '', 'pago20', PagosNamespaceTok, Pago);
        Helper.AddAttribute(Pago, 'FechaPago', FormatDateTime(Payment."Posting Date"));
        Helper.AddAttribute(Pago, 'FormaDePagoP', GetSATMethod(Payment."Payment Method Code"));
        Helper.AddAttribute(Pago, 'MonedaP', Currency(Payment."Currency Code", LCY));
        if Currency(Payment."Currency Code", LCY) <> LCY then
            Helper.AddAttribute(Pago, 'TipoCambioP', FormatDecimal(Round(Abs(Payment."Amount (LCY)") / Amount, 0.000001), 6))
        else
            Helper.AddAttribute(Pago, 'TipoCambioP', '1');
        Helper.AddAttribute(Pago, 'Monto', Helper.FormatAmount(Amount));
        if Currency(Payment."Currency Code", LCY) <> LCY then begin
            CustomerBankAccount.SetRange("Customer No.", Payment."Customer No.");
            if CustomerBankAccount.FindFirst() then
                Helper.AddAttribute(Pago, 'NomBancoOrdExt', CustomerBankAccount.Name);
        end;
        Detail.SetRange("Cust. Ledger Entry No.", Payment."Entry No.");
        Detail.SetRange("Entry Type", Detail."Entry Type"::Application);
        Detail.SetRange(Unapplied, false);
        if Detail.FindSet() then
            repeat
                if Applied.Get(Detail."Applied Cust. Ledger Entry No.") then begin
                    Applied.CalcFields(Amount);
                    Dom.AddElementWithPrefix(Pago, 'DoctoRelacionado', '', 'pago20', PagosNamespaceTok, Related);
                    Helper.AddAttribute(Related, 'IdDocumento', GetUUID(Applied, WriteBack));
                    Helper.AddAttribute(Related, 'MonedaDR', Currency(Applied."Currency Code", LCY));
                    Helper.AddAttributeSimple(Related, 'Folio', Applied."Document No.");
                    EquivalenciaDR := GetEquivalenciaDR(Detail, Payment, Applied, LCY);
                    if EquivalenciaDR <> 1 then
                        Helper.AddAttribute(Related, 'EquivalenciaDR', FormatDecimal(EquivalenciaDR, 10));
                    GetPartialPaymentData(Applied, Detail, BalanceBefore, PartialNo);
                    BalanceAfter := BalanceBefore - Abs(Detail.Amount);
                    if BalanceAfter < 0 then
                        BalanceAfter := 0;
                    Helper.AddAttribute(Related, 'NumParcialidad', Format(PartialNo));
                    Helper.AddAttribute(Related, 'ImpSaldoAnt', Helper.FormatAmount(BalanceBefore));
                    Helper.AddAttribute(Related, 'ImpPagado', Helper.FormatAmount(Abs(Detail.Amount)));
                    Helper.AddAttribute(Related, 'ImpSaldoInsoluto', Helper.FormatAmount(BalanceAfter));
                    if BalanceBefore <> 0 then
                        AddRelatedTaxes(Related, Applied, Abs(Detail.Amount) / BalanceBefore, Helper, Dom, Base16, Tax16, Base8, Tax8, Base0, Tax0, BaseExempt)
                    else
                        Helper.AddAttribute(Related, 'ObjetoImpDR', '01');
                end until Detail.Next() = 0;
        AddPaymentTaxes(Pago, Helper, Dom, Base16, Tax16, Base8, Tax8, Base0, Tax0, BaseExempt);
        AddTotals(Totals, Helper, Base16, Tax16, Base8, Tax8, Base0, Tax0, BaseExempt);
    end;

    local procedure AddRelatedTaxes(Related: XmlNode; Applied: Record "Cust. Ledger Entry"; Ratio: Decimal; Helper: Codeunit "CFDI XML Helper MX"; Dom: Codeunit "XML DOM Management"; var Base16: Decimal; var Tax16: Decimal; var Base8: Decimal; var Tax8: Decimal; var Base0: Decimal; var Tax0: Decimal; var BaseExempt: Decimal)
    var
        VATEntry: Record "VAT Entry";
        TaxesNode: XmlNode;
        TransfersNode: XmlNode;
        TransferNode: XmlNode;
        Base: Decimal;
        Tax: Decimal;
        Rate: Decimal;
    begin
        VATEntry.SetRange("Document No.", Applied."Document No.");
        if not VATEntry.FindSet() then begin
            Helper.AddAttribute(Related, 'ObjetoImpDR', '01');
            exit;
        end;
        Helper.AddAttribute(Related, 'ObjetoImpDR', '02');
        Dom.AddElementWithPrefix(Related, 'ImpuestosDR', '', 'pago20', PagosNamespaceTok, TaxesNode);
        Dom.AddElementWithPrefix(TaxesNode, 'TrasladosDR', '', 'pago20', PagosNamespaceTok, TransfersNode);
        repeat
            Base := Round(Abs(VATEntry.Base) * Ratio, 0.01);
            Tax := Round(Abs(VATEntry.Amount) * Ratio, 0.01);
            Rate := GetVATRate(VATEntry);
            if (Base = 0) and (Tax = 0) then
                continue;
            Dom.AddElementWithPrefix(TransfersNode, 'TrasladoDR', '', 'pago20', PagosNamespaceTok, TransferNode);
            Helper.AddAttribute(TransferNode, 'BaseDR', FormatDecimal(Base, 2));
            Helper.AddAttribute(TransferNode, 'ImpuestoDR', '002');
            if Rate = 0 then begin
                Helper.AddAttribute(TransferNode, 'TipoFactorDR', 'Exento');
                BaseExempt += Base;
            end else begin
                Helper.AddAttribute(TransferNode, 'TipoFactorDR', 'Tasa');
                Helper.AddAttribute(TransferNode, 'TasaOCuotaDR', FormatDecimal(Rate / 100, 6));
                Helper.AddAttribute(TransferNode, 'ImporteDR', FormatDecimal(Tax, 2));
                case Rate of
                    16:
                        begin
                            Base16 += Base;
                            Tax16 += Tax;
                        end;
                    8:
                        begin
                            Base8 += Base;
                            Tax8 += Tax;
                        end;
                    0:
                        begin
                            Base0 += Base;
                            Tax0 += Tax;
                        end;
                end;
            end;
        until VATEntry.Next() = 0;
    end;

    local procedure AddPaymentTaxes(Pago: XmlNode; Helper: Codeunit "CFDI XML Helper MX"; Dom: Codeunit "XML DOM Management"; Base16: Decimal; Tax16: Decimal; Base8: Decimal; Tax8: Decimal; Base0: Decimal; Tax0: Decimal; BaseExempt: Decimal)
    var
        TaxesNode: XmlNode;
        TransfersNode: XmlNode;
    begin
        if (Base16 + Base8 + Base0 + BaseExempt) = 0 then
            exit;
        Dom.AddElementWithPrefix(Pago, 'ImpuestosP', '', 'pago20', PagosNamespaceTok, TaxesNode);
        Dom.AddElementWithPrefix(TaxesNode, 'TrasladosP', '', 'pago20', PagosNamespaceTok, TransfersNode);
        AddPaymentTransfer(TransfersNode, Helper, Dom, Base16, Tax16, 16, false);
        AddPaymentTransfer(TransfersNode, Helper, Dom, Base8, Tax8, 8, false);
        AddPaymentTransfer(TransfersNode, Helper, Dom, Base0, Tax0, 0, false);
        AddPaymentTransfer(TransfersNode, Helper, Dom, BaseExempt, 0, 0, true);
    end;

    local procedure GetVATRate(VATEntry: Record "VAT Entry"): Decimal
    begin
        if VATEntry.Base = 0 then
            exit(0);
        exit(Round(Abs(VATEntry.Amount / VATEntry.Base) * 100, 0.000001));
    end;

    local procedure AddPaymentTransfer(TransfersNode: XmlNode; Helper: Codeunit "CFDI XML Helper MX"; Dom: Codeunit "XML DOM Management"; Base: Decimal; Tax: Decimal; Rate: Decimal; Exempt: Boolean)
    var
        TransferNode: XmlNode;
    begin
        if Base = 0 then
            exit;
        Dom.AddElementWithPrefix(TransfersNode, 'TrasladoP', '', 'pago20', PagosNamespaceTok, TransferNode);
        Helper.AddAttribute(TransferNode, 'BaseP', FormatDecimal(Round(Base, 0.000001, '<'), 6));
        Helper.AddAttribute(TransferNode, 'ImpuestoP', '002');
        if Exempt then
            Helper.AddAttribute(TransferNode, 'TipoFactorP', 'Exento')
        else begin
            Helper.AddAttribute(TransferNode, 'TipoFactorP', 'Tasa');
            Helper.AddAttribute(TransferNode, 'TasaOCuotaP', FormatDecimal(Rate / 100, 6));
            Helper.AddAttribute(TransferNode, 'ImporteP', FormatDecimal(Round(Tax, 0.000001, '<'), 6));
        end;
    end;

    local procedure AddTotals(Totals: XmlNode; Helper: Codeunit "CFDI XML Helper MX"; Base16: Decimal; Tax16: Decimal; Base8: Decimal; Tax8: Decimal; Base0: Decimal; Tax0: Decimal; BaseExempt: Decimal)
    begin
        if Base16 <> 0 then begin Helper.AddAttribute(Totals, 'TotalTrasladosBaseIVA16', FormatDecimal(Base16, 2)); Helper.AddAttribute(Totals, 'TotalTrasladosImpuestoIVA16', FormatDecimal(Tax16, 2)); end;
        if Base8 <> 0 then begin Helper.AddAttribute(Totals, 'TotalTrasladosBaseIVA8', FormatDecimal(Base8, 2)); Helper.AddAttribute(Totals, 'TotalTrasladosImpuestoIVA8', FormatDecimal(Tax8, 2)); end;
        if Base0 <> 0 then begin Helper.AddAttribute(Totals, 'TotalTrasladosBaseIVA0', FormatDecimal(Base0, 2)); Helper.AddAttribute(Totals, 'TotalTrasladosImpuestoIVA0', FormatDecimal(Tax0, 2)); end;
        if BaseExempt <> 0 then Helper.AddAttribute(Totals, 'TotalTrasladosBaseIVAExento', FormatDecimal(BaseExempt, 2));
    end;

    local procedure GetEquivalenciaDR(Detail: Record "Detailed Cust. Ledg. Entry"; Payment: Record "Cust. Ledger Entry"; Applied: Record "Cust. Ledger Entry"; LCY: Code[10]): Decimal
    var
        PaymentFactor: Decimal;
        DocumentFactor: Decimal;
    begin
        if Currency(Payment."Currency Code", LCY) = Currency(Applied."Currency Code", LCY) then
            exit(1);
        if (Detail."Amount (LCY)" = 0) or (Payment."Original Currency Factor" = 0) then
            exit(Round(Applied."Original Currency Factor" / Payment."Original Currency Factor", 0.0000000001));
        DocumentFactor := Detail.Amount / Detail."Amount (LCY)";
        PaymentFactor := Payment."Original Currency Factor";
        exit(Round(DocumentFactor / PaymentFactor, 0.0000000001));
    end;

    local procedure GetPartialPaymentData(Applied: Record "Cust. Ledger Entry"; CurrentDetail: Record "Detailed Cust. Ledg. Entry"; var BalanceBefore: Decimal; var PartialNo: Integer)
    var
        Detail: Record "Detailed Cust. Ledg. Entry";
        PreviousPayment: Record "Cust. Ledger Entry";
        PreviousPaid: Decimal;
    begin
        Applied.CalcFields(Amount);
        BalanceBefore := Abs(Applied.Amount);
        PartialNo := 1;
        Detail.SetRange("Applied Cust. Ledger Entry No.", Applied."Entry No.");
        Detail.SetRange("Entry Type", Detail."Entry Type"::Application);
        Detail.SetRange(Unapplied, false);
        if Detail.FindSet() then
            repeat
                if Detail."Entry No." = CurrentDetail."Entry No." then
                    continue;
                if PreviousPayment.Get(Detail."Cust. Ledger Entry No.") and
                   (PreviousPayment."Document Type" = PreviousPayment."Document Type"::Payment) and
                   (PreviousPayment."Fiscal Invoice Number PAC" <> '') then begin
                    PreviousPaid += Abs(Detail.Amount);
                    PartialNo += 1;
                end;
            until Detail.Next() = 0;
        BalanceBefore += PreviousPaid;
    end;

    local procedure FormatDecimal(Value: Decimal; Decimals: Integer): Text
    begin
        exit(Format(Abs(Value), 0, '<Precision,' + Format(Decimals) + ':' + Format(Decimals) + '><Standard Format,1>'));
    end;

    local procedure GetUUID(Applied: Record "Cust. Ledger Entry"; WriteBack: Codeunit "CFDI Write-Back MX"): Text
    var
        SI: Record "Sales Invoice Header";
        SVI: Record "Service Invoice Header";
    begin
        if SI.Get(Applied."Document No.") then begin
            if WriteBack.GetUUIDForDocument(SI.RecordId()) <> '' then exit(WriteBack.GetUUIDForDocument(SI.RecordId()));
        end;
        if SVI.Get(Applied."Document No.") then begin
            if WriteBack.GetUUIDForDocument(SVI.RecordId()) <> '' then exit(WriteBack.GetUUIDForDocument(SVI.RecordId()));
        end;
        Error(AppliedDocumentNotStampedErr, Applied."Document No.");
    end;

    local procedure Currency(Code: Code[10]; LCY: Code[10]): Code[10]
    begin
        if Code = '' then exit(LCY);
        exit(Code);
    end;

    local procedure GetSATMethod(Code: Code[10]): Code[10]
    var
        M: Record "Payment Method";
    begin
        M.Get(Code);
        exit(M."SAT Method of Payment");
    end;

    local procedure FormatDateTime(D: Date): Text
    begin
        exit(Format(CreateDateTime(D, 120000T), 0, '<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>'));
    end;

    local procedure GetCertificate(Id: Code[10]; var Certificate: Text; var No: Text[250])
    var
        Setup: Record "MX Connection Setup";
        Iso: Record "Isolated Certificate";
        CM: Codeunit "Certificate Management";
        X: Codeunit X509Certificate2;
        Signer: Codeunit "Digital Sign MX";
    begin
        Setup.Get(Id);
        Iso.Get(Setup."SAT Certificate");
        Certificate := X.GetRawCertDataAsBase64String(CM.GetCertAsBase64String(Iso), CM.GetPasswordAsSecret(Iso));
        No := Signer.GetCertificateSerialNo(Id);
    end;

    var
        PagosNamespaceTok: Label 'http://www.sat.gob.mx/Pagos20', Locked = true;
        XmlHeaderTok: Label '<cfdi:Comprobante xmlns:cfdi="http://www.sat.gob.mx/cfd/4" xmlns:pago20="http://www.sat.gob.mx/Pagos20"/>', Locked = true;
        AppliedDocumentNotStampedErr: Label 'Applied document %1 is not stamped.', Comment = '%1 = document number';
}
