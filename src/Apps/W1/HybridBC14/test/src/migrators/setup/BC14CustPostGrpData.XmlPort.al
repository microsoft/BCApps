// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14Reimplementation;

xmlport 148953 "BC14 CustPostGrp Data"
{
    Caption = 'BC14 Customer Posting Group buffer data';
    Direction = Both;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(BC14CustomerPostingGroup; "BC14 Customer Posting Group")
            {
                AutoSave = false;
                XmlName = 'BC14CustomerPostingGroup';

                textelement(Code) { }
                textelement(Description) { }
                textelement(ReceivablesAccount) { }
                textelement(ServiceChargeAcc) { }
                textelement(PaymentDiscDebitAcc) { }
                textelement(InvoiceRoundingAccount) { }
                textelement(AdditionalFeeAccount) { }
                textelement(InterestAccount) { }
                textelement(DebitCurrApplnRndgAcc) { }
                textelement(CreditCurrApplnRndgAcc) { }
                textelement(DebitRoundingAccount) { }
                textelement(CreditRoundingAccount) { }
                textelement(PaymentDiscCreditAcc) { }
                textelement(PaymentToleranceDebitAcc) { }
                textelement(PaymentToleranceCreditAcc) { }
                textelement(AddFeePerLineAccount) { }

                trigger OnBeforeInsertRecord()
                var
                    NewBC14CustomerPostingGroup: Record "BC14 Customer Posting Group";
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    NewBC14CustomerPostingGroup.Init();
                    NewBC14CustomerPostingGroup.Code := CopyStr(Code, 1, MaxStrLen(NewBC14CustomerPostingGroup.Code));
                    NewBC14CustomerPostingGroup.Description := CopyStr(Description, 1, MaxStrLen(NewBC14CustomerPostingGroup.Description));
                    NewBC14CustomerPostingGroup."Receivables Account" := CopyStr(ReceivablesAccount, 1, MaxStrLen(NewBC14CustomerPostingGroup."Receivables Account"));
                    NewBC14CustomerPostingGroup."Service Charge Acc." := CopyStr(ServiceChargeAcc, 1, MaxStrLen(NewBC14CustomerPostingGroup."Service Charge Acc."));
                    NewBC14CustomerPostingGroup."Payment Disc. Debit Acc." := CopyStr(PaymentDiscDebitAcc, 1, MaxStrLen(NewBC14CustomerPostingGroup."Payment Disc. Debit Acc."));
                    NewBC14CustomerPostingGroup."Invoice Rounding Account" := CopyStr(InvoiceRoundingAccount, 1, MaxStrLen(NewBC14CustomerPostingGroup."Invoice Rounding Account"));
                    NewBC14CustomerPostingGroup."Additional Fee Account" := CopyStr(AdditionalFeeAccount, 1, MaxStrLen(NewBC14CustomerPostingGroup."Additional Fee Account"));
                    NewBC14CustomerPostingGroup."Interest Account" := CopyStr(InterestAccount, 1, MaxStrLen(NewBC14CustomerPostingGroup."Interest Account"));
                    NewBC14CustomerPostingGroup."Debit Curr. Appln. Rndg. Acc." := CopyStr(DebitCurrApplnRndgAcc, 1, MaxStrLen(NewBC14CustomerPostingGroup."Debit Curr. Appln. Rndg. Acc."));
                    NewBC14CustomerPostingGroup."Credit Curr. Appln. Rndg. Acc." := CopyStr(CreditCurrApplnRndgAcc, 1, MaxStrLen(NewBC14CustomerPostingGroup."Credit Curr. Appln. Rndg. Acc."));
                    NewBC14CustomerPostingGroup."Debit Rounding Account" := CopyStr(DebitRoundingAccount, 1, MaxStrLen(NewBC14CustomerPostingGroup."Debit Rounding Account"));
                    NewBC14CustomerPostingGroup."Credit Rounding Account" := CopyStr(CreditRoundingAccount, 1, MaxStrLen(NewBC14CustomerPostingGroup."Credit Rounding Account"));
                    NewBC14CustomerPostingGroup."Payment Disc. Credit Acc." := CopyStr(PaymentDiscCreditAcc, 1, MaxStrLen(NewBC14CustomerPostingGroup."Payment Disc. Credit Acc."));
                    NewBC14CustomerPostingGroup."Payment Tolerance Debit Acc." := CopyStr(PaymentToleranceDebitAcc, 1, MaxStrLen(NewBC14CustomerPostingGroup."Payment Tolerance Debit Acc."));
                    NewBC14CustomerPostingGroup."Payment Tolerance Credit Acc." := CopyStr(PaymentToleranceCreditAcc, 1, MaxStrLen(NewBC14CustomerPostingGroup."Payment Tolerance Credit Acc."));
                    NewBC14CustomerPostingGroup."Add. Fee per Line Account" := CopyStr(AddFeePerLineAccount, 1, MaxStrLen(NewBC14CustomerPostingGroup."Add. Fee per Line Account"));
                    NewBC14CustomerPostingGroup.Insert();

                    currXMLport.Skip();
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        CaptionRow := true;
    end;

    var
        CaptionRow: Boolean;
}
