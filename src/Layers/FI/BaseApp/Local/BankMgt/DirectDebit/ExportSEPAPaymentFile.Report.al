// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Bank.DirectDebit;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Payment;
using Microsoft.Bank.Setup;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.NoSeries;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using System.IO;
using System.Telemetry;
using System.Utilities;

report 13403 "Export SEPA Payment File"
{
    Caption = 'Export SEPA Payment File';
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(RefPaymentExported; "Ref. Payment - Exported")
        {
            DataItemTableView = sorting("Payment Account", "Payment Date") where(Transferred = const(false), "Applied Payments" = const(false), "SEPA Payment" = const(true));

            trigger OnAfterGetRecord()
            begin
                if ("Payment Account" <> CurrPaymentAccount) or ("Payment Date" <> CurrPaymentDate) then begin
                    if not FirstPaymentHeader then // Closing element for previous Payment Information (PmtInf)
                        XMLNodeCurr.GetParent(XMLNodeCurr);
                    ExportPaymentHeader();
                    CurrPaymentAccount := "Payment Account";
                    CurrPaymentDate := "Payment Date";
                    FirstPaymentHeader := false;
                end;
                ExportPaymentInformation();
            end;

            trigger OnPostDataItem()
            var
                XMLDocText: Text;
                BlobOutStream: OutStream;
            begin
                TempBlob.CreateOutStream(BlobOutStream, TextEncoding::UTF8);
                XMLDomDoc.WriteTo(XMLDocText);
                BlobOutStream.WriteText(XMLDocText);
                Clear(XMLDomDoc);
            end;

            trigger OnPreDataItem()
            begin
                GLSetup.Get();
                CompanyInfo.Get();
                PurchSetup.Get();
                CheckSEPAValidations();
                if IsEmpty() then
                    Error(Text13403);

                CurrPaymentAccount := '';
                CurrPaymentDate := 0D;
                Clear(XMLDomDoc);

                ExportHeader();
                FirstPaymentHeader := true;
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnInitReport()
    var
        SEPARefPmtExported: Record "Ref. Payment - Exported";
    begin
        SEPARefPmtExported.Reset();
        SEPARefPmtExported.SetCurrentKey("Payment Date", "Vendor No.", "Entry No.");
        SEPARefPmtExported.SetRange(Transferred, false);
        SEPARefPmtExported.SetRange("Applied Payments", false);
        if SEPARefPmtExported.FindFirst() then begin
            ReferenceFileSetup.Reset();
            ReferenceFileSetup.SetRange("No.", SEPARefPmtExported."Payment Account");
            if ReferenceFileSetup.FindFirst() then begin
                ReferenceFileSetup.TestField("Bank Party ID");
                ReferenceFileSetup.Validate("Bank Party ID");
                FileName := ReferenceFileSetup."File Name";
            end;
        end;
    end;

    trigger OnPostReport()
    var
        BlobInStream: InStream;
        CancelDownload: Boolean;
    begin
        OnBeforeDownloadFromBlob(TempBlob, CancelDownload);
        if not CancelDownload then begin
            TempBlob.CreateInStream(BlobInStream);
            DownloadFromStream(BlobInStream, '', '', '', FileName);
            Message(Text13400, FileName);
        end;
    end;

    trigger OnPreReport()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        SEPACTExportFile: Codeunit "SEPA CT-Export File";
    begin
        FeatureTelemetry.LogUptake('0000N2J', SEPACTExportFile.FeatureName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000N2K', SEPACTExportFile.FeatureName(), 'Report (FI) Export SEPA Payment File');

        if FileName = '' then
            Error(Text13407);

        TmpFileNameServer := FileMgt.ServerTempFileName('.tmp');
        XMLFileNameServer := FileMgt.ServerTempFileName('.xml')
    end;

    var
        CompanyInfo: Record "Company Information";
        PurchSetup: Record "Purchases & Payables Setup";
        Vendor: Record Vendor;
        ReferenceFileSetup: Record "Reference File Setup";
        GLSetup: Record "General Ledger Setup";
        FileMgt: Codeunit "File Management";
        TempBlob: Codeunit "Temp Blob";
        XMLDomDoc: XmlDocument;
        XMLNodeCurr: XmlElement;
        XMLNameSpace: Text;
        XMLFileNameServer: Text;
        TmpFileNameServer: Text;
        FileName: Text;
        MessageId: Text[20];
        Text13400: Label 'Transfer File %1 Created Successfully.';
        Text13403: Label 'There is nothing to send.';
        Text13405: Label 'Payment Account %1 is not in a Country/Region that allows SEPA Payments.';
        Text13407: Label 'Enter the file name.';
        CurrPaymentAccount: Code[20];
        CurrPaymentDate: Date;
        ControlSum: Decimal;
        FirstPaymentHeader: Boolean;

    local procedure ExportHeader()
    var
        XMLRootElement: XmlElement;
        XMLNewChild: XmlElement;
        xsiNameSpace: Text;
        xsdName: Text;
    begin
        xsdName := 'pain.001.001.02';
        XMLNameSpace := 'urn:iso:std:iso:20022:tech:xsd:' + xsdName;
        xsiNameSpace := 'http://www.w3.org/2001/XMLSchema-instance';

        XmlDocument.ReadFrom(
          '<?xml version="1.0" encoding="UTF-8"?><Document xmlns="' + XMLNameSpace + '" xmlns:xsi="' + xsiNameSpace + '"></Document>', XMLDomDoc);
        XMLDomDoc.GetRoot(XMLRootElement);
        XMLRootElement.SetAttribute('schemaLocation', xsiNameSpace, XMLNameSpace + ' ' + xsdName + '.xsd');

        XMLNodeCurr := XMLRootElement;
        AddElement(XMLNodeCurr, xsdName, '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;
        ExportGroupHeader();
    end;

    local procedure AddElement(var ParentElement: XmlElement; NodeName: Text; NodeText: Text; var CreatedElement: XmlElement)
    begin
        if NodeText <> '' then
            CreatedElement := XmlElement.Create(NodeName, XMLNameSpace, NodeText)
        else
            CreatedElement := XmlElement.Create(NodeName, XMLNameSpace);
        ParentElement.Add(CreatedElement);
    end;

    local procedure ExportGroupHeader()
    var
        RefPaymentExported: Record "Ref. Payment - Exported";
        NoSeries: Codeunit "No. Series";
        XMLNewChild: XmlElement;
    begin
        AddElement(XMLNodeCurr, 'GrpHdr', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;
        MessageId := NoSeries.GetNextNo(PurchSetup."Bank Batch Nos.");
        AddElement(XMLNodeCurr, 'MsgId', MessageId, XMLNewChild);
        AddElement(XMLNodeCurr, 'CreDtTm', Format(CurrentDateTime, 19, 9), XMLNewChild);
        RefPaymentExported.Reset();
        RefPaymentExported.SetRange("SEPA Payment", true);
        RefPaymentExported.SetRange(Transferred, false);
        RefPaymentExported.SetRange("Applied Payments", false);
        if RefPaymentExported.FindFirst() then
            AddElement(XMLNodeCurr, 'NbOfTxs', Format(RefPaymentExported.Count), XMLNewChild);
        AddElement(XMLNodeCurr, 'CtrlSum', Format(ControlSum, 0, '<Precision,2:2><Standard Format,9>'), XMLNewChild);
        AddElement(XMLNodeCurr, 'Grpg', 'MIXD', XMLNewChild);
        AddElement(XMLNodeCurr, 'InitgPty', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;
        AddElement(XMLNodeCurr, 'Nm', CompanyInfo.Name, XMLNewChild);
        AddElement(XMLNodeCurr, 'PstlAdr', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        if (CompanyInfo.Address <> '') or (CompanyInfo."Address 2" <> '') then
            AddElement(XMLNodeCurr, 'StrtNm', CopyStr(GetAddressLine(0, 1), 1, 70), XMLNewChild);
        if DelChr(CompanyInfo."Post Code", '<>') <> '' then
            AddElement(XMLNodeCurr, 'PstCd', CopyStr(DelChr(CompanyInfo."Post Code", '<>'), 1, 16), XMLNewChild);
        if DelChr(CompanyInfo.City, '<>') <> '' then
            AddElement(XMLNodeCurr, 'TwnNm', CopyStr(DelChr(CompanyInfo.City, '<>'), 1, 35), XMLNewChild);
        AddElement(XMLNodeCurr, 'Ctry', CopyStr(CompanyInfo."Country/Region Code", 1, 2), XMLNewChild);
        XMLNodeCurr.GetParent(XMLNodeCurr);
        AddElement(XMLNodeCurr, 'Id', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;
        AddElement(XMLNodeCurr, 'OrgId', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;
        AddElement(XMLNodeCurr, 'BkPtyId', ReferenceFileSetup."Bank Party ID", XMLNewChild);
        XMLNodeCurr.GetParent(XMLNodeCurr);
        XMLNodeCurr.GetParent(XMLNodeCurr);
        XMLNodeCurr.GetParent(XMLNodeCurr);
        XMLNodeCurr.GetParent(XMLNodeCurr);
    end;

    local procedure ExportPaymentHeader()
    var
        BankAcc: Record "Bank Account";
        XMLNewChild: XmlElement;
    begin
        BankAcc.Get(RefPaymentExported."Payment Account");

        AddElement(XMLNodeCurr, 'PmtInf', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'PmtInfId', MessageId, XMLNewChild);
        AddElement(XMLNodeCurr, 'PmtMtd', 'TRF', XMLNewChild);
        AddElement(XMLNodeCurr, 'ReqdExctnDt', Format(RefPaymentExported."Payment Date", 0, 9), XMLNewChild); // r30
        AddElement(XMLNodeCurr, 'Dbtr', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'Nm', CompanyInfo.Name, XMLNewChild);
        AddElement(XMLNodeCurr, 'PstlAdr', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        if (CompanyInfo.Address <> '') or (CompanyInfo."Address 2" <> '') then
            AddElement(XMLNodeCurr, 'StrtNm', CopyStr(GetAddressLine(0, 1), 1, 70), XMLNewChild);
        if DelChr(CompanyInfo."Post Code", '<>') <> '' then
            AddElement(XMLNodeCurr, 'PstCd', CopyStr(DelChr(CompanyInfo."Post Code", '<>'), 1, 16), XMLNewChild);
        if DelChr(CompanyInfo.City, '<>') <> '' then
            AddElement(XMLNodeCurr, 'TwnNm', CopyStr(DelChr(CompanyInfo.City, '<>'), 1, 35), XMLNewChild);
        AddElement(XMLNodeCurr, 'Ctry', CopyStr(CompanyInfo."Country/Region Code", 1, 2), XMLNewChild);
        XMLNodeCurr.GetParent(XMLNodeCurr);

        AddElement(XMLNodeCurr, 'Id', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;
        AddElement(XMLNodeCurr, 'OrgId', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;
        AddElement(XMLNodeCurr, 'BkPtyId', ReferenceFileSetup."Bank Party ID", XMLNewChild);
        XMLNodeCurr.GetParent(XMLNodeCurr);
        XMLNodeCurr.GetParent(XMLNodeCurr);
        XMLNodeCurr.GetParent(XMLNodeCurr);

        AddElement(XMLNodeCurr, 'DbtrAcct', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'Id', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'IBAN', CopyStr(BankAcc.IBAN, 1, 34), XMLNewChild);
        XMLNodeCurr.GetParent(XMLNodeCurr);
        XMLNodeCurr.GetParent(XMLNodeCurr);

        AddElement(XMLNodeCurr, 'DbtrAgt', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'FinInstnId', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'BIC', CopyStr(BankAcc."SWIFT Code", 1, 11), XMLNewChild);
        XMLNodeCurr.GetParent(XMLNodeCurr);
        XMLNodeCurr.GetParent(XMLNodeCurr);

        AddElement(XMLNodeCurr, 'ChrgBr', 'SLEV', XMLNewChild);
    end;

    local procedure ExportPaymentInformation()
    var
        VendBankAcc: Record "Vendor Bank Account";
        XMLNewChild: XmlElement;
    begin
        Vendor.Get(RefPaymentExported."Vendor No.");
        VendBankAcc.Get(RefPaymentExported."Vendor No.", RefPaymentExported."Vendor Account");

        AddElement(XMLNodeCurr, 'CdtTrfTxInf', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'PmtId', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'EndToEndId', RefPaymentExported."Document No.", XMLNewChild);
        XMLNodeCurr.GetParent(XMLNodeCurr);

        AddElement(XMLNodeCurr, 'Amt', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;
        AddElement(
          XMLNodeCurr, 'InstdAmt', Format(RefPaymentExported.Amount, 0, '<Precision,2:2><Standard Format,9>'), XMLNewChild);
        XMLNewChild.SetAttribute('Ccy', GetCurrencyCode(RefPaymentExported."Currency Code"));
        XMLNodeCurr.GetParent(XMLNodeCurr);

        AddElement(XMLNodeCurr, 'CdtrAgt', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'FinInstnId', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        if VendBankAcc."SWIFT Code" <> '' then
            AddElement(XMLNodeCurr, 'BIC', CopyStr(VendBankAcc."SWIFT Code", 1, 11), XMLNewChild)
        else begin
            AddElement(XMLNodeCurr, 'CmbndId', '', XMLNewChild);
            XMLNodeCurr := XMLNewChild;
            if VendBankAcc."Clearing Code" <> '' then begin
                AddElement(XMLNodeCurr, 'ClrSysMmbId', '', XMLNewChild);
                XMLNodeCurr := XMLNewChild;
                AddElement(XMLNodeCurr, 'Id', VendBankAcc."Clearing Code", XMLNewChild);
                XMLNodeCurr.GetParent(XMLNodeCurr);
            end;

            if VendBankAcc.Name <> '' then
                AddElement(XMLNodeCurr, 'Nm', CopyStr(VendBankAcc.Name, 1, 70), XMLNewChild);

            AddElement(XMLNodeCurr, 'PstlAdr', '', XMLNewChild);
            XMLNodeCurr := XMLNewChild;
            if VendBankAcc.Address <> '' then
                AddElement(
                    XMLNodeCurr, 'StrtNm',
                    CopyStr(JoinAddressFields(VendBankAcc.Address, VendBankAcc."Address 2"), 1, 70), XMLNewChild);
            if DelChr(VendBankAcc."Post Code", '<>') <> '' then
                AddElement(XMLNodeCurr, 'PstCd', CopyStr(DelChr(VendBankAcc."Post Code", '<>'), 1, 16), XMLNewChild);
            if VendBankAcc.City <> '' then
                AddElement(XMLNodeCurr, 'TwnNm', CopyStr(DelChr(VendBankAcc.City, '<>'), 1, 35), XMLNewChild);
            AddElement(XMLNodeCurr, 'Ctry', VendBankAcc."Country/Region Code", XMLNewChild);

            XMLNodeCurr.GetParent(XMLNodeCurr);
            XMLNodeCurr.GetParent(XMLNodeCurr);
        end;

        XMLNodeCurr.GetParent(XMLNodeCurr);
        XMLNodeCurr.GetParent(XMLNodeCurr);

        AddElement(XMLNodeCurr, 'Cdtr', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'Nm', CopyStr(RefPaymentExported."Description 2", 1, 70), XMLNewChild);
        AddElement(XMLNodeCurr, 'PstlAdr', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        if (Vendor.Address <> '') or (Vendor."Address 2" <> '') then
            AddElement(XMLNodeCurr, 'StrtNm', CopyStr(GetAddressLine(1, 1), 1, 70), XMLNewChild);
        if DelChr(Vendor."Post Code", '<>') <> '' then
            AddElement(XMLNodeCurr, 'PstCd', CopyStr(DelChr(Vendor."Post Code", '<>'), 1, 16), XMLNewChild);
        if DelChr(Vendor.City, '<>') <> '' then
            AddElement(XMLNodeCurr, 'TwnNm', CopyStr(DelChr(Vendor.City, '<>'), 1, 35), XMLNewChild);
        AddElement(XMLNodeCurr, 'Ctry', CopyStr(Vendor."Country/Region Code", 1, 2), XMLNewChild);
        XMLNodeCurr.GetParent(XMLNodeCurr);
        XMLNodeCurr.GetParent(XMLNodeCurr);

        AddElement(XMLNodeCurr, 'CdtrAcct', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'Id', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        if VendBankAcc.IBAN <> '' then
            AddElement(XMLNodeCurr, 'IBAN', CopyStr(VendBankAcc.IBAN, 1, 34), XMLNewChild)
        else
            AddElement(XMLNodeCurr, 'BBAN', CopyStr(VendBankAcc."Bank Account No.", 1, 30), XMLNewChild);
        XMLNodeCurr.GetParent(XMLNodeCurr);
        XMLNodeCurr.GetParent(XMLNodeCurr);

        AddElement(XMLNodeCurr, 'RmtInf', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;
        RefPaymentExported.UpdateRemittanceInfo();
        if RefPaymentExported."Remittance Information" = RefPaymentExported."Remittance Information"::Structured then begin
            AddElement(XMLNodeCurr, 'Strd', '', XMLNewChild);
            XMLNodeCurr := XMLNewChild;
            if not RefPaymentExported."Foreign Payment" then begin
                AddElement(XMLNodeCurr, 'CdtrRefInf', '', XMLNewChild);
                XMLNodeCurr := XMLNewChild;
                AddElement(XMLNodeCurr, 'CdtrRefTp', '', XMLNewChild);
                XMLNodeCurr := XMLNewChild;
                AddElement(XMLNodeCurr, 'Cd', 'SCOR', XMLNewChild);
                XMLNodeCurr.GetParent(XMLNodeCurr);
                if RefPaymentExported."Invoice Message" <> '' then
                    AddElement(XMLNodeCurr, 'CdtrRef', AddLeadingZeros(RefPaymentExported."Invoice Message", 20, 35), XMLNewChild);
            end else begin
                AddElement(XMLNodeCurr, 'RfrdDocInf', '', XMLNewChild);
                XMLNodeCurr := XMLNewChild;
                AddElement(XMLNodeCurr, 'RfrdDocTp', '', XMLNewChild);
                XMLNodeCurr := XMLNewChild;
                AddElement(XMLNodeCurr, 'Cd', 'CINV', XMLNewChild);
                XMLNodeCurr.GetParent(XMLNodeCurr);
                if RefPaymentExported."External Document No." <> '' then
                    AddElement(XMLNodeCurr, 'RfrdDocNb', RefPaymentExported."External Document No.", XMLNewChild);
            end;
            XMLNodeCurr.GetParent(XMLNodeCurr);
            XMLNodeCurr.GetParent(XMLNodeCurr);
        end else
            if RefPaymentExported."External Document No." <> '' then
                AddElement(XMLNodeCurr, 'Ustrd', RefPaymentExported."External Document No.", XMLNewChild);
        XMLNodeCurr.GetParent(XMLNodeCurr);

        RefPaymentExported.Transferred := true;
        RefPaymentExported."Transfer Date" := Today;
        RefPaymentExported."Transfer Time" := Time;
        RefPaymentExported."Batch Code" := MessageId;
        RefPaymentExported."Payment Execution Date" := RefPaymentExported."Payment Date";
        RefPaymentExported."File Name" := CopyStr(FileName, 1, MaxStrLen(RefPaymentExported."File Name"));
        RefPaymentExported.Modify();
        RefPaymentExported.MarkAffiliatedAsTransferred();

        XMLNodeCurr.GetParent(XMLNodeCurr);
    end;

    local procedure CheckSEPAValidations()
    var
        Country: Record "Country/Region";
        BankAcc: Record "Bank Account";
        VendorBankAcc: Record "Vendor Bank Account";
    begin
        ControlSum := 0;
        RefPaymentExported.Reset();
        RefPaymentExported.SetCurrentKey("Payment Account", "Payment Date");
        RefPaymentExported.SetRange(Transferred, false);
        RefPaymentExported.SetRange("Applied Payments", false);
        RefPaymentExported.SetRange("SEPA Payment", true);
        if RefPaymentExported.FindSet() then
            repeat
                RefPaymentExported.TestField("Vendor No.");
                RefPaymentExported.TestField("Description 2");
                RefPaymentExported.TestField("Vendor Account");
                RefPaymentExported.TestField("Document No.");
                RefPaymentExported.TestField(Amount);
                RefPaymentExported.TestField("Payment Account");
                RefPaymentExported.TestField("Payment Date");

                BankAcc.Get(RefPaymentExported."Payment Account");
                BankAcc.TestField(IBAN);
                BankAcc.TestField("SWIFT Code");
                if not Country.Get(BankAcc."Country/Region Code") then
                    BankAcc.FieldError("Country/Region Code");
                if not Country."SEPA Allowed" then
                    Error(Text13405, RefPaymentExported."Payment Account");

                VendorBankAcc.Get(RefPaymentExported."Vendor No.", RefPaymentExported."Vendor Account");
                if not Country.Get(VendorBankAcc."Country/Region Code") then
                    VendorBankAcc.FieldError("Country/Region Code");
                if Country."SEPA Allowed" then
                    VendorBankAcc.TestField(IBAN)
                else
                    if VendorBankAcc.IBAN = '' then
                        VendorBankAcc.TestField("Bank Account No.");

                ControlSum += RefPaymentExported.Amount;
            until RefPaymentExported.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure AddCRLF(Char: Char; var NeedsCRLF: Boolean): Boolean
    begin
        case Char of
            60: // '<'
                if NeedsCRLF then begin
                    NeedsCRLF := false;
                    exit(true);
                end;
            62: // '>'
                NeedsCRLF := true;
            0, 32:
                ;
            else
                NeedsCRLF := false;
        end;
        exit(false);
    end;

    local procedure AddLeadingZeros(Text: Text[250]; MinLen: Integer; MaxLen: Integer): Text[250]
    begin
        if StrLen(Text) < MinLen then
            Text := PadStr('', MinLen - StrLen(Text), '0') + Text;
        exit(CopyStr(Text, 1, MaxLen));
    end;

    local procedure GetAddressLine(Type: Option Company,Vendor; No: Integer): Text[250]
    begin
        case Type of
            Type::Company:
                if No = 1 then
                    exit(CopyStr(JoinAddressFields(CompanyInfo.Address, CompanyInfo."Address 2"), 1, 250))
                else
                    exit(CopyStr(JoinAddressFields(CompanyInfo."Post Code", CompanyInfo.City), 1, 250));
            Type::Vendor:
                if No = 1 then
                    exit(CopyStr(JoinAddressFields(Vendor.Address, Vendor."Address 2"), 1, 250))
                else
                    exit(CopyStr(JoinAddressFields(Vendor."Post Code", Vendor.City), 1, 250));
        end;
    end;

    local procedure JoinAddressFields(Field1: Text; Field2: Text): Text
    begin
        exit(DelChr(Field1, '<>') + ' ' + DelChr(Field2, '<>'));
    end;

    local procedure GetCurrencyCode(CurrencyCode: Code[10]): Code[10]
    begin
        if CurrencyCode = '' then
            exit(GLSetup."LCY Code");
        exit(CurrencyCode);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDownloadFromBlob(var TempBlob: Codeunit "Temp Blob"; var CancelDownload: Boolean)
    begin
    end;
}
