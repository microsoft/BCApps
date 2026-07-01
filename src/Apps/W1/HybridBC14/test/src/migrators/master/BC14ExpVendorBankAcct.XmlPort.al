// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.Purchases.Vendor;

xmlport 148912 "BC14 Exp Vendor Bank Acct"
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
            tableelement(VendorBankAccount; "Vendor Bank Account")
            {
                AutoSave = false;
                XmlName = 'VendorBankAccount';

                textelement(VendorNo) { }
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

                    TempVendBankAccount.Init();
                    TempVendBankAccount."Vendor No." := CopyStr(VendorNo, 1, MaxStrLen(TempVendBankAccount."Vendor No."));
                    TempVendBankAccount.Code := CopyStr(CodeValue, 1, MaxStrLen(TempVendBankAccount.Code));
                    TempVendBankAccount.Name := CopyStr(Name, 1, MaxStrLen(TempVendBankAccount.Name));
                    TempVendBankAccount."Bank Account No." := CopyStr(BankAccountNo, 1, MaxStrLen(TempVendBankAccount."Bank Account No."));
                    TempVendBankAccount."Currency Code" := CopyStr(CurrencyCode, 1, MaxStrLen(TempVendBankAccount."Currency Code"));
                    TempVendBankAccount.IBAN := CopyStr(IBANValue, 1, MaxStrLen(TempVendBankAccount.IBAN));
                    TempVendBankAccount."SWIFT Code" := CopyStr(SWIFTCode, 1, MaxStrLen(TempVendBankAccount."SWIFT Code"));
                    TempVendBankAccount.Insert();

                    currXMLport.Skip();
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        CaptionRow := true;
        TempVendBankAccount.Reset();
        TempVendBankAccount.DeleteAll();
    end;

    procedure GetExpectedVendorBankAccounts(var DestTemp: Record "Vendor Bank Account" temporary)
    begin
        DestTemp.Reset();
        DestTemp.DeleteAll();
        if TempVendBankAccount.FindSet() then
            repeat
                DestTemp := TempVendBankAccount;
                DestTemp.Insert();
            until TempVendBankAccount.Next() = 0;
    end;

    var
        TempVendBankAccount: Record "Vendor Bank Account" temporary;
        CaptionRow: Boolean;
}
