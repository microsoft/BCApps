// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14Reimplementation;

xmlport 148955 "BC14 VendPostGrp Data"
{
    Caption = 'BC14 Vendor Posting Group buffer data';
    Direction = Both;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(BC14VendorPostingGroup; "BC14 Vendor Posting Group")
            {
                AutoSave = false;
                XmlName = 'BC14VendorPostingGroup';

                textelement(Code) { }
                textelement(Description) { }
                textelement(PayablesAccount) { }
                textelement(ServiceChargeAcc) { }
                textelement(PaymentDiscDebitAcc) { }
                textelement(InvoiceRoundingAccount) { }
                textelement(DebitCurrApplnRndgAcc) { }
                textelement(CreditCurrApplnRndgAcc) { }
                textelement(DebitRoundingAccount) { }
                textelement(CreditRoundingAccount) { }
                textelement(PaymentDiscCreditAcc) { }
                textelement(PaymentToleranceDebitAcc) { }
                textelement(PaymentToleranceCreditAcc) { }

                trigger OnBeforeInsertRecord()
                var
                    NewBC14VendorPostingGroup: Record "BC14 Vendor Posting Group";
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    NewBC14VendorPostingGroup.Init();
                    NewBC14VendorPostingGroup.Code := CopyStr(Code, 1, MaxStrLen(NewBC14VendorPostingGroup.Code));
                    NewBC14VendorPostingGroup.Description := CopyStr(Description, 1, MaxStrLen(NewBC14VendorPostingGroup.Description));
                    NewBC14VendorPostingGroup."Payables Account" := CopyStr(PayablesAccount, 1, MaxStrLen(NewBC14VendorPostingGroup."Payables Account"));
                    NewBC14VendorPostingGroup."Service Charge Acc." := CopyStr(ServiceChargeAcc, 1, MaxStrLen(NewBC14VendorPostingGroup."Service Charge Acc."));
                    NewBC14VendorPostingGroup."Payment Disc. Debit Acc." := CopyStr(PaymentDiscDebitAcc, 1, MaxStrLen(NewBC14VendorPostingGroup."Payment Disc. Debit Acc."));
                    NewBC14VendorPostingGroup."Invoice Rounding Account" := CopyStr(InvoiceRoundingAccount, 1, MaxStrLen(NewBC14VendorPostingGroup."Invoice Rounding Account"));
                    NewBC14VendorPostingGroup."Debit Curr. Appln. Rndg. Acc." := CopyStr(DebitCurrApplnRndgAcc, 1, MaxStrLen(NewBC14VendorPostingGroup."Debit Curr. Appln. Rndg. Acc."));
                    NewBC14VendorPostingGroup."Credit Curr. Appln. Rndg. Acc." := CopyStr(CreditCurrApplnRndgAcc, 1, MaxStrLen(NewBC14VendorPostingGroup."Credit Curr. Appln. Rndg. Acc."));
                    NewBC14VendorPostingGroup."Debit Rounding Account" := CopyStr(DebitRoundingAccount, 1, MaxStrLen(NewBC14VendorPostingGroup."Debit Rounding Account"));
                    NewBC14VendorPostingGroup."Credit Rounding Account" := CopyStr(CreditRoundingAccount, 1, MaxStrLen(NewBC14VendorPostingGroup."Credit Rounding Account"));
                    NewBC14VendorPostingGroup."Payment Disc. Credit Acc." := CopyStr(PaymentDiscCreditAcc, 1, MaxStrLen(NewBC14VendorPostingGroup."Payment Disc. Credit Acc."));
                    NewBC14VendorPostingGroup."Payment Tolerance Debit Acc." := CopyStr(PaymentToleranceDebitAcc, 1, MaxStrLen(NewBC14VendorPostingGroup."Payment Tolerance Debit Acc."));
                    NewBC14VendorPostingGroup."Payment Tolerance Credit Acc." := CopyStr(PaymentToleranceCreditAcc, 1, MaxStrLen(NewBC14VendorPostingGroup."Payment Tolerance Credit Acc."));
                    NewBC14VendorPostingGroup.Insert();

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
