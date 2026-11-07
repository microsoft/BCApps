// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.Sales.Customer;

xmlport 148954 "BC14 Exp CustPostGrp"
{
    Caption = 'Expected Customer Posting Group data';
    Direction = Import;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(CustomerPostingGroup; "Customer Posting Group")
            {
                AutoSave = false;
                XmlName = 'CustomerPostingGroup';

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
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    TempCustomerPostingGroup.Init();
                    TempCustomerPostingGroup.Code := CopyStr(Code, 1, MaxStrLen(TempCustomerPostingGroup.Code));
                    TempCustomerPostingGroup.Description := CopyStr(Description, 1, MaxStrLen(TempCustomerPostingGroup.Description));
                    TempCustomerPostingGroup."Receivables Account" := CopyStr(ReceivablesAccount, 1, MaxStrLen(TempCustomerPostingGroup."Receivables Account"));
                    TempCustomerPostingGroup."Service Charge Acc." := CopyStr(ServiceChargeAcc, 1, MaxStrLen(TempCustomerPostingGroup."Service Charge Acc."));
                    TempCustomerPostingGroup."Payment Disc. Debit Acc." := CopyStr(PaymentDiscDebitAcc, 1, MaxStrLen(TempCustomerPostingGroup."Payment Disc. Debit Acc."));
                    TempCustomerPostingGroup."Invoice Rounding Account" := CopyStr(InvoiceRoundingAccount, 1, MaxStrLen(TempCustomerPostingGroup."Invoice Rounding Account"));
                    TempCustomerPostingGroup."Additional Fee Account" := CopyStr(AdditionalFeeAccount, 1, MaxStrLen(TempCustomerPostingGroup."Additional Fee Account"));
                    TempCustomerPostingGroup."Interest Account" := CopyStr(InterestAccount, 1, MaxStrLen(TempCustomerPostingGroup."Interest Account"));
                    TempCustomerPostingGroup."Debit Curr. Appln. Rndg. Acc." := CopyStr(DebitCurrApplnRndgAcc, 1, MaxStrLen(TempCustomerPostingGroup."Debit Curr. Appln. Rndg. Acc."));
                    TempCustomerPostingGroup."Credit Curr. Appln. Rndg. Acc." := CopyStr(CreditCurrApplnRndgAcc, 1, MaxStrLen(TempCustomerPostingGroup."Credit Curr. Appln. Rndg. Acc."));
                    TempCustomerPostingGroup."Debit Rounding Account" := CopyStr(DebitRoundingAccount, 1, MaxStrLen(TempCustomerPostingGroup."Debit Rounding Account"));
                    TempCustomerPostingGroup."Credit Rounding Account" := CopyStr(CreditRoundingAccount, 1, MaxStrLen(TempCustomerPostingGroup."Credit Rounding Account"));
                    TempCustomerPostingGroup."Payment Disc. Credit Acc." := CopyStr(PaymentDiscCreditAcc, 1, MaxStrLen(TempCustomerPostingGroup."Payment Disc. Credit Acc."));
                    TempCustomerPostingGroup."Payment Tolerance Debit Acc." := CopyStr(PaymentToleranceDebitAcc, 1, MaxStrLen(TempCustomerPostingGroup."Payment Tolerance Debit Acc."));
                    TempCustomerPostingGroup."Payment Tolerance Credit Acc." := CopyStr(PaymentToleranceCreditAcc, 1, MaxStrLen(TempCustomerPostingGroup."Payment Tolerance Credit Acc."));
                    TempCustomerPostingGroup."Add. Fee per Line Account" := CopyStr(AddFeePerLineAccount, 1, MaxStrLen(TempCustomerPostingGroup."Add. Fee per Line Account"));
                    TempCustomerPostingGroup.Insert();

                    currXMLport.Skip();
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        CaptionRow := true;
        TempCustomerPostingGroup.Reset();
        TempCustomerPostingGroup.DeleteAll();
    end;

    procedure GetExpectedCustomerPostingGroups(var Dest: Record "Customer Posting Group" temporary)
    begin
        Dest.Reset();
        Dest.DeleteAll();
        if TempCustomerPostingGroup.FindSet() then
            repeat
                Dest := TempCustomerPostingGroup;
                Dest.Insert();
            until TempCustomerPostingGroup.Next() = 0;
    end;

    var
        TempCustomerPostingGroup: Record "Customer Posting Group" temporary;
        CaptionRow: Boolean;
}
