// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Sales.Customer;

report 3010836 "LSV Collection Authorisation"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Bank/Payment/LSVCollectionAuthorisation.rdlc';
    Caption = 'LSV Collection Authorisation';

    dataset
    {
        dataitem(Customer; Customer)
        {
            RequestFilterFields = "No.", "Customer Posting Group", "Statistics Group", "Payment Method Code", "Country/Region Code", "Currency Code";
            column(Adr6; Adr[6])
            {
            }
            column(Adr7; Adr[7])
            {
            }
            column(Adr5; Adr[5])
            {
            }
            column(Adr4; Adr[4])
            {
            }
            column(Adr3; Adr[3])
            {
            }
            column(Adr2; Adr[2])
            {
            }
            column(Adr1; Adr[1])
            {
            }
            column(CompanyAdr1; CompanyAdr[1])
            {
            }
            column(CompanyAdr2; CompanyAdr[2])
            {
            }
            column(CompanyAdr3; CompanyAdr[3])
            {
            }
            column(CompanyAdr4; CompanyAdr[4])
            {
            }
            column(CompanyAdr5; CompanyAdr[5])
            {
            }
            column(CompanyAdr6; CompanyAdr[6])
            {
            }
            column(LSVCustID_LsvSetup; LsvSetup."LSV Customer ID")
            {
            }
            column(City_CompanyInfo_WorkDateFormatted; CompanyInfo.City + ', ' + Format(WorkDate()))
            {
            }
            column(Text_LsvSetup; LsvSetup.Text)
            {
            }
            column(Text2_LsvSetup; LsvSetup."Text 2")
            {
            }
            column(EmptyString; '')
            {
            }
            column(LSVCurrCode_LsvSetup; LsvSetup."LSV Currency Code")
            {
            }
            column(LSVIDENTCaption; LSVIDENTLbl)
            {
            }
            column(No_Cust; "No.")
            {
            }
            column(LSVHeaderCaption; LSVLbl)
            {
            }
            column(RefNo1Caption; RefNo1Lbl)
            {
            }
            column(RefNo2Caption; RefNo2Lbl)
            {
            }
            column(CreditorCaption; CreditorLbl)
            {
            }
            column(CustomerCaption; CustomerLbl)
            {
            }
            column(NameOfBank1Caption; NameOfBank1Lbl)
            {
            }
            column(NameOfBank2Caption; NameOfBank2Lbl)
            {
            }
            column(PostalCodeAndCity1Caption; PostalCodeAndCity1Lbl)
            {
            }
            column(PostalCodeAndCity2Caption; PostalCodeAndCity2Lbl)
            {
            }
            column(IBANCaption; IBANLbl)
            {
            }
            column(BankClearingNo1Caption; BankClearingNo1Lbl)
            {
            }
            column(BankClearingNo2Caption; BankClearingNo2Lbl)
            {
            }
            column(PlaceDateCaption; PlaceDateLbl)
            {
            }
            column(SignatureCaption; SignatureLbl)
            {
            }
            column(RectificationCaption; RectificationLbl)
            {
            }
            column(LeaveBlankToCompletedByBankCaption; LeaveBlankToCompletedByBankLbl)
            {
            }
            column(NoCBCaption; NoCBLbl)
            {
            }
            column(DatumCaption; DatumLbl)
            {
            }
            column(DateCaption; DateLbl)
            {
            }
            column(BankVisaCHCaption; BankVisaCHLbl)
            {
            }
            column(BankVisaFRCaption; BankVisaFRLbl)
            {
            }
            column(DebitAuthorizationENUHeaderCaption; DebitAuthorizationENUHeaderLbl)
            {
            }
            column(DebitAuthorizationENUText; DebitAuthorizationENU)
            {
            }
            column(DebitAuthorizationENU2Caption; DebitAuthorizationENU2Lbl)
            {
            }
            column(DebitAuthorizationENU3Caption; DebitAuthorizationENU3Lbl)
            {
            }
            column(DebitAuthorizationENU4Caption; DebitAuthorizationENU4Lbl)
            {
            }
            column(DebitAuthorizationENU5Caption; DebitAuthorizationENU5Lbl)
            {
            }
            column(DebitAuthorizationCHHeaderCaption; DebitAuthorizationCHHeaderLbl)
            {
            }
            column(DebitAuthorizationCHText; DebitAuthorizationCH)
            {
            }
            column(DebitAuthorizationCH2Caption; DebitAuthorizationCH2Lbl)
            {
            }
            column(DebitAuthorizationCH3Caption; DebitAuthorizationCH3Lbl)
            {
            }
            column(DebitAuthorizationCH4Caption; DebitAuthorizationCH4Lbl)
            {
            }
            column(DebitAuthorizationCH5Caption; DebitAuthorizationCH5Lbl)
            {
            }
            column(DebitAuthorizationFRHeaderCaption; DebitAuthorizationFRHeaderLbl)
            {
            }
            column(DebitAuthorizationFRText; DebitAuthorizationFR)
            {
            }
            column(DebitAuthorizationFR2Caption; DebitAuthorizationFR2Lbl)
            {
            }
            column(DebitAuthorizationFR3Caption; DebitAuthorizationFR3Lbl)
            {
            }
            column(DebitAuthorizationFR4Caption; DebitAuthorizationFR4Lbl)
            {
            }
            column(DebitAuthorizationFR5Caption; DebitAuthorizationFR5Lbl)
            {
            }
            column(DebitAuthorizationITHeaderCaption; DebitAuthorizationITHeaderLbl)
            {
            }
            column(DebitAuthorizationITText; DebitAuthorizationIT)
            {
            }
            column(DebitAuthorizationIT2Caption; DebitAuthorizationIT2Lbl)
            {
            }
            column(DebitAuthorizationIT3Caption; DebitAuthorizationIT3Lbl)
            {
            }
            column(DebitAuthorizationIT4Caption; DebitAuthorizationIT4Lbl)
            {
            }
            column(DebitAuthorizationIT5Caption; DebitAuthorizationIT5Lbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                FormatAdr.Customer(Adr, Customer);
            end;

            trigger OnPreDataItem()
            begin
                if GetFilters = '' then
                    if not Confirm(SendToAllCustomersQst) then
                        CurrReport.Break();

                LsvSetup.Get(LsvSetup."Bank Code");

                CompanyInfo.Get();
                FormatAdr.Company(CompanyAdr, CompanyInfo);

                DebitAuthorizationENU := StrSubstNo(DebitAuthorizationENU1Txt, LsvSetup."LSV Currency Code");
                DebitAuthorizationIT := StrSubstNo(DebitAuthorizationIT1Txt, LsvSetup."LSV Currency Code");
                DebitAuthorizationFR := StrSubstNo(DebitAuthorizationFR1Txt, LsvSetup."LSV Currency Code");
                DebitAuthorizationCH := StrSubstNo(DebitAuthorizationCH1Txt, LsvSetup."LSV Currency Code");
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field("LsvSetup.""Bank Code"""; LsvSetup."Bank Code")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'LSV Bank Code';
                        TableRelation = "LSV Setup";
                        ToolTip = 'Specifies the LSV bank code that you want to print on the report.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if LsvSetup.Count = 1 then
                LsvSetup.FindFirst();
        end;
    }

    labels
    {
    }

    var
        SendToAllCustomersQst: Label 'Are you sure that you want to send the collection authorization to all customers?\You have not set any filter and therefore you have selected all customers.\Do you want to continue?';
        CompanyInfo: Record "Company Information";
        LsvSetup: Record "LSV Setup";
        FormatAdr: Codeunit "Format Address";
        Adr: array[8] of Text[100];
        CompanyAdr: array[8] of Text[100];
        LSVIDENTLbl: Label 'LSV-IDENT.', Locked = true;
        LSVLbl: Label 'LSV*', Locked = true;
        RefNo1Lbl: Label 'Ref Nr. / No. Réf.', Locked = true;
        RefNo2Lbl: Label 'N. Rif / Ref No.', Locked = true;
        CreditorLbl: Label 'Zahlungsempfänger / Bénéficiaire / Beneficiario / Creditor', Locked = true;
        CustomerLbl: Label 'Kunde / Client / Cliente / Customer', Locked = true;
        NameOfBank1Lbl: Label 'Bankname / Nom de la banque /', Locked = true;
        NameOfBank2Lbl: Label 'Nome della banca / Name of bank', Locked = true;
        PostalCodeAndCity1Lbl: Label 'PLZ und Ort / NPA et Lieu /', Locked = true;
        PostalCodeAndCity2Lbl: Label 'NPA et Luogo  / Postal code and City', Locked = true;
        IBANLbl: Label 'IBAN', Locked = true;
        BankClearingNo1Lbl: Label 'Bankenclearing-Nr. (soffen bekannt) / No clearing bancaire (si connu) /', Locked = true;
        BankClearingNo2Lbl: Label 'N. di clearing bancario (se conosciuto) /  Bank clearing no. (if known)', Locked = true;
        DebitAuthorizationENUHeaderLbl: Label 'Debit authorization with right of objection', Locked = true;
        DebitAuthorizationENU1Txt: Label 'I hereby authorize my bank to deduct debits <b>in %1</b> from the above-listed creditor directly from my account until the authorization is revoked.', Locked = true;
        DebitAuthorizationENU2Lbl: Label 'If there are insufficient funds in my account, then my bank is not obligated to carry out the debit.', Locked = true;
        DebitAuthorizationENU3Lbl: Label 'I will be notified for each debit to my account.', Locked = true;
        DebitAuthorizationENU4Lbl: Label 'The amount debited will be repaid to me if I contest the debit in binding form to my bank within 30 calendar days of date of notification.', Locked = true;
        DebitAuthorizationENU5Lbl: Label 'I authorize my bank to notify the creditor in Switzerland or abroad about the contents of this debit authorization as well as any subsequent rescinding thereof with the means of communications considered best suited by the bank.', Locked = true;
        DebitAuthorizationITHeaderLbl: Label 'Autorizzazione di addebito con diritto di contestazione', Locked = true;
        DebitAuthorizationIT1Txt: Label 'Con la presente autorizzo la mia banca revocabilmente ad addebitare sul mio conto gli avvisi di addebito <b>in %1</b> emessi dal beneficiario summenzionato.', Locked = true;
        DebitAuthorizationIT2Lbl: Label 'Se il mio conto non ha la necessaria copertura, la mia banca non è tenuta ad effettuare l''addebito.', Locked = true;
        DebitAuthorizationIT3Lbl: Label 'Riceverò un avviso per ogni addebito sul mio conto.', Locked = true;
        DebitAuthorizationIT4Lbl: Label 'L''importo addebitato mi verrà riaccreditato, se lo contesterò in forma vincolante alla mia banca entro 30 giorni calendario dalla data dell''avviso.', Locked = true;
        DebitAuthorizationIT5Lbl: Label 'Autorizzo la mia banca a informare il destinatario del pagamento nel nostro paese o all’estero sul contenuto della presente autorizzazione di addebito nonché sulla sua eventuale revoca successiva in qualsiasi modo essa lo ritenga opportuno.', Locked = true;
        DebitAuthorizationFRHeaderLbl: Label 'Authorisation de débit avec droit de contestation', Locked = true;
        DebitAuthorizationFR1Txt: Label 'Par la présente j''autorise ma banque, sous reserve de révocation, à débiter sur mon compte les recouvrements directs <b>en %1</b> émis par le bénéficiaire ci-dessus.', Locked = true;
        DebitAuthorizationFR2Lbl: Label 'Si mon compte ne présente pas la couverture suffisante, il n''existe pour ma banque aucune obligation de débit.', Locked = true;
        DebitAuthorizationFR3Lbl: Label 'Chaque débit sur mon compte me sera avisé.', Locked = true;
        DebitAuthorizationFR4Lbl: Label 'Le montant débité me sera remboursé si je le conteste dans les 30 jours civils après la date de l''avis auprès de ma banque, en la forme contraignante.', Locked = true;
        DebitAuthorizationFR5Lbl: Label 'J''autorise ma banque à informer le bénéficiaire, en Suisse ou à l''étranger, du contenu de cette autorisation de débit ainsi que de son éventuelle annulation par la suite, et ce par tous les moyens de communication qui lui sembleront appropriés.', Locked = true;
        DebitAuthorizationCHHeaderLbl: Label 'Belastungsermächtigung mit Widerspruchsmöglichkeit', Locked = true;
        DebitAuthorizationCH1Txt: Label 'Hiermit ermächtige ich meine Bank bis auf Widerruf, die ihr von obigem Zahlungsempfänger vorgelegten Lastschriften <b>in %1</b> meinem Konto zu belasten.', Locked = true;
        DebitAuthorizationCH2Lbl: Label 'Wenn mein Konto die erforderliche Deckung nicht aufweist, besteht für meine Bank keine Verpflichtung zur Belastung.', Locked = true;
        DebitAuthorizationCH3Lbl: Label 'Jede Belastung meines Kontos wird mir avisiert.', Locked = true;
        DebitAuthorizationCH4Lbl: Label 'Der belastete Betrag wird mir zurückvergütet, falls ich innerhalb von 30 Kalendertagen nach Avisierungsdatum bei meiner Bank in verbindlicher Form Widerspruch einlege.', Locked = true;
        DebitAuthorizationCH5Lbl: Label 'Ich ermächtige meine Bank, dem Zahlungsempfänger im In- oder Ausland den Inhalt dieser Belastungsermächtigung sowie deren allfällige spätere Aufhebung mit jedem der Bank geeignet erscheinenden Kommunikationsmittel zur Kenntnis zu bringen.', Locked = true;
        PlaceDateLbl: Label 'Ort, Datum  /  Lieu, Date  /  Luogo, Data  /  Place, Date', Locked = true;
        SignatureLbl: Label 'Unterschrift  /  Signature  /  Firma  /  Signature', Locked = true;
        LeaveBlankToCompletedByBankLbl: Label 'Leer lassen, wird von der Bank ausgefüllt / Laisser vide, à remplir par la banque / Lasciare vuoto, è riempito della banca  / Leave blank, to be completed by the bank.', Locked = true;
        RectificationLbl: Label 'Berichtigungen  /  Rectification', Locked = true;
        NoCBLbl: Label 'BC-Nr./No.CB', Locked = true;
        DatumLbl: Label 'Datum:', Locked = true;
        DateLbl: Label 'Date:', Locked = true;
        DebitAuthorizationENU: Text;
        DebitAuthorizationIT: Text;
        DebitAuthorizationFR: Text;
        DebitAuthorizationCH: Text;
        BankVisaCHLbl: Label 'Stempel und Visum der Bank:', Locked = true;
        BankVisaFRLbl: Label 'Timbre et visa de la banque:', Locked = true;
}

