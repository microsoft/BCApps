// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;
using System.Telemetry;
using System.Utilities;

report 3010544 "EZAG Payment Order"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Bank/Payment/EZAGPaymentOrder.rdlc';
    Caption = 'EZAG Payment Order';

    dataset
    {
        dataitem("Journal Line"; "Gen. Journal Line")
        {
            DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", "Posting Date", Clearing, "Debit Bank");

            trigger OnAfterGetRecord()
            begin
                DebitDate := "Posting Date";
                xISO := DtaMgt.GetIsoCurrencyCode("Currency Code");

                // summary pay flag for record?
                if SummaryPerVendor then begin
                    VendBank.Get("Account No.", "Recipient Bank Account");
                    NextGlLine.Copy("Journal Line");
                    if (NextGlLine.Next() = 0) or
                       (NextGlLine."Account No." <> "Account No.") or
                       (NextGlLine."Recipient Bank Account" <> "Recipient Bank Account") or
                       (NextGlLine."Currency Code" <> "Currency Code") or
                       (VendBank."Payment Form" in [VendBank."Payment Form"::ESR, VendBank."Payment Form"::"ESR+"])
                    then
                        SumPayLine := false
                    else
                        SumPayLine := true;
                end;

                i := 1;
                while (iCurrCode[i] <> xISO) and (i < 16) and (iCurrCode[i] <> '') do
                    i := i + 1;

                if i = 16 then
                    Error(Text001);

                iCurrCode[i] := xISO;
                iAmt[i] := iAmt[i] + Amount;  // amount (FCY)
                iAmtTxt[i] := ConvertStr(Format(iAmt[i], 14, 1), ' ', '0'); // generate leading 0
                if not SumPayLine then begin
                    iNo[i] := iNo[i] + 1;  // no of records
                    iNoTxt[i] := ConvertStr(Format(iNo[i], 6, 1), ' ', '0'); // generate leading 0
                end;
            end;

            trigger OnPreDataItem()
            begin
                SetRange("Account Type", "Account Type"::Vendor);
                SetRange("Document Type", "Document Type"::Payment);
            end;
        }
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number);
            column(DtaSetupEZAGPostLogo; DtaSetup."EZAG Post Logo")
            {
            }
            column(DtaSetupEZAGBarCode; DtaSetup."EZAG Bar Code")
            {
            }
            column(Adr1; Adr[1])
            {
            }
            column(Adr2; Adr[2])
            {
            }
            column(Adr3; Adr[3])
            {
            }
            column(Adr4; Adr[4])
            {
            }
            column(Adr5; Adr[5])
            {
            }
            column(DtaSetupEZAGMediaID; DtaSetup."EZAG Media ID")
            {
            }
            column(DtaSetupEZAGDebitAccountNo; DtaSetup."EZAG Debit Account No.")
            {
            }
            column(TODAY; Format(Today))
            {
            }
            column(DebitDate; Format(DebitDate))
            {
            }
            column(DtaSetupLastEZAGOrderNo; DtaSetup."Last EZAG Order No.")
            {
            }
            column(DtaSetupEZAGChargesAccountNo; DtaSetup."EZAG Charges Account No.")
            {
            }
            column(MsgLine4; MsgLine[4])
            {
            }
            column(MsgLine3; MsgLine[3])
            {
            }
            column(MsgLine2; MsgLine[2])
            {
            }
            column(iNoTxt1; iNoTxt[1])
            {
            }
            column(iAmtTxt1; iAmtTxt[1])
            {
            }
            column(iCurrCode1; iCurrCode[1])
            {
            }
            column(MsgLine1; MsgLine[1])
            {
            }
            column(iAmtTxt2; iAmtTxt[2])
            {
            }
            column(iNoTxt2; iNoTxt[2])
            {
            }
            column(iCurrCode2; iCurrCode[2])
            {
            }
            column(iAmtTxt3; iAmtTxt[3])
            {
            }
            column(iNoTxt3; iNoTxt[3])
            {
            }
            column(iCurrCode3; iCurrCode[3])
            {
            }
            column(iAmtTxt4; iAmtTxt[4])
            {
            }
            column(iNoTxt4; iNoTxt[4])
            {
            }
            column(iCurrCode4; iCurrCode[4])
            {
            }
            column(iCurrCode5; iCurrCode[5])
            {
            }
            column(iAmtTxt5; iAmtTxt[5])
            {
            }
            column(iNoTxt5; iNoTxt[5])
            {
            }
            column(iAmtTxt6; iAmtTxt[6])
            {
            }
            column(iNoTxt6; iNoTxt[6])
            {
            }
            column(iCurrCode6; iCurrCode[6])
            {
            }
            column(iAmtTxt7; iAmtTxt[7])
            {
            }
            column(iNoTxt7; iNoTxt[7])
            {
            }
            column(iCurrCode7; iCurrCode[7])
            {
            }
            column(iAmtTxt8; iAmtTxt[8])
            {
            }
            column(iNoTxt8; iNoTxt[8])
            {
            }
            column(iCurrCode8; iCurrCode[8])
            {
            }
            column(iAmtTxt9; iAmtTxt[9])
            {
            }
            column(iNoTxt9; iNoTxt[9])
            {
            }
            column(iCurrCode9; iCurrCode[9])
            {
            }
            column(iAmtTxt10; iAmtTxt[10])
            {
            }
            column(iNoTxt10; iNoTxt[10])
            {
            }
            column(iCurrCode10; iCurrCode[10])
            {
            }
            column(iAmtTxt11; iAmtTxt[11])
            {
            }
            column(iNoTxt11; iNoTxt[11])
            {
            }
            column(iCurrCode11; iCurrCode[11])
            {
            }
            column(iAmtTxt12; iAmtTxt[12])
            {
            }
            column(iNoTxt12; iNoTxt[12])
            {
            }
            column(iCurrCode12; iCurrCode[12])
            {
            }
            column(iAmtTxt13; iAmtTxt[13])
            {
            }
            column(iNoTxt13; iNoTxt[13])
            {
            }
            column(iCurrCode13; iCurrCode[13])
            {
            }
            column(iAmtTxt14; iAmtTxt[14])
            {
            }
            column(iNoTxt14; iNoTxt[14])
            {
            }
            column(iCurrCode14; iCurrCode[14])
            {
            }
            column(iAmtTxt15; iAmtTxt[15])
            {
            }
            column(iNoTxt15; iNoTxt[15])
            {
            }
            column(iCurrCode15; iCurrCode[15])
            {
            }
            column(Adr6; Adr[6])
            {
            }
            column(Adr7; Adr[7])
            {
            }
            column(ElectronicPaymentOrderCaption; ElectronicPaymentOrderCaptionLbl)
            {
            }
            column(V4320906PCaption; V4320906PCaptionLbl)
            {
            }
            column(DependingOnApplicationCaption; DependingOnApplicationCaptionLbl)
            {
            }
            column(ReturningAddressCaption; ReturningAddressCaptionLbl)
            {
            }
            column(DataCarrierIdCaption; DataCarrierIdCaptionLbl)
            {
            }
            column(AccountNumberDebitCaption; AccountNumberDebitCaptionLbl)
            {
            }
            column(ISOCurrencyCodeCaption; ISOCurrencyCodeCaptionLbl)
            {
            }
            column(NameOfTransactionCaption; NameOfTransactionCaptionLbl)
            {
            }
            column(ImportTotalCaption; ImportTotalCaptionLbl)
            {
            }
            column(CreationDateCaption; CreationDateCaptionLbl)
            {
            }
            column(CommunicatonsCaption; CommunicatonsCaptionLbl)
            {
            }
            column(ExpiryDateCaption; ExpiryDateCaptionLbl)
            {
            }
            column(OrderNumberCaption; OrderNumberCaptionLbl)
            {
            }
            column(AccountNoExpencesCaption; AccountNoExpencesCaptionLbl)
            {
            }
            column(SignatureCaption; SignatureCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                DtaSetup.CalcFields("EZAG Post Logo", "EZAG Bar Code");
                if not DtaSetup."EZAG Post Logo".HasValue() then
                    Error(Text000, DtaSetup.FieldCaption("EZAG Post Logo"), DtaSetup.TableCaption());
                if not DtaSetup."EZAG Bar Code".HasValue() then
                    Error(Text000, DtaSetup.FieldCaption("EZAG Bar Code"), DtaSetup.TableCaption());
            end;

            trigger OnPreDataItem()
            begin
                SetRange(Number, 1, Copies);
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
                    field("DtaSetup.""Bank Code"""; DtaSetup."Bank Code")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payment from';
                        Lookup = true;
                        TableRelation = "DTA Setup";
                        ToolTip = 'Specifies the bank code that you want to include on the report.';
                    }
                    field(SummaryPerVendor; SummaryPerVendor)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Summary per Vendor';
                        ToolTip = 'Specifies if you want to include a summary for each vendor on the report.';
                    }
                    field(Copies; Copies)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Number of Copies';
                        ToolTip = 'Specifies number of copies that you want to print of the report.';
                    }
                    field("MsgLine[1]"; MsgLine[1])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Message';
                        MultiLine = true;
                        ToolTip = 'Specifies a message to include on the report.';
                    }
                    field("MsgLine[2]"; MsgLine[2])
                    {
                        ApplicationArea = Basic, Suite;
                        MultiLine = true;
                    }
                    field("MsgLine[3]"; MsgLine[3])
                    {
                        ApplicationArea = Basic, Suite;
                        MultiLine = true;
                    }
                    field("MsgLine[4]"; MsgLine[4])
                    {
                        ApplicationArea = Basic, Suite;
                        MultiLine = true;
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

    trigger OnInitReport()
    begin
        if Copies = 0 then
            Copies := 1;
    end;

    trigger OnPreReport()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUsage('0000KEH', 'DTA Local CH Functionality', 'EZAG Payment Order report');
        if not (Copies in [1 .. 10]) then
            Error(Text004);

        if not DtaSetup.Get(DtaSetup."Bank Code") then
            Error(Text002, DtaSetup."Bank Code", DtaSetup.TableCaption());

        if DtaSetup."DTA/EZAG" <> DtaSetup."DTA/EZAG"::EZAG then
            Error(Text003);

        DtaSetup.TestField("EZAG Debit Account No.");
        DtaSetup.TestField("EZAG Charges Account No.");
        DtaSetup.TestField("Last EZAG Order No.");
        DtaSetup.TestField("EZAG Media ID");

        GlSetup.Get();

        CompanyInfo.Get();
        FormatAdr.Company(Adr, CompanyInfo);
    end;

    var
        CompanyInfo: Record "Company Information";
        NextGlLine: Record "Gen. Journal Line";
        DtaSetup: Record "DTA Setup";
        GlSetup: Record "General Ledger Setup";
        VendBank: Record "Vendor Bank Account";
        DtaMgt: Codeunit DtaMgt;
        FormatAdr: Codeunit "Format Address";
        SummaryPerVendor: Boolean;
        Copies: Integer;
        SumPayLine: Boolean;
        DebitDate: Date;
        xISO: Code[3];
        i: Integer;
        iCurrCode: array[15] of Code[3];
        iNoTxt: array[15] of Text[6];
        iNo: array[15] of Integer;
        iAmt: array[15] of Decimal;
        iAmtTxt: array[15] of Text[30];
        Adr: array[8] of Text[100];
        MsgLine: array[4] of Text[25];
        Text000: Label 'The picture %1 is missing. Please add the picture in %2.';
        Text001: Label 'There are only 15 Currencies possible. Please prepare orders with max. 15 Currency Codes.';
        Text002: Label 'The EZAG Bank %1 is not defined in %2.';
        Text003: Label 'This Bank is not Setup for EZAG.';
        Text004: Label 'The Amount of copies should be between 1 and 10.';
        ElectronicPaymentOrderCaptionLbl: Label 'Elektronischer Zahlungsauftrag \Ordre de paiement électronique\Ordine di pagamento elettronico';
        V4320906PCaptionLbl: Label '432.09 06P';
        DependingOnApplicationCaptionLbl: Label '(gemäss Anmeldung) \(selon demande d''adhésion) \(seconde domanda di adesione)';
        ReturningAddressCaptionLbl: Label 'Adresse für die Rücksendung der Datenträger \Adresse pour le renvoi des spports de données \Indirizzo per la rispedizione dei suppporti dati';
        DataCarrierIdCaptionLbl: Label 'Datenträger-Identifikation \Identification du support de données \Identificazione del supporto di dati';
        AccountNumberDebitCaptionLbl: Label 'EZAG-Lastkontonummer \OPAE Numéro du compte de débit \OPAE Numero del conto d''addebito';
        ISOCurrencyCodeCaptionLbl: Label 'ISO Währungscode \Code ISO monnaie \Codice ISO valuta';
        NameOfTransactionCaptionLbl: Label 'Anzahl Transaktionen \Nombre de transactions \Numero di transazioni';
        ImportTotalCaptionLbl: Label 'Totalbetrag \Montant total \Importo totale';
        CreationDateCaptionLbl: Label 'Erstellungsdatum \Date d''émmission \Data d''emmissione';
        CommunicatonsCaptionLbl: Label 'Mitteilungen / Bemerkungen \Communications / Remarques \Comunicazioni  / Osservazioni';
        ExpiryDateCaptionLbl: Label 'Fälligkeitsdatum  \Date d''échénce \Data di scadenza';
        OrderNumberCaptionLbl: Label 'Auftragsnummer \Numéro de l''ordre \Numero dell ordine';
        AccountNoExpencesCaptionLbl: Label 'Gebührenkontonummer \Numéro du compte de frais \Numero del conto delle spese';
        SignatureCaptionLbl: Label 'Unterschrift/Unterschriften \Signature/Signatures \Firma/Firme';
}

