// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

report 3010835 "LSV Collection Order"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Bank/Payment/LSVCollectionOrder.rdlc';
    Caption = 'LSV Collection Order';

    dataset
    {
        dataitem("LSV Journal"; "LSV Journal")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.";
            column(No_LSVJnl; "No.")
            {
            }
            column(CreditDate_LSVJnl; Format("Credit Date"))
            {
            }
            column(AmtPlus_LSVJnl; "Amount Plus")
            {
            }
            column(FileWrittenOn_LSVJnl; Format("File Written On"))
            {
            }
            column(LsvBankAdr5; LsvBankAdr[5])
            {
            }
            column(LsvBankAdr4; LsvBankAdr[4])
            {
            }
            column(LsvBankAdr3; LsvBankAdr[3])
            {
            }
            column(LsvSenderAdr3; LsvSenderAdr[3])
            {
            }
            column(LsvSenderAdr4; LsvSenderAdr[4])
            {
            }
            column(LsvSenderAdr5; LsvSenderAdr[5])
            {
            }
            column(LsvBankAdr2; LsvBankAdr[2])
            {
            }
            column(LsvSenderAdr2; LsvSenderAdr[2])
            {
            }
            column(LsvBankAdr1; LsvBankAdr[1])
            {
            }
            column(LsvSenderAdr1; LsvSenderAdr[1])
            {
            }
            column(LsvSetupLSVSenderIBAN; LsvSetup."LSV Sender IBAN")
            {
            }
            column(LsvSetupLSVCustID; LsvSetup."LSV Customer ID")
            {
            }
            column(LsvSetupLSVSenderID; LsvSetup."LSV Sender ID")
            {
            }
            column(EmptyString; '')
            {
            }
            column(LsvSetupLSVSenderCity; LsvSetup."LSV Sender City" + ', ' + Format(WorkDate()))
            {
            }
            column(LsvSetupLSVCurrCode; LsvSetup."LSV Currency Code")
            {
            }
            column(LSVJnlNoCaption; LSVJnlNoCaptionLbl)
            {
            }
            column(LSVCaption; LSVCaptionLbl)
            {
            }
            column(BeneficiaryCaption; BeneficiaryCaptionLbl)
            {
            }
            column(LSVSenderIBANCaption; LSVSenderIBANCaptionLbl)
            {
            }
            column(FileTransferRequestCaption; FileTransferRequestCaptionLbl)
            {
            }
            column(DebitAuthorisationCaption; DebitAuthorisationCaptionLbl)
            {
            }
            column(BeneficiaryIdentificationCaption; BeneficiaryIdentificationCaptionLbl)
            {
            }
            column(LSVFileSenderIdentificationCaption; LSVFileSenderIdentificationCaptionLbl)
            {
            }
            column(LSVFileCreationDateCaption; LSVFileCreationDateCaptionLbl)
            {
            }
            column(RequiredProcessingDateCaption; RequiredProcessingDateCaptionLbl)
            {
            }
            column(CompanySignatureCaption; CompanySignatureCaptionLbl)
            {
            }
            column(DatePlaceCaption; DatePlaceCaptionLbl)
            {
            }
            column(CollectionOrderCaption; CollectionOrderCaptionLbl)
            {
            }
            column(RecoveryOrderCaption; RecoveryOrderCaptionLbl)
            {
            }
            column(OrderCollectionCaption; OrderCollectionCaptionLbl)
            {
            }
            column(YearCaption; YearCaptionLbl)
            {
            }
            column(TreatDirectDebitsByTransferringFilesCaption; TreatDirectDebitsByTransferringFilesCaptionLbl)
            {
            }
            column(NoticesOfWithdrawalCaption; NoticesOfWithdrawalCaptionLbl)
            {
            }
            column(DebitAuthorizationCaption; DebitAuthorizationCaptionLbl)
            {
            }
            column(DebitAuthorizationITCaption; DebitAuthorizationITCaptionLbl)
            {
            }
            column(BeneficialIdentificationCaption; BeneficialIdentificationCaptionLbl)
            {
            }
            column(BeneficialIdentificationITCaption; BeneficialIdentificationITCaptionLbl)
            {
            }
            column(SenderIdITCaption; SenderIdITCaptionLbl)
            {
            }
            column(SenderIdFRCaption; SenderIdFRCaptionLbl)
            {
            }
            column(LSVFileCreationFRCaption; LSVFileCreationFRCaptionLbl)
            {
            }
            column(LSVFileCreationITCaption; LSVFileCreationITCaptionLbl)
            {
            }
            column(DateOfExecutionFRCaption; DateOfExecutionFRCaptionLbl)
            {
            }
            column(DateOfExecutionITCaption; DateOfExecutionITCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                LsvSetup.Get("LSV Bank Code");
                LsvSetup.TestField("LSV Sender IBAN");
                TestField("File Written On");

                LsvSenderAdr[1] := LsvSetup."LSV Sender Name";
                LsvSenderAdr[2] := LsvSetup."LSV Sender Name 2";
                LsvSenderAdr[3] := LsvSetup."LSV Sender Address";
                LsvSenderAdr[4] := Format(LsvSetup."LSV Sender Post Code" + ' ' + LsvSetup."LSV Sender City", -MaxStrLen(LsvSenderAdr[4]));
                CompressArray(LsvSenderAdr);

                LsvBankAdr[1] := LsvSetup."LSV Bank Name";
                LsvBankAdr[2] := LsvSetup."LSV Bank Name 2";
                LsvBankAdr[3] := LsvSetup."LSV Bank Address";
                LsvBankAdr[4] := Format(LsvSetup."LSV Bank Post Code" + ' ' + LsvSetup."LSV Bank City", -MaxStrLen(LsvBankAdr[4]));
                CompressArray(LsvBankAdr);
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

    var
        LsvSetup: Record "LSV Setup";
        LsvSenderAdr: array[6] of Text[50];
        LsvBankAdr: array[6] of Text[50];
        LSVJnlNoCaptionLbl: Label 'Collection';
        LSVCaptionLbl: Label 'LSV+';
        BeneficiaryCaptionLbl: Label 'Zahlungsempfänger / Bénéficiaire / Beneficiario';
        LSVSenderIBANCaptionLbl: Label 'IBAN:';
        FileTransferRequestCaptionLbl: Label 'Ich / Wir bitte(n) um Verarbeitung der heute mittels Filetransfer eingereichten Lastschriften über total';
        DebitAuthorisationCaptionLbl: Label 'Die Belastungsermächtigungen liegen mir / uns vor.';
        BeneficiaryIdentificationCaptionLbl: Label 'Identifikation des Zahlungsempfängers';
        LSVFileSenderIdentificationCaptionLbl: Label 'Identifikation des LSV Fileabsenders';
        LSVFileCreationDateCaptionLbl: Label 'Erstellungsdatum des LSV-Files';
        RequiredProcessingDateCaptionLbl: Label 'Gewünschtes Verarbeitungsdatum';
        CompanySignatureCaptionLbl: Label 'Unterschrift / Signature / Firma';
        DatePlaceCaptionLbl: Label 'Ort, Datum / Lieu, date / Luogo, data';
        CollectionOrderCaptionLbl: Label 'Einzugsauftrag';
        RecoveryOrderCaptionLbl: Label 'Ordre de recouvrement';
        OrderCollectionCaptionLbl: Label 'Ordine d''incasso';
        YearCaptionLbl: Label 'an / à / a';
        TreatDirectDebitsByTransferringFilesCaptionLbl: Label 'Veuillez traiter les recouvrements directs remis ce jour par transfert de fichiers pour un montant total de';
        NoticesOfWithdrawalCaptionLbl: Label 'Io / Noi vi preg(o / hiamo) di elaborare gli avvisi di prelevamento trasmessi oggi mediante trasferimento di un file per il totale di';
        DebitAuthorizationCaptionLbl: Label 'Les autorisations de débit sont en ma / notre possession.';
        DebitAuthorizationITCaptionLbl: Label 'Le autorizzazioni d''addebitamento sono in mio / nostro possesso.';
        BeneficialIdentificationCaptionLbl: Label 'Identification du bénéficiaire';
        BeneficialIdentificationITCaptionLbl: Label 'Identificazi one del beneficiario';
        SenderIdITCaptionLbl: Label 'Identificazione del mitente del file LSV';
        SenderIdFRCaptionLbl: Label 'Identification de l''expéditeur du fichier LSV';
        LSVFileCreationFRCaptionLbl: Label 'Date de création du fichier LSV';
        LSVFileCreationITCaptionLbl: Label 'Data del rilevamento del file LSV';
        DateOfExecutionFRCaptionLbl: Label 'Date désirée de l''exécution';
        DateOfExecutionITCaptionLbl: Label 'Data desiderata per l''esecuzione';
}

