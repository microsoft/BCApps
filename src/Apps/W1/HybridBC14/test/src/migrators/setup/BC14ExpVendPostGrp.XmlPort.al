// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.Purchases.Vendor;

xmlport 148956 "BC14 Exp VendPostGrp"
{
    Caption = 'Expected Vendor Posting Group data';
    Direction = Import;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(VendorPostingGroup; "Vendor Posting Group")
            {
                AutoSave = false;
                XmlName = 'VendorPostingGroup';

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
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    TempVendorPostingGroup.Init();
                    TempVendorPostingGroup.Code := CopyStr(Code, 1, MaxStrLen(TempVendorPostingGroup.Code));
                    TempVendorPostingGroup.Description := CopyStr(Description, 1, MaxStrLen(TempVendorPostingGroup.Description));
                    TempVendorPostingGroup."Payables Account" := CopyStr(PayablesAccount, 1, MaxStrLen(TempVendorPostingGroup."Payables Account"));
                    TempVendorPostingGroup."Service Charge Acc." := CopyStr(ServiceChargeAcc, 1, MaxStrLen(TempVendorPostingGroup."Service Charge Acc."));
                    TempVendorPostingGroup."Payment Disc. Debit Acc." := CopyStr(PaymentDiscDebitAcc, 1, MaxStrLen(TempVendorPostingGroup."Payment Disc. Debit Acc."));
                    TempVendorPostingGroup."Invoice Rounding Account" := CopyStr(InvoiceRoundingAccount, 1, MaxStrLen(TempVendorPostingGroup."Invoice Rounding Account"));
                    TempVendorPostingGroup."Debit Curr. Appln. Rndg. Acc." := CopyStr(DebitCurrApplnRndgAcc, 1, MaxStrLen(TempVendorPostingGroup."Debit Curr. Appln. Rndg. Acc."));
                    TempVendorPostingGroup."Credit Curr. Appln. Rndg. Acc." := CopyStr(CreditCurrApplnRndgAcc, 1, MaxStrLen(TempVendorPostingGroup."Credit Curr. Appln. Rndg. Acc."));
                    TempVendorPostingGroup."Debit Rounding Account" := CopyStr(DebitRoundingAccount, 1, MaxStrLen(TempVendorPostingGroup."Debit Rounding Account"));
                    TempVendorPostingGroup."Credit Rounding Account" := CopyStr(CreditRoundingAccount, 1, MaxStrLen(TempVendorPostingGroup."Credit Rounding Account"));
                    TempVendorPostingGroup."Payment Disc. Credit Acc." := CopyStr(PaymentDiscCreditAcc, 1, MaxStrLen(TempVendorPostingGroup."Payment Disc. Credit Acc."));
                    TempVendorPostingGroup."Payment Tolerance Debit Acc." := CopyStr(PaymentToleranceDebitAcc, 1, MaxStrLen(TempVendorPostingGroup."Payment Tolerance Debit Acc."));
                    TempVendorPostingGroup."Payment Tolerance Credit Acc." := CopyStr(PaymentToleranceCreditAcc, 1, MaxStrLen(TempVendorPostingGroup."Payment Tolerance Credit Acc."));
                    TempVendorPostingGroup.Insert();

                    currXMLport.Skip();
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        CaptionRow := true;
        TempVendorPostingGroup.Reset();
        TempVendorPostingGroup.DeleteAll();
    end;

    procedure GetExpectedVendorPostingGroups(var Dest: Record "Vendor Posting Group" temporary)
    begin
        Dest.Reset();
        Dest.DeleteAll();
        if TempVendorPostingGroup.FindSet() then
            repeat
                Dest := TempVendorPostingGroup;
                Dest.Insert();
            until TempVendorPostingGroup.Next() = 0;
    end;

    var
        TempVendorPostingGroup: Record "Vendor Posting Group" temporary;
        CaptionRow: Boolean;
}
