// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.Sales.Customer;

xmlport 148910 "BC14 Exp Customer Bank Acct"
{
    Direction = Import;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(CustomerBankAccount; "Customer Bank Account")
            {
                AutoSave = false;
                XmlName = 'CustomerBankAccount';

                textelement(CustomerNo) { }
                textelement(CodeValue) { }
                textelement(Name) { }
                textelement(BankAccountNo) { }
                textelement(CurrencyCode) { }
                textelement(IBANValue) { }
                textelement(SWIFTCode) { }

                trigger OnBeforeInsertRecord()
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    TempCustBankAccount.Init();
                    TempCustBankAccount."Customer No." := CopyStr(CustomerNo, 1, MaxStrLen(TempCustBankAccount."Customer No."));
                    TempCustBankAccount.Code := CopyStr(CodeValue, 1, MaxStrLen(TempCustBankAccount.Code));
                    TempCustBankAccount.Name := CopyStr(Name, 1, MaxStrLen(TempCustBankAccount.Name));
                    TempCustBankAccount."Bank Account No." := CopyStr(BankAccountNo, 1, MaxStrLen(TempCustBankAccount."Bank Account No."));
                    TempCustBankAccount."Currency Code" := CopyStr(CurrencyCode, 1, MaxStrLen(TempCustBankAccount."Currency Code"));
                    TempCustBankAccount.IBAN := CopyStr(IBANValue, 1, MaxStrLen(TempCustBankAccount.IBAN));
                    TempCustBankAccount."SWIFT Code" := CopyStr(SWIFTCode, 1, MaxStrLen(TempCustBankAccount."SWIFT Code"));
                    TempCustBankAccount.Insert();

                    currXMLport.Skip();
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        CaptionRow := true;
        TempCustBankAccount.Reset();
        TempCustBankAccount.DeleteAll();
    end;

    procedure GetExpectedCustomerBankAccounts(var DestTemp: Record "Customer Bank Account" temporary)
    begin
        DestTemp.Reset();
        DestTemp.DeleteAll();
        if TempCustBankAccount.FindSet() then
            repeat
                DestTemp := TempCustBankAccount;
                DestTemp.Insert();
            until TempCustBankAccount.Next() = 0;
    end;

    var
        TempCustBankAccount: Record "Customer Bank Account" temporary;
        CaptionRow: Boolean;
}
