// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.DirectDebit;

using Microsoft.Bank.Payment;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Payables;
using Microsoft.Utilities;
using System.Telemetry;

/// <summary>
/// XMLPort for exporting SEPA credit transfers in pain.001.001.03 format.
/// Generates XML files compliant with SEPA Customer Credit Transfer Initiation standard
/// for submission to banks for automated payment processing.
/// </summary>
xmlport 1000 "SEPA CT pain.001.001.03"
{
    Caption = 'SEPA CT pain.001.001.03';
    DefaultNamespace = 'urn:iso:std:iso:20022:tech:xsd:pain.001.001.03';
    Direction = Export;
    Encoding = UTF8;
    FormatEvaluate = Xml;
    UseDefaultNamespace = true;

    schema
    {
        tableelement("Gen. Journal Line"; "Gen. Journal Line")
        {
            XmlName = 'Document';
            UseTemporary = true;
            tableelement(companyinformation; "Company Information")
            {
                XmlName = 'CstmrCdtTrfInitn';
                textelement(GrpHdr)
                {
                    textelement(messageid)
                    {
                        XmlName = 'MsgId';
                    }
                    textelement(createddatetime)
                    {
                        XmlName = 'CreDtTm';
                    }
                    textelement(nooftransfers)
                    {
                        XmlName = 'NbOfTxs';
                    }
                    textelement(controlsum)
                    {
                        XmlName = 'CtrlSum';
                    }
                    textelement(InitgPty)
                    {
                        fieldelement(Nm; CompanyInformation.Name)
                        {
                        }
                        textelement(initgptypstladr)
                        {
                            XmlName = 'PstlAdr';
                            fieldelement(StrtNm; CompanyInformation.Address)
                            {

                                trigger OnBeforePassField()
                                begin
                                    if CompanyInformation.Address = '' then
                                        currXMLport.Skip();
                                end;
                            }
                            fieldelement(PstCd; CompanyInformation."Post Code")
                            {

                                trigger OnBeforePassField()
                                begin
                                    if CompanyInformation."Post Code" = '' then
                                        currXMLport.Skip();
                                end;
                            }
                            fieldelement(TwnNm; CompanyInformation.City)
                            {

                                trigger OnBeforePassField()
                                begin
                                    if CompanyInformation.City = '' then
                                        currXMLport.Skip();
                                end;
                            }
                            fieldelement(Ctry; CompanyInformation."Country/Region Code")
                            {

                                trigger OnBeforePassField()
                                begin
                                    if CompanyInformation."Country/Region Code" = '' then
                                        currXMLport.Skip();
                                end;
                            }
                        }
                        textelement(initgptyid)
                        {
                            XmlName = 'Id';
                            textelement(initgptyorgid)
                            {
                                XmlName = 'OrgId';
                                textelement(initgptyothrinitgpty)
                                {
                                    XmlName = 'Othr';
                                    fieldelement(Id; CompanyInformation."VAT Registration No.")
                                    {
                                    }
                                    textelement(schemaname)
                                    {
                                        XmlName = 'SchmeNm';
                                        textelement(cd)
                                        {
                                            XmlName = 'Cd';

                                            trigger OnBeforePassVariable()
                                            begin
                                                Cd := 'BANK';
                                            end;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                tableelement(paymentexportdatagroup; "Payment Export Data")
                {
                    XmlName = 'PmtInf';
                    UseTemporary = true;
                    fieldelement(PmtInfId; PaymentExportDataGroup."Payment Information ID")
                    {
                    }
                    fieldelement(PmtMtd; PaymentExportDataGroup."SEPA Payment Method Text")
                    {
                    }
                    fieldelement(BtchBookg; PaymentExportDataGroup."SEPA Batch Booking")
                    {
                    }
                    fieldelement(NbOfTxs; PaymentExportDataGroup."Line No.")
                    {
                    }
                    fieldelement(CtrlSum; PaymentExportDataGroup.Amount)
                    {
                    }
                    textelement(PmtTpInf)
                    {
                        fieldelement(InstrPrty; PaymentExportDataGroup."SEPA Instruction Priority Text")
                        {
                        }
                    }
                    fieldelement(ReqdExctnDt; PaymentExportDataGroup."Transfer Date")
                    {
                    }
                    textelement(Dbtr)
                    {
                        fieldelement(Nm; CompanyInformation.Name)
                        {
                        }
                        textelement(dbtrpstladr)
                        {
                            XmlName = 'PstlAdr';
                            fieldelement(StrtNm; CompanyInformation.Address)
                            {

                                trigger OnBeforePassField()
                                begin
                                    if CompanyInformation.Address = '' then
                                        currXMLport.Skip();
                                end;
                            }
                            fieldelement(PstCd; CompanyInformation."Post Code")
                            {

                                trigger OnBeforePassField()
                                begin
                                    if CompanyInformation."Post Code" = '' then
                                        currXMLport.Skip();
                                end;
                            }
                            fieldelement(TwnNm; CompanyInformation.City)
                            {

                                trigger OnBeforePassField()
                                begin
                                    if CompanyInformation.City = '' then
                                        currXMLport.Skip();
                                end;
                            }
                            fieldelement(Ctry; CompanyInformation."Country/Region Code")
                            {

                                trigger OnBeforePassField()
                                begin
                                    if CompanyInformation."Country/Region Code" = '' then
                                        currXMLport.Skip();
                                end;
                            }
                        }
                        textelement(dbtrid)
                        {
                            XmlName = 'Id';
                            textelement(dbtrorgid)
                            {
                                XmlName = 'OrgId';
                                fieldelement(BICOrBEI; PaymentExportDataGroup."Sender Bank BIC")
                                {
                                }
                            }

                            trigger OnBeforePassVariable()
                            begin
                                if PaymentExportDataGroup."Sender Bank BIC" = '' then
                                    currXMLport.Skip();
                            end;
                        }
                    }
                    textelement(DbtrAcct)
                    {
                        textelement(dbtracctid)
                        {
                            XmlName = 'Id';
                            fieldelement(IBAN; PaymentExportDataGroup."Sender Bank Account No.")
                            {
                                MaxOccurs = Once;
                                MinOccurs = Once;
                            }
                        }
                    }
                    textelement(DbtrAgt)
                    {
                        textelement(dbtragtfininstnid)
                        {
                            XmlName = 'FinInstnId';
                            fieldelement(BIC; PaymentExportDataGroup."Sender Bank BIC")
                            {
                                MaxOccurs = Once;
                                MinOccurs = Once;
                            }
                        }

                        trigger OnBeforePassVariable()
                        begin
                            if PaymentExportDataGroup."Sender Bank BIC" = '' then
                                currXMLport.Skip();
                        end;
                    }
                    fieldelement(ChrgBr; PaymentExportDataGroup."SEPA Charge Bearer Text")
                    {
                    }
                    tableelement(paymentexportdata; "Payment Export Data")
                    {
                        LinkFields = "Sender Bank BIC" = field("Sender Bank BIC"), Urgent = field(Urgent), "Transfer Date" = field("Transfer Date"), "SEPA Batch Booking" = field("SEPA Batch Booking"), "SEPA Charge Bearer Text" = field("SEPA Charge Bearer Text");
                        LinkTable = PaymentExportDataGroup;
                        XmlName = 'CdtTrfTxInf';
                        UseTemporary = true;
                        textelement(PmtId)
                        {
                            textelement(InstrId)
                            {

                                trigger OnBeforePassVariable()
                                begin
                                    InstrId := DelChr(CreateGuid(), '=', '{}-');
                                end;
                            }
                            fieldelement(EndToEndId; PaymentExportData."End-to-End ID")
                            {
                            }
                        }
                        textelement(Amt)
                        {
                            fieldelement(InstdAmt; PaymentExportData.Amount)
                            {
                                fieldattribute(Ccy; PaymentExportData."Currency Code")
                                {
                                }
                            }
                        }
                        textelement(CdtrAgt)
                        {
                            textelement(cdtragtfininstnid)
                            {
                                XmlName = 'FinInstnId';
                                fieldelement(BIC; PaymentExportData."Recipient Bank BIC")
                                {
                                    FieldValidate = yes;
                                }
                            }

                            trigger OnBeforePassVariable()
                            begin
                                if PaymentExportData."Recipient Bank BIC" = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(Cdtr)
                        {
                            fieldelement(Nm; PaymentExportData."Recipient Name")
                            {
                            }
                            textelement(cdtrpstladr)
                            {
                                XmlName = 'PstlAdr';
                                fieldelement(StrtNm; PaymentExportData."Recipient Address")
                                {

                                    trigger OnBeforePassField()
                                    begin
                                        if PaymentExportData."Recipient Address" = '' then
                                            currXMLport.Skip();
                                    end;
                                }
                                fieldelement(PstCd; PaymentExportData."Recipient Post Code")
                                {

                                    trigger OnBeforePassField()
                                    begin
                                        if PaymentExportData."Recipient Post Code" = '' then
                                            currXMLport.Skip();
                                    end;
                                }
                                fieldelement(TwnNm; PaymentExportData."Recipient City")
                                {

                                    trigger OnBeforePassField()
                                    begin
                                        if PaymentExportData."Recipient City" = '' then
                                            currXMLport.Skip();
                                    end;
                                }
                                fieldelement(Ctry; PaymentExportData."Recipient Country/Region Code")
                                {

                                    trigger OnBeforePassField()
                                    begin
                                        if PaymentExportData."Recipient Country/Region Code" = '' then
                                            currXMLport.Skip();
                                    end;
                                }

                                trigger OnBeforePassVariable()
                                begin
                                    if (PaymentExportData."Recipient Address" = '') and
                                       (PaymentExportData."Recipient Post Code" = '') and
                                       (PaymentExportData."Recipient City" = '') and
                                       (PaymentExportData."Recipient Country/Region Code" = '')
                                    then
                                        currXMLport.Skip();
                                end;
                            }
                        }
                        textelement(CdtrAcct)
                        {
                            textelement(cdtracctid)
                            {
                                XmlName = 'Id';
                                fieldelement(IBAN; PaymentExportData."Recipient Bank Acc. No.")
                                {
                                    FieldValidate = yes;
                                    MaxOccurs = Once;
                                    MinOccurs = Once;
                                }
                            }
                        }
                        tableelement(genjnllineregrepcode; "Gen. Jnl. Line Reg. Rep. Code")
                        {
                            LinkFields = "Journal Template Name" = field("General Journal Template"), "Journal Batch Name" = field("General Journal Batch Name"), "Line No." = field("General Journal Line No.");
                            LinkTable = PaymentExportData;
                            MinOccurs = Zero;
                            XmlName = 'RgltryRptg';
                            textelement(Dtls)
                            {
                                fieldelement(Cd; GenJnlLineRegRepCode."Reg. Code")
                                {
                                }
                                fieldelement(Inf; GenJnlLineRegRepCode."Reg. Code Description")
                                {
                                }
                            }

                            trigger OnAfterGetRecord()
                            begin
                                if not (IsNorgeExport and PaymentExportData."Reg.Rep. Thresh.Amt Exceeded") then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(RmtInf)
                        {
                            MinOccurs = Zero;
                            textelement(Strd)
                            {
                                textelement(CdtrRefInf)
                                {
                                    MinOccurs = Zero;
                                    textelement(Tp)
                                    {
                                        MinOccurs = Zero;
                                        textelement(CdOrPrtry)
                                        {
                                            MinOccurs = Zero;
                                            textelement(rmtinfcd)
                                            {
                                                MinOccurs = Zero;
                                                XmlName = 'Cd';

                                                trigger OnBeforePassVariable()
                                                begin
                                                    RmtInfCd := 'SCOR';
                                                end;
                                            }
                                        }
                                    }
                                    textelement(rmtinfref)
                                    {
                                        MinOccurs = Zero;
                                        XmlName = 'Ref';

                                        trigger OnBeforePassVariable()
                                        begin
                                            if PaymentExportData.KID <> '' then
                                                rmtinfref := PaymentExportData.KID
                                            else
                                                if PaymentExportData."External Document No." <> '' then
                                                    rmtinfref := PaymentExportData."External Document No.";
                                        end;
                                    }
                                }

                                trigger OnAfterAssignVariable()
                                begin
                                    if (PaymentExportData.KID = '') and (PaymentExportData."External Document No." = '') then
                                        currXMLport.Skip();
                                end;
                            }
                            textelement(remittancetext1)
                            {
                                MinOccurs = Zero;
                                XmlName = 'Ustrd';

                                trigger OnBeforePassVariable()
                                begin
                                    if RemittanceText2 = '' then
                                        currXMLport.Skip();
                                end;
                            }
                            textelement(remittancetext2)
                            {
                                MinOccurs = Zero;
                                XmlName = 'Ustrd';

                                trigger OnBeforePassVariable()
                                begin
                                    if RemittanceText2 = '' then
                                        currXMLport.Skip();
                                end;
                            }

                            trigger OnBeforePassVariable()
                            var
                                IsHandled: Boolean;
                            begin
                                IsHandled := false;
                                OnBeforePassVariableRmtInf(PaymentExportData, RemittanceText1, IsHandled);
                                if IsHandled then
                                    exit;

                                RemittanceText1 := '';
                                RemittanceText2 := '';
                                TempPaymentExportRemittanceText.SetRange("Pmt. Export Data Entry No.", PaymentExportData."Entry No.");
                                if TempPaymentExportRemittanceText.FindSet() then begin
                                    RemittanceText1 := TempPaymentExportRemittanceText.Text;
                                    if TempPaymentExportRemittanceText.Next() = 0 then
                                        exit;
                                    RemittanceText2 := TempPaymentExportRemittanceText.Text;
                                    // there is not text combination like in W1.
                                end;
                            end;
                        }
                    }
                }

                trigger OnAfterGetRecord()
                begin
                    if not PaymentExportData.GetPreserveNonLatinCharacters() then
                        PaymentExportData.CompanyInformationConvertToLatin(CompanyInformation);
                end;
            }
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

    trigger OnPreXmlPort()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        SEPACTExportFile: Codeunit "SEPA CT-Export File";
    begin
        FeatureTelemetry.LogUptake('0000N1X', SEPACTExportFile.FeatureName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000N1Y', SEPACTExportFile.FeatureName(), 'XmlPort SEPA CT pain.001.001.03');
        InitData();
    end;

    var
        TempPaymentExportRemittanceText: Record "Payment Export Remittance Text" temporary;
        NoDataToExportErr: Label 'There is no data to export.', Comment = '%1=Field;%2=Value;%3=Value';
        IsNorgeExport: Boolean;

    local procedure InitData()
    var
        WaitingJournal: Record "Waiting Journal";
        GenJournalLine: Record "Gen. Journal Line";
        SEPACTFillExportBuffer: Codeunit "SEPA CT-Fill Export Buffer";
        DocumentTools: Codeunit DocumentTools;
        PaymentGroupNo: Integer;
    begin
        GenJournalLine.Copy("Gen. Journal Line");
        if GenJournalLine.FindFirst() then
            IsNorgeExport := DocumentTools.IsNorgeSEPACT(GenJournalLine);
        SEPACTFillExportBuffer.FillExportBuffer("Gen. Journal Line", PaymentExportData);
        PaymentExportData.GetRemittanceTexts(TempPaymentExportRemittanceText);

        NoOfTransfers := Format(PaymentExportData.Count);
        MessageID := PaymentExportData."Message ID";
        CreatedDateTime := Format(CurrentDateTime, 19, 9);
        PaymentExportData.CalcSums(Amount);
        ControlSum := Format(PaymentExportData.Amount, 0, 9);

        PaymentExportData.SetCurrentKey(
          "Sender Bank BIC", "Transfer Date", "SEPA Batch Booking",
          "SEPA Charge Bearer Text", Urgent);

        if not PaymentExportData.FindSet() then
            Error(NoDataToExportErr);

        InitPmtGroup(PaymentGroupNo);
        repeat
            if IsNewGroup() then begin
                PaymentExportDataGroup.Insert();
                InitPmtGroup(PaymentGroupNo);
            end;

            WaitingJournal.Reset();
            WaitingJournal.SetFilter("SEPA Msg. ID", PaymentExportData."Message ID");
            WaitingJournal.SetFilter("SEPA Payment Inf ID", PaymentExportData."Payment Information ID");
            WaitingJournal.SetFilter("SEPA End To End ID", PaymentExportData."End-to-End ID");
            WaitingJournal.SetFilter("SEPA Instr. ID", PaymentExportData."Document No.");
            if WaitingJournal.FindFirst() then
                WaitingJournal.ModifyAll("SEPA Payment Inf ID", PaymentExportDataGroup."Payment Information ID", true);

            PaymentExportDataGroup."Line No." += 1;
            PaymentExportDataGroup.Amount += PaymentExportData.Amount;
        until PaymentExportData.Next() = 0;
        PaymentExportDataGroup.Insert();
    end;

    local procedure IsNewGroup(): Boolean
    begin
        exit(
          (PaymentExportData."Sender Bank BIC" <> PaymentExportDataGroup."Sender Bank BIC") or
          (PaymentExportData.Urgent <> PaymentExportDataGroup.Urgent) or
          (PaymentExportData."Transfer Date" <> PaymentExportDataGroup."Transfer Date") or
          (PaymentExportData."SEPA Batch Booking" <> PaymentExportDataGroup."SEPA Batch Booking") or
          (PaymentExportData."SEPA Charge Bearer Text" <> PaymentExportDataGroup."SEPA Charge Bearer Text"));
    end;

    local procedure InitPmtGroup(var PaymentGroupNo: Integer)
    begin
        PaymentGroupNo += 1;
        PaymentExportDataGroup := PaymentExportData;
        PaymentExportDataGroup."Line No." := 0; // used for counting transactions within group
        PaymentExportDataGroup.Amount := 0; // used for summarizing transactions within group
        PaymentExportDataGroup."Entry No." := PaymentGroupNo;
        PaymentExportDataGroup."Payment Information ID" :=
          CopyStr(
            StrSubstNo('%1/%2', PaymentExportData."Message ID", PaymentGroupNo),
            1, MaxStrLen(PaymentExportDataGroup."Payment Information ID"));
    end;

#if not CLEAN27
    [Obsolete('The event is never raised.', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnSpecifyRemittanceTextSeparatorText(var SeparatorText: Text)
    begin
    end;
#endif
    [IntegrationEvent(false, false)]
    local procedure OnBeforePassVariableRmtInf(PaymentExportData: Record "Payment Export Data"; var RemittanceText: Text; var IsHandled: Boolean)
    begin
    end;
}
