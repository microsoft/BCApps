// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14Reimplementation;

xmlport 148911 "BC14 Vendor Bank Acct Data"
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
            tableelement(BC14VendorBankAccount; "BC14 Vendor Bank Account")
            {
                AutoSave = false;
                XmlName = 'BC14VendorBankAccount';

                textelement(VendorNo) { }
                textelement(CodeValue) { }
                textelement(Name) { }
                textelement(BankAccountNo) { }
                textelement(CurrencyCode) { }
                textelement(IBANValue) { }
                textelement(SWIFTCode) { }

                trigger OnBeforeInsertRecord()
                var
                    NewBC14VendBankAccount: Record "BC14 Vendor Bank Account";
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    NewBC14VendBankAccount.Init();
                    NewBC14VendBankAccount."Vendor No." := CopyStr(VendorNo, 1, MaxStrLen(NewBC14VendBankAccount."Vendor No."));
                    NewBC14VendBankAccount.Code := CopyStr(CodeValue, 1, MaxStrLen(NewBC14VendBankAccount.Code));
                    NewBC14VendBankAccount.Name := CopyStr(Name, 1, MaxStrLen(NewBC14VendBankAccount.Name));
                    NewBC14VendBankAccount."Bank Account No." := CopyStr(BankAccountNo, 1, MaxStrLen(NewBC14VendBankAccount."Bank Account No."));
                    NewBC14VendBankAccount."Currency Code" := CopyStr(CurrencyCode, 1, MaxStrLen(NewBC14VendBankAccount."Currency Code"));
                    NewBC14VendBankAccount.IBAN := CopyStr(IBANValue, 1, MaxStrLen(NewBC14VendBankAccount.IBAN));
                    NewBC14VendBankAccount."SWIFT Code" := CopyStr(SWIFTCode, 1, MaxStrLen(NewBC14VendBankAccount."SWIFT Code"));
                    NewBC14VendBankAccount.Insert();

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
