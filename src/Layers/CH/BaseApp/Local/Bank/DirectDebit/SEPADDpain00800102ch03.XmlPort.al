// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#pragma warning disable AA0247
xmlport 11501 "SEPA DD pain.008.001.02.ch03"
{
    Caption = 'SEPA DD pain.008.001.02.ch03';
    DefaultNamespace = 'http://www.six-interbank-clearing.com/de/pain.008.001.02.ch.03.xsd';
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
                        textelement(Id)
                        {
                            textelement(OrgId)
                            {
                                textelement(Othr)
                                {
                                    textelement(rspid)
                                    {
                                        XmlName = 'Id';
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
                    textelement(PmtTpInf)
                    {
                        textelement(SvcLvl)
                        {
                            textelement(svclvlprtry)
                            {
                                XmlName = 'Prtry';
                            }
                        }
                        textelement(LclInstrm)
                        {
                            textelement(lcinstrmprtry)
                            {
                                XmlName = 'Prtry';
                            }
                        }
                        textelement(CtgyPurp)
                        {
                            textelement(ctgypurpcd)
                            {
                                XmlName = 'Cd';

                                trigger OnBeforePassVariable()
                                begin
                                    if CtgyPurpCd = '' then
                                        currXMLport.Skip();
                                end;
                            }
                            textelement(ctgypurpprtry)
                            {
                                XmlName = 'Prtry';

                                trigger OnBeforePassVariable()
                                begin
                                    if CtgyPurpPrtry = '' then
                                        currXMLport.Skip();
                                end;
                            }

                            trigger OnBeforePassVariable()
                            begin
                                if (CtgyPurpCd = '') and (CtgyPurpPrtry = '') then
                                    currXMLport.Skip();
                            end;
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
                        textelement(PstlAdr)
                        {
                            fieldelement(StrtNm; CompanyInformation.Address)
                            {
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
                        textelement(fininstnidch)
                        {
                            XmlName = 'FinInstnId';
                            textelement(crdtagtclrsysmmbid)
                            {
                                XmlName = 'ClrSysMmbId';
                                textelement(cdtrmmbid)
                                {
                                    XmlName = 'MmbId';
                                }
                            }
                        }
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
                        textelement(DbtrAgt)
                        {
                            textelement(dbtragtfininstnid)
                            {
                                XmlName = 'FinInstnId';
                                textelement(ClrSysMmbId)
                                {
                                    textelement(dbtrmmbid)
                                    {
                                        XmlName = 'MmbId';
                                    }
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
                            fieldelement(Ustrd; PaymentExportData."Message to Recipient 1")
                            {
                            }

                            trigger OnBeforePassVariable()
                            begin
                                if PaymentExportData."Message to Recipient 1" = '' then
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
        FeatureTelemetry.LogUsage('0000N22', SEPADDExportFile.FeatureName(), 'XmlPort (CH) SEPA DD pain.008.001.02.ch03');
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
        SchmeNmPrtry := 'CHDD';
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

        RSPID := PaymentExportData."Creditor No.";
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
        SvcLvlPrtry := 'CHDD';
        LcInstrmPrtry := 'DDCOR1';
        CdtrMmbId := '09000';
        DbtrMmbId := '09000';
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

