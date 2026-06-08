// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.DirectDebit;

using Microsoft.Bank.Payment;
using Microsoft.Foundation.Company;
using System.Telemetry;

/// <summary>
/// XMLPort for exporting SEPA direct debits in pain.008.001.02 format.
/// Generates XML files compliant with SEPA Customer Direct Debit Initiation standard
/// for submission to banks for automated payment collection processing.
/// </summary>
xmlport 1010 "SEPA DD pain.008.001.02"
{
    Caption = 'SEPA DD pain.008.001.02';
    DefaultNamespace = 'urn:iso:std:iso:20022:tech:xsd:pain.008.001.02';
    Direction = Export;
    Encoding = UTF8;
    FormatEvaluate = Xml;
    UseDefaultNamespace = true;

    schema
    {
        tableelement("Direct Debit Collection Entry"; "Direct Debit Collection Entry")
        {
            XmlName = 'Document';
            UseTemporary = true;
            tableelement(companyinformation; "Company Information")
            {
                XmlName = 'CstmrDrctDbtInitn';
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
                        textelement(PstlAdr)
                        {
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
                        textelement(Id)
                        {
                            textelement(OrgId)
                            {
                                textelement(Othr)
                                {
                                    textelement(OrganizationID)
                                    {
                                        XmlName = 'Id';

                                        trigger OnBeforePassVariable()
                                        begin
                                            OrganizationID := paymentexportdatagroup.GetOrganizationID();
                                        end;
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
                    textelement(paymentmethoddd)
                    {
                        XmlName = 'PmtMtd';
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
                        textelement(SvcLvl)
                        {
                            textelement(servicelevelcodesepa)
                            {
                                XmlName = 'Cd';
                            }
                        }
                        textelement(LclInstrm)
                        {
                            fieldelement(Cd; PaymentExportDataGroup."SEPA Partner Type Text")
                            {
                            }
                        }
                        fieldelement(SeqTp; PaymentExportDataGroup."SEPA Direct Debit Seq. Text")
                        {
                        }
                    }
                    fieldelement(ReqdColltnDt; PaymentExportDataGroup."Transfer Date")
                    {
                    }
                    textelement(Cdtr)
                    {
                        textelement(companyinformationname)
                        {
                            XmlName = 'Nm';
                        }
                        textelement(cdrid)
                        {
                            XmlName = 'Id';
                            textelement(cdrorgid)
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
                    textelement(CdtrAcct)
                    {
                        textelement(cdtracctid)
                        {
                            XmlName = 'Id';
                            fieldelement(IBAN; PaymentExportDataGroup."Sender Bank Account No.")
                            {
                            }
                        }
                    }
                    textelement(CdtrAgt)
                    {
                        textelement(FinInstnId)
                        {
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
                    textelement(CdtrSchmeId)
                    {
                        textelement(cdtrschmeidid)
                        {
                            XmlName = 'Id';
                            textelement(PrvtId)
                            {
                                textelement(cdtrschmeidothr)
                                {
                                    XmlName = 'Othr';
                                    fieldelement(Id; PaymentExportDataGroup."Creditor No.")
                                    {
                                    }
                                    textelement(SchmeNm)
                                    {
                                        textelement(schmenmprtry)
                                        {
                                            XmlName = 'Prtry';
                                        }
                                    }
                                }
                            }
                        }
                    }
                    tableelement(paymentexportdata; "Payment Export Data")
                    {
                        LinkFields = "Sender Bank BIC" = field("Sender Bank BIC"), "SEPA Instruction Priority Text" = field("SEPA Instruction Priority Text"), "Transfer Date" = field("Transfer Date"), "SEPA Direct Debit Seq. Text" = field("SEPA Direct Debit Seq. Text"), "SEPA Partner Type Text" = field("SEPA Partner Type Text"), "SEPA Batch Booking" = field("SEPA Batch Booking"), "SEPA Charge Bearer Text" = field("SEPA Charge Bearer Text");
                        LinkTable = PaymentExportDataGroup;
                        XmlName = 'DrctDbtTxInf';
                        UseTemporary = true;
                        textelement(PmtId)
                        {
                            fieldelement(InstrId; PaymentExportData."Payment Information ID")
                            {
                            }
                            fieldelement(EndToEndId; PaymentExportData."End-to-End ID")
                            {
                            }
                        }
                        fieldelement(InstdAmt; PaymentExportData.Amount)
                        {
                            fieldattribute(Ccy; PaymentExportData."Currency Code")
                            {
                            }
                        }
                        textelement(DrctDbtTx)
                        {
                            textelement(MndtRltdInf)
                            {
                                fieldelement(MndtId; PaymentExportData."SEPA Direct Debit Mandate ID")
                                {
                                }
                                fieldelement(DtOfSgntr; PaymentExportData."SEPA DD Mandate Signed Date")
                                {
                                }
                            }
                        }
                        textelement(DbtrAgt)
                        {
                            textelement(dbtragtfininstnid)
                            {
                                XmlName = 'FinInstnId';
                                fieldelement(BIC; PaymentExportData."Recipient Bank BIC")
                                {
                                }
                            }

                            trigger OnBeforePassVariable()
                            begin
                                if PaymentExportData."Recipient Bank BIC" = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(Dbtr)
                        {
                            fieldelement(Nm; PaymentExportData."Recipient Name")
                            {
                            }
                            textelement(dbtrpstladr)
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
                            }
                            textelement(dbtrid)
                            {
                                XmlName = 'Id';
                                textelement(dbtrorgid)
                                {
                                    XmlName = 'OrgId';
                                    fieldelement(BICOrBEI; PaymentExportData."Recipient Bank BIC")
                                    {
                                    }
                                }

                                trigger OnBeforePassVariable()
                                begin
                                    if PaymentExportData."Recipient Bank BIC" = '' then
                                        currXMLport.Skip();
                                end;
                            }
                        }
                        textelement(DbtrAcct)
                        {
                            textelement(dbtracctid)
                            {
                                XmlName = 'Id';
                                fieldelement(IBAN; PaymentExportData."Recipient Bank Acc. No.")
                                {
                                }
                            }
                        }
                        textelement(RmtInf)
                        {
                            textelement(remittancetext)
                            {
                                XmlName = 'Ustrd';

                                trigger OnBeforePassVariable()
                                begin
                                    if PaymentExportData."Message to Recipient 2" <> '' then
                                        RemittanceText := PaymentExportData."Message to Recipient 2"
                                    else
                                        RemittanceText := PaymentExportData."Message to Recipient 1" + ' ;' + PaymentExportData."Document No.";
                                end;
                            }

                            trigger OnBeforePassVariable()
                            begin
                                if (PaymentExportData."Message to Recipient 1" = '') and
                                   (PaymentExportData."Message to Recipient 2" = '') and
                                   (PaymentExportData."Document No." = '') then
                                    currXMLport.Skip();
                            end;
                        }
                    }
                }

                trigger OnAfterGetRecord()
                begin
                    if not PaymentExportData.GetPreserveNonLatinCharacters() then
                        PaymentExportData.CompanyInformationConvertToLatin(CompanyInformation);
                    CompanyInformationName := CompanyInformation.Name;
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
        SEPADDExportFile: Codeunit "SEPA DD-Export File";
    begin
        FeatureTelemetry.LogUptake('0000N21', SEPADDExportFile.FeatureName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000N22', SEPADDExportFile.FeatureName(), 'XmlPort SEPA DD pain.008.001.02');
        InitData();
    end;

    var
        NoDataToExportErr: Label 'There is no data to export. Make sure the %1 field is not set to %2 or %3.', Comment = '%1=Field;%2=Value;%3=Value';

    local procedure InitData()
    var
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        DirectDebitCollection: Record "Direct Debit Collection";
        SEPADDFillExportBuffer: Codeunit "SEPA DD-Fill Export Buffer";
        PaymentGroupNo: Integer;
    begin
        SEPADDFillExportBuffer.FillExportBuffer("Direct Debit Collection Entry", PaymentExportData);
        PaymentMethodDD := 'DD';
        ServiceLevelCodeSEPA := 'SEPA';
        SchmeNmPrtry := 'SEPA';
        NoOfTransfers := Format(PaymentExportData.Count);
        MessageID := PaymentExportData."Message ID";
        CreatedDateTime := Format(CurrentDateTime, 19, 9);
        PaymentExportData.CalcSums(Amount);
        ControlSum := Format(PaymentExportData.Amount, 0, '<Precision,2:2><Standard Format,9>');

        PaymentExportData.SetCurrentKey(
          "Sender Bank BIC", "SEPA Instruction Priority Text", "Transfer Date",
          "SEPA Direct Debit Seq. Text", "SEPA Partner Type Text", "SEPA Batch Booking", "SEPA Charge Bearer Text");

        if not PaymentExportData.FindSet() then
            Error(NoDataToExportErr, DirectDebitCollectionEntry.FieldCaption(Status),
              DirectDebitCollectionEntry.Status::Rejected, DirectDebitCollection.Status::Canceled);

        InitPmtGroup();
        repeat
            if IsNewGroup() then begin
                InsertPmtGroup(PaymentGroupNo);
                InitPmtGroup();
            end;
            PaymentExportDataGroup."Line No." += 1;
            PaymentExportDataGroup.Amount += PaymentExportData.Amount;
        until PaymentExportData.Next() = 0;
        InsertPmtGroup(PaymentGroupNo);
    end;

    local procedure IsNewGroup(): Boolean
    begin
        exit(
          (PaymentExportData."Sender Bank BIC" <> PaymentExportDataGroup."Sender Bank BIC") or
          (PaymentExportData."SEPA Instruction Priority Text" <> PaymentExportDataGroup."SEPA Instruction Priority Text") or
          (PaymentExportData."Transfer Date" <> PaymentExportDataGroup."Transfer Date") or
          (PaymentExportData."SEPA Direct Debit Seq. Text" <> PaymentExportDataGroup."SEPA Direct Debit Seq. Text") or
          (PaymentExportData."SEPA Partner Type Text" <> PaymentExportDataGroup."SEPA Partner Type Text") or
          (PaymentExportData."SEPA Batch Booking" <> PaymentExportDataGroup."SEPA Batch Booking") or
          (PaymentExportData."SEPA Charge Bearer Text" <> PaymentExportDataGroup."SEPA Charge Bearer Text"));
    end;

    local procedure InitPmtGroup()
    begin
        PaymentExportDataGroup := PaymentExportData;
        PaymentExportDataGroup."Line No." := 0; // used for counting transactions within group
        PaymentExportDataGroup.Amount := 0; // used for summarizing transactions within group
    end;

    local procedure InsertPmtGroup(var PaymentGroupNo: Integer)
    begin
        PaymentGroupNo += 1;
        PaymentExportDataGroup."Entry No." := PaymentGroupNo;
        PaymentExportDataGroup."Payment Information ID" :=
          CopyStr(
            StrSubstNo('%1/%2', PaymentExportData."Message ID", PaymentGroupNo),
            1, MaxStrLen(PaymentExportDataGroup."Payment Information ID"));
        PaymentExportDataGroup.Insert();
    end;
}

