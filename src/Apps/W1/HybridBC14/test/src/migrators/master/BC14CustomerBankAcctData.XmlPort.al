// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14Reimplementation;

xmlport 148909 "BC14 Customer Bank Acct Data"
{
    Direction = Both;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(BC14CustomerBankAccount; "BC14 Customer Bank Account")
            {
                AutoSave = false;
                XmlName = 'BC14CustomerBankAccount';

                textelement(CustomerNo) { }
                textelement(CodeValue) { }
                textelement(Name) { }
                textelement(BankAccountNo) { }
                textelement(CurrencyCode) { }
                textelement(IBANValue) { }
                textelement(SWIFTCode) { }

                trigger OnBeforeInsertRecord()
                var
                    NewBC14CustBankAccount: Record "BC14 Customer Bank Account";
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    NewBC14CustBankAccount.Init();
                    NewBC14CustBankAccount."Customer No." := CopyStr(CustomerNo, 1, MaxStrLen(NewBC14CustBankAccount."Customer No."));
                    NewBC14CustBankAccount.Code := CopyStr(CodeValue, 1, MaxStrLen(NewBC14CustBankAccount.Code));
                    NewBC14CustBankAccount.Name := CopyStr(Name, 1, MaxStrLen(NewBC14CustBankAccount.Name));
                    NewBC14CustBankAccount."Bank Account No." := CopyStr(BankAccountNo, 1, MaxStrLen(NewBC14CustBankAccount."Bank Account No."));
                    NewBC14CustBankAccount."Currency Code" := CopyStr(CurrencyCode, 1, MaxStrLen(NewBC14CustBankAccount."Currency Code"));
                    NewBC14CustBankAccount.IBAN := CopyStr(IBANValue, 1, MaxStrLen(NewBC14CustBankAccount.IBAN));
                    NewBC14CustBankAccount."SWIFT Code" := CopyStr(SWIFTCode, 1, MaxStrLen(NewBC14CustBankAccount."SWIFT Code"));
                    NewBC14CustBankAccount.Insert();

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
