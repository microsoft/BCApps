// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.Bank.BankAccount;

xmlport 148932 "BC14 Exp Payment Method Data"
{
    Caption = 'Expected Payment Method data for BC14 migration tests';
    Direction = Import;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(PaymentMethod; "Payment Method")
            {
                AutoSave = false;
                XmlName = 'PaymentMethod';

                textelement(Code) { }
                textelement(Description) { }
                textelement(BalAccountType) { }
                textelement(BalAccountNo) { }
                textelement(DirectDebit) { }
                textelement(DirectDebitPmtTermsCode) { }

                trigger OnBeforeInsertRecord()
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    TempPaymentMethod.Init();
                    TempPaymentMethod.Code := CopyStr(Code, 1, MaxStrLen(TempPaymentMethod.Code));
                    TempPaymentMethod.Description := CopyStr(Description, 1, MaxStrLen(TempPaymentMethod.Description));
                    Evaluate(TempPaymentMethod."Bal. Account Type", BalAccountType);
                    TempPaymentMethod."Bal. Account No." := CopyStr(BalAccountNo, 1, MaxStrLen(TempPaymentMethod."Bal. Account No."));
                    Evaluate(TempPaymentMethod."Direct Debit", DirectDebit);
                    TempPaymentMethod."Direct Debit Pmt. Terms Code" := CopyStr(DirectDebitPmtTermsCode, 1, MaxStrLen(TempPaymentMethod."Direct Debit Pmt. Terms Code"));
                    TempPaymentMethod.Insert();

                    currXMLport.Skip();
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        CaptionRow := true;
        TempPaymentMethod.Reset();
        TempPaymentMethod.DeleteAll();
    end;

    procedure GetExpectedPaymentMethods(var DestTempPaymentMethod: Record "Payment Method" temporary)
    begin
        DestTempPaymentMethod.Reset();
        DestTempPaymentMethod.DeleteAll();
        if TempPaymentMethod.FindSet() then
            repeat
                DestTempPaymentMethod := TempPaymentMethod;
                DestTempPaymentMethod.Insert();
            until TempPaymentMethod.Next() = 0;
    end;

    var
        TempPaymentMethod: Record "Payment Method" temporary;
        CaptionRow: Boolean;
}
