#pragma warning disable AA0247
report 12459 "Posted Bank Payment Order"
{
    Caption = 'Posted Bank Payment Order';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Check Ledger Entry"; "Check Ledger Entry")
        {
            DataItemTableView = sorting("Entry No.") where("Entry Status" = const(Posted));
            PrintOnlyIfDetail = false;
            RequestFilterFields = "Entry No.";

            trigger OnAfterGetRecord()
            begin
                if Amount >= 0 then
                    FieldError(Amount, AmountErr);

                case PaymentDocType of
                    PaymentDocType::"Payment Order":
                        begin
                            TitleDoc := PayNoteTxt;
                            OCUD := '0401060';
                        end;
                    PaymentDocType::"Collection Payment Order":
                        begin
                            TitleDoc := InkPayNoteTxt;
                            OCUD := '0401060';
                        end;
                    PaymentDocType::"Payment Requisition":
                        begin
                            TitleDoc := PayingRequestTxt;
                            OCUD := '0401061';
                        end;
                    else
                        CurrReport.Skip();
                end;

                if KBK <> '' then
                    CompStat := CopyStr(Format("Check Ledger Entry"."Taxpayer Status"), 1, 2);

                SdandRepManagement.PostedCheckAttributes("Check Ledger Entry",
                  PayerCode, PayerText, BenefeciaryCode, BenefeciaryText);

                DocAmount := Abs(Amount);

                case PaymentDocType of
                    PaymentDocType::"Payment Order":
                        begin
                            PayerVATRegNo := PayerCode[1];
                            PayerBIC := PayerCode[2];
                            PayerCurrentAccNo := PayerCode[3];
                            PayerGLAccNo := PayerCode[4];

                            PayerName := PayerText[1];
                            PayerName2 := PayerText[2];
                            PayerBank := PayerText[3];
                            PayerBank2 := PayerText[4] + ' ' + PayerText[5];
                            PayerBank2 := DelChr(PayerBank2, '<>', ' ');

                            PayerBankCity := PayerText[5];
                            PayerBranch := PayerText[6];
                            CompanyInf.Get();
                            PayerKPP := '';
                            PayerKPP := CompanyInf."KPP Code";
                            if Vendor.Get("Bal. Account No.") then begin
                                BeneficiaryKPP := Vendor."KPP Code";
                                if Vendor."Control Tax Organ" <> '' then
                                    ContrTaxOrgan := '(' + Vendor."Control Tax Organ" + ')';
                            end;

                            BeneficiaryVATRegNo := BenefeciaryCode[1];
                            BeneficiaryBIC := BenefeciaryCode[2];
                            BeneficiarySettlAccNo := BenefeciaryCode[3];
                            BeneficiaryGLNo := BenefeciaryCode[4];

                            BeneficiaryName := BenefeciaryText[1];
                            BeneficiaryName2 := BenefeciaryText[2];
                            BeneficiaryBank := BenefeciaryText[3];
                            BeneficiaryBank2 := BenefeciaryText[4] + ' ' + BenefeciaryText[5];
                            BeneficiaryBank2 := DelChr(BeneficiaryBank2, '<>', ' ');
                            BeneficiaryBankCity := BenefeciaryText[5];
                            BeneficiaryBranch := BenefeciaryText[6];
                        end;
                    else
                        if (PaymentDocType = PaymentDocType::"Collection Payment Order") or
                           (PaymentDocType = PaymentDocType::"Payment Requisition")
                        then begin
                            PayerVATRegNo := BenefeciaryCode[1];
                            PayerBIC := BenefeciaryCode[2];
                            PayerCurrentAccNo := BenefeciaryCode[3];
                            PayerGLAccNo := BenefeciaryCode[4];

                            PayerName := BenefeciaryText[1];
                            PayerName2 := BenefeciaryText[2];
                            PayerBank := BenefeciaryText[3];
                            PayerBank2 := BenefeciaryText[4] + ' ' + BenefeciaryText[5];
                            PayerBank2 := DelChr(PayerBank2, '<>', ' ');

                            PayerKPP := '';
                            PayerBankCity := BenefeciaryText[5];
                            PayerBranch := BenefeciaryText[6];

                            BeneficiaryVATRegNo := PayerCode[1];
                            BeneficiaryBIC := PayerCode[2];
                            BeneficiarySettlAccNo := PayerCode[3];
                            BeneficiaryGLNo := PayerCode[4];

                            BeneficiaryName := PayerText[1];
                            BeneficiaryName2 := PayerText[2];
                            BeneficiaryBank := PayerText[3];
                            BeneficiaryBank2 := PayerText[4] + ' ' + PayerText[5];
                            BeneficiaryBank2 := DelChr(BeneficiaryBank2, '<>', ' ');

                            BeneficiaryBankCity := PayerText[5];
                            BeneficiaryBranch := PayerText[6];
                        end;
                end;

                WrittenAmount := LocMgt.Amount2Text(' ', Abs(DocAmount));

                "Document No." := LocMgt.DigitalPartCode("Document No.");

                if PaymentDocType = PaymentDocType::"Payment Requisition" then
                    BankMark := ReceiverBankMarkTxt
                else
                    BankMark := BankMarkTxt;
            end;

            trigger OnPostDataItem()
            var
                LineValue: array[28] of Text;
            begin
                BankPaymentOrderHelper.FillHeader(OCUD);

                case PaymentDocType of
                    PaymentDocType::"Payment Order", PaymentDocType::"Collection Payment Order":
                        BankPaymentOrderHelper.FillTitle(
                          OCUD, StrSubstNo(TitleDoc, "Document No."), '', "Check Date", Format("Payment Method"), CompStat);
                    PaymentDocType::"Payment Requisition":
                        BankPaymentOrderHelper.FillRequestTitle(
                          OCUD, StrSubstNo(TitleDoc, "Document No."), '', "Check Date", Format("Payment Method"), CompStat);
                    else
                        CurrReport.Break();
                end;

                TransferLineValues(LineValue, "Check Ledger Entry");
                BankPaymentOrderHelper.FillBody(LineValue);
                if PaymentDocType = PaymentDocType::"Payment Requisition" then
                    BankPaymentOrderHelper.FillReqFooter()
                else
                    BankPaymentOrderHelper.FillFooter(BankMark, '');

                case PaymentDocType of
                    PaymentDocType::"Collection Payment Order", PaymentDocType::"Payment Requisition":
                        BankPaymentOrderHelper.FillMarks();
                end;
            end;

            trigger OnPreDataItem()
            begin
                BankPaymentOrderHelper.InitReportTemplate();
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(PaymentDocType; PaymentDocType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payment Document Type';
                        OptionCaption = 'Payment Order,Collection Payment Order,Payment Requisition';
                        ToolTip = 'Specifies if the related document is for a payment or a refund.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        if FileName <> '' then
            BankPaymentOrderHelper.ExportDataFile(FileName)
        else
            BankPaymentOrderHelper.ExportData();
    end;

    var
        BankMarkTxt: Label 'Bank marks', Comment = 'Must be translated: ÄÔ¼ÑÔ¬¿ íá¡¬á';
        Vendor: Record Vendor;
        CompanyInf: Record "Company Information";
        LocMgt: Codeunit "Localisation Management";
        SdandRepManagement: Codeunit "Local Report Management";
        BankPaymentOrderHelper: Codeunit "Bank Payment Order Helper";
        DocAmount: Decimal;
        PaymentDocType: Option "Payment Order","Collection Payment Order","Payment Requisition";
        PayerCode: array[4] of Code[20];
        PayerVATRegNo: Code[20];
        PayerGLAccNo: Code[20];
        PayerBIC: Code[20];
        PayerCurrentAccNo: Code[20];
        BenefeciaryCode: array[4] of Code[20];
        BeneficiaryVATRegNo: Code[20];
        BeneficiaryGLNo: Code[20];
        BeneficiaryBIC: Code[20];
        BeneficiarySettlAccNo: Code[20];
        OCUD: Code[10];
        TitleDoc: Text;
        WrittenAmount: Text;
        PayerName: Text;
        PayerName2: Text;
        PayerBank: Text;
        PayerBank2: Text;
        PayerText: array[6] of Text;
        BeneficiaryName: Text;
        BeneficiaryName2: Text;
        BeneficiaryBank: Text;
        BeneficiaryBank2: Text;
        BenefeciaryText: array[6] of Text;
        BankMark: Text;
        AmountErr: Label 'Cannot be less than 0';
        ReceiverBankMarkTxt: Label 'Receiver bank marks', Comment = 'Must be translated: ÄÔ¼ÑÔ¬¿ íá¡¬á »«½ÒþáÔÑ½´';
        PayerBankCity: Text;
        PayerKPP: Code[30];
        PayerBranch: Text;
        BeneficiaryBranch: Text;
        BeneficiaryBankCity: Text;
        BeneficiaryKPP: Text;
        CompStat: Text;
        ContrTaxOrgan: Text;
#pragma warning disable AA0470
        PayNoteTxt: Label 'PAYMENT ORDER # %1', Comment = 'Must be translated: Å½áÔÑª¡«Ñ »«ÓÒþÑ¡¿Ñ';
#pragma warning restore AA0470
#pragma warning disable AA0470
        InkPayNoteTxt: Label 'COLLECTION\PAYMENT ORDER # %1', Comment = 'Must be translated: ê¡¬áßß«ó«Ñ\»½áÔÑª¡«Ñ »«ÓÒþÑ¡¿Ñ';
#pragma warning restore AA0470
#pragma warning disable AA0470
        PayingRequestTxt: Label 'PAYMENT REQUEST # %1', Comment = 'Must be translated: Å½áÔÑª¡«Ñ ÔÓÑí«óá¡¿Ñ';
#pragma warning restore AA0470
        FileName: Text;

    [Scope('OnPrem')]
    procedure FormatAmount(Amount: Decimal): Text[30]
    begin
        if Round(Amount, 1) = Amount then
            exit(Format(Amount, 0, 1) + '-00');

        if Round(Amount, 0.1) = Amount then
            exit(ConvertStr(Format(Amount, 0, 1) + '0', '.,', '--'));

        exit(ConvertStr(Format(Amount, 0, 1), '.,', '--'));
    end;

    local procedure TransferLineValues(var LineValue: array[28] of Text; CheckEntry: Record "Check Ledger Entry")
    begin
        LineValue[1] := WrittenAmount;
        LineValue[2] := PayerVATRegNo;
        LineValue[3] := PayerKPP;
        LineValue[4] := PayerName + ' ' + PayerName2 + '\' + PayerBranch;
        LineValue[5] := PayerBank + ' ' + PayerBank2 + '\' + PayerBankCity;
        LineValue[6] := BeneficiaryBank + ' ' + BeneficiaryBank2 + '\' + BeneficiaryBankCity;
        LineValue[7] := BeneficiaryVATRegNo;
        LineValue[8] := BeneficiaryKPP;
        LineValue[9] := BeneficiaryName + ' ' + BeneficiaryName2 + '\' + BeneficiaryBranch;
        LineValue[10] := ContrTaxOrgan;
        LineValue[11] := FormatAmount(DocAmount);
        LineValue[12] := PayerGLAccNo;
        LineValue[13] := PayerBIC;
        LineValue[14] := PayerCurrentAccNo;
        LineValue[15] := BeneficiaryBIC;
        LineValue[16] := BeneficiarySettlAccNo;
        LineValue[17] := BeneficiaryGLNo;
        LineValue[18] := CheckEntry."Payment Type";
        LineValue[19] := CheckEntry."Payment Assignment";
        LineValue[20] := CheckEntry."Payment Code";
        LineValue[21] := LocMgt.Date2Text(CheckEntry."Payment Before Date");
        LineValue[22] := CheckEntry."Payment Subsequence";
        LineValue[23] := CheckEntry.KBK;
        LineValue[24] := CheckEntry.OKATO;
        LineValue[25] := CheckEntry."Tax Period";
        LineValue[26] := CheckEntry."Reason Document No.";
        LineValue[27] := LocMgt.Date2Text(CheckEntry."Reason Document Date");
        LineValue[28] := CheckEntry."Tax Payment Type";
    end;

    [Scope('OnPrem')]
    procedure SetFileNameSilent(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;
}

