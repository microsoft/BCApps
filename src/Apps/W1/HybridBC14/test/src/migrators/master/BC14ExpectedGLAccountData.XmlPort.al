// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.Finance.GeneralLedger.Account;

xmlport 148908 "BC14 Expected GL Account Data"
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
            tableelement(GLAccount; "G/L Account")
            {
                AutoSave = false;
                XmlName = 'GLAccount';

                textelement(No) { }
                textelement(Name) { }
                textelement(AccountType) { }
                textelement(IncomeBalance) { }
                textelement(DebitCredit) { }
                textelement(BlockedValue) { }
                textelement(DirectPosting) { }
                textelement(AccountCategory) { }
                textelement(AccountSubcategoryEntryNo) { }

                trigger OnBeforeInsertRecord()
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    TempGLAccount.Init();
                    TempGLAccount."No." := CopyStr(No, 1, MaxStrLen(TempGLAccount."No."));
                    TempGLAccount.Name := CopyStr(Name, 1, MaxStrLen(TempGLAccount.Name));
                    Evaluate(TempGLAccount."Account Type", AccountType);
                    Evaluate(TempGLAccount."Income/Balance", IncomeBalance);
                    Evaluate(TempGLAccount."Debit/Credit", DebitCredit);
                    Evaluate(TempGLAccount.Blocked, BlockedValue);
                    Evaluate(TempGLAccount."Direct Posting", DirectPosting);
                    Evaluate(TempGLAccount."Account Category", AccountCategory);
                    Evaluate(TempGLAccount."Account Subcategory Entry No.", AccountSubcategoryEntryNo);
                    TempGLAccount.Insert();

                    currXMLport.Skip();
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        CaptionRow := true;
        TempGLAccount.Reset();
        TempGLAccount.DeleteAll();
    end;

    procedure GetExpectedGLAccounts(var DestTempGLAccount: Record "G/L Account" temporary)
    begin
        DestTempGLAccount.Reset();
        DestTempGLAccount.DeleteAll();
        if TempGLAccount.FindSet() then
            repeat
                DestTempGLAccount := TempGLAccount;
                DestTempGLAccount.Insert();
            until TempGLAccount.Next() = 0;
    end;

    var
        TempGLAccount: Record "G/L Account" temporary;
        CaptionRow: Boolean;
}
