// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#pragma warning disable AA0247
xmlport 12100 "CBI Payment Request.00.04.00"
{
    Caption = 'CBI Payment Request.00.04.00';
    DefaultNamespace = 'urn:CBI:xsd:CBIPaymentRequest.00.04.00';
    Direction = Export;
    Encoding = UTF8;
    FormatEvaluate = Xml;
    UseDefaultNamespace = true;

    schema
    {
        tableelement("Gen. Journal Line"; "Gen. Journal Line")
        {
            XmlName = 'CBIPaymentRequest';
            textattribute(xmlnamespace)
            {
                XmlName = 'xmlns';
            }
            tableelement(companyinformation; "Company Information")
            {
                XmlName = 'GrpHdr';
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
                    textelement(initgptyid)
                    {
                        XmlName = 'Id';
                        textelement(initgptyorgid)
                        {
                            XmlName = 'OrgId';
                            textelement(initgptyothrinitgpty)
                            {
                                XmlName = 'Othr';
                                textelement(initgptycuc)
                                {
                                    XmlName = 'Id';

                                    trigger OnBeforePassVariable()
                                    var
                                        BankAccount: Record "Bank Account";
                                    begin
                                        BankAccount.Get(PaymentExportDataGroup."Sender Bank Account Code");
                                        InitgPtyCUC := BankAccount.CUC;
                                    end;
                                }
                                textelement(initgptyissr)
                                {
                                    MinOccurs = Zero;
                                    XmlName = 'Issr';

                                    trigger OnBeforePassVariable()
                                    begin
                                        InitgPtyIssr := 'CBI';
                                    end;
                                }
                            }
                        }
                    }
                }

                trigger OnAfterGetRecord()
                begin
                    if not PaymentExportData.GetPreserveNonLatinCharacters() then
                        PaymentExportData.CompanyInformationConvertToLatin(CompanyInformation);

                    ThisCompanyName := CompanyInformation.Name;
                    ThisCompanyAddress := CompanyInformation.Address;
                    ThisCompanyPostCode := CompanyInformation."Post Code";
                    ThisCompanyCity := CompanyInformation.City;
                    ThisCompanyCountry := CompanyInformation."Country/Region Code";
                    ThisCompanyVATRegNo := CompanyInformation."VAT Registration No.";
                end;
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
                textelement(batchbooking)
                {
                    XmlName = 'BtchBookg';

                    trigger OnBeforePassVariable()
                    begin
                        if PaymentExportDataGroup."SEPA Batch Booking" then
                            BatchBooking := 'true'
                        else
                            BatchBooking := 'false';
                    end;
                }
                textelement(PmtTpInf)
                {
                    fieldelement(InstrPrty; PaymentExportDataGroup."SEPA Instruction Priority Text")
                    {
                    }
                    textelement(SvcLvl)
                    {
                        textelement(cd)
                        {
                            XmlName = 'Cd';

                            trigger OnBeforePassVariable()
                            begin
                                Cd := 'SEPA';
                            end;
                        }
                    }
                }
                fieldelement(ReqdExctnDt; PaymentExportDataGroup."Transfer Date")
                {
                }
                textelement(Dbtr)
                {
                    textelement(thiscompanyname)
                    {
                        XmlName = 'Nm';
                    }
                    textelement(dbtrpstladr)
                    {
                        XmlName = 'PstlAdr';
                        textelement(thiscompanyaddress)
                        {
                            XmlName = 'StrtNm';

                            trigger OnBeforePassVariable()
                            begin
                                if CompanyInformation.Address = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(thiscompanypostcode)
                        {
                            XmlName = 'PstCd';

                            trigger OnBeforePassVariable()
                            begin
                                if CompanyInformation."Post Code" = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(thiscompanycity)
                        {
                            XmlName = 'TwnNm';

                            trigger OnBeforePassVariable()
                            begin
                                if CompanyInformation.City = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(thiscompanycountry)
                        {
                            XmlName = 'Ctry';

                            trigger OnBeforePassVariable()
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
                            textelement(Othr)
                            {
                                textelement(thiscompanyvatregno)
                                {
                                    XmlName = 'Id';
                                }
                                textelement(dbtrissr)
                                {
                                    XmlName = 'Issr';

                                    trigger OnBeforePassVariable()
                                    begin
                                        DbtrIssr := 'ADE';
                                    end;
                                }
                            }
                        }
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
                        textelement(ClrSysMmbId)
                        {
                            textelement(mmbid)
                            {
                                XmlName = 'MmbId';

                                trigger OnBeforePassVariable()
                                var
                                    BankAccount: Record "Bank Account";
                                begin
                                    BankAccount.Get(PaymentExportDataGroup."Sender Bank Account Code");
                                    MmbId := BankAccount.ABI;
                                end;
                            }
                        }
                    }
                }
                fieldelement(ChrgBr; PaymentExportDataGroup."SEPA Charge Bearer Text")
                {
                }
                tableelement(paymentexportdata; "Payment Export Data")
                {
                    LinkFields = "Sender Bank BIC" = field("Sender Bank BIC"), "SEPA Instruction Priority Text" = field("SEPA Instruction Priority Text"), "Transfer Date" = field("Transfer Date"), "SEPA Batch Booking" = field("SEPA Batch Booking"), "SEPA Charge Bearer Text" = field("SEPA Charge Bearer Text");
                    LinkTable = PaymentExportDataGroup;
                    XmlName = 'CdtTrfTxInf';
                    UseTemporary = true;
                    textelement(PmtId)
                    {
                        fieldelement(InstrId; PaymentExportData."End-to-End ID")
                        {
                        }
                        fieldelement(EndToEndId; PaymentExportData."End-to-End ID")
                        {
                        }
                    }
                    textelement("<pmttpinf>")
                    {
                        XmlName = 'PmtTpInf';
                        textelement(CtgyPurp)
                        {
                            textelement(cd2)
                            {
                                XmlName = 'Cd';

                                trigger OnBeforePassVariable()
                                begin
                                    Cd2 := 'SUPP';
                                end;
                            }
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
                    textelement(RmtInf)
                    {
                        MinOccurs = Zero;
                        textelement(remittancetext1)
                        {
                            MinOccurs = Zero;
                            XmlName = 'Ustrd';

                            trigger OnBeforePassVariable()
                            begin
                                if RemittanceText1 = '' then
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
                        begin
                            RemittanceText1 := '';
                            RemittanceText2 := '';
                            TempPaymentExportRemittanceTxt.SetRange("Pmt. Export Data Entry No.", PaymentExportData."Entry No.");
                            if TempPaymentExportRemittanceTxt.FindSet() then begin
                                RemittanceText1 := TempPaymentExportRemittanceTxt.Text;
                                if TempPaymentExportRemittanceTxt.Next() <> 0 then
                                    RemittanceText2 := TempPaymentExportRemittanceTxt.Text;
                            end;
                        end;
                    }
                }
            }

            trigger OnAfterGetRecord()
            begin
                if "Gen. Journal Line"."Line No." <> 0 then
                    if not TempGroupedGenJnlLine.Get("Gen. Journal Line"."Journal Template Name", "Gen. Journal Line"."Journal Batch Name",
                         "Gen. Journal Line"."Line No.")
                    then
                        currXMLport.Skip();
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

    trigger OnInitXmlPort()
    begin
        XMLNamespace := 'urn:CBI:xsd:CBIPaymentRequest.00.04.00';
    end;

    trigger OnPostXmlPort()
    begin
        DeleteGenJnlLine();
    end;

    trigger OnPreXmlPort()
    begin
        InitData();
        InsertGenJnlLine();
    end;

    var
        TempPaymentExportRemittanceTxt: Record "Payment Export Remittance Text" temporary;
        NoDataToExportErr: Label 'There is no data to export.';
        TempGroupedGenJnlLine: Record "Gen. Journal Line" temporary;

    local procedure InitData()
    var
        SEPACTFillExportBuffer: Codeunit "SEPA CT-Fill Export Buffer";
        PaymentGroupNo: Integer;
        SEPAFormat: Option pain,CBI;
    begin
        SEPACTFillExportBuffer.FillExportBuffer("Gen. Journal Line", PaymentExportData, SEPAFormat::CBI);
        PaymentExportData.GetRemittanceTexts(TempPaymentExportRemittanceTxt);

        NoOfTransfers := Format(PaymentExportData.Count);
        MessageID := PaymentExportData."Message ID";
        CreatedDateTime := Format(CurrentDateTime, 0, 9);
        PaymentExportData.CalcSums(Amount);
        ControlSum := Format(PaymentExportData.Amount, 0, 9);

        PaymentExportData.SetCurrentKey(
          "Sender Bank BIC", "SEPA Instruction Priority Text", "Transfer Date",
          "SEPA Batch Booking", "SEPA Charge Bearer Text");

        if not PaymentExportData.FindSet() then
            Error(NoDataToExportErr);

        InitPmtGroup();
        InsertTempGroupedGenJnlLine(PaymentExportData);
        repeat
            if IsNewGroup() then begin
                InsertPmtGroup(PaymentGroupNo);
                InitPmtGroup();
                InsertTempGroupedGenJnlLine(PaymentExportData);
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

    local procedure InsertGenJnlLine()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        DeleteGenJnlLine();
        Clear(GenJnlLine);
        GenJnlLine."Document No." := "Gen. Journal Line".GetFilter("Document No.");
        GenJnlLine.Insert();
    end;

    local procedure DeleteGenJnlLine()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.SetRange("Journal Template Name", '');
        GenJnlLine.SetRange("Journal Batch Name", '');
        GenJnlLine.SetRange("Line No.", 0);
        GenJnlLine.DeleteAll();
    end;

    local procedure InsertTempGroupedGenJnlLine(var PaymentExportData: Record "Payment Export Data")
    begin
        TempGroupedGenJnlLine."Journal Template Name" := PaymentExportData."General Journal Template";
        TempGroupedGenJnlLine."Journal Batch Name" := PaymentExportData."General Journal Batch Name";
        TempGroupedGenJnlLine."Line No." := PaymentExportData."General Journal Line No.";
        if not TempGroupedGenJnlLine.Find() then
            TempGroupedGenJnlLine.Insert();
    end;
}

