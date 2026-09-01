// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14Reimplementation;

xmlport 148907 "BC14 GL Account Data"
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
            tableelement(BC14GLAccount; "BC14 G/L Account")
            {
                AutoSave = false;
                XmlName = 'BC14GLAccount';

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
                var
                    NewBC14GLAccount: Record "BC14 G/L Account";
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    NewBC14GLAccount.Init();
                    NewBC14GLAccount."No." := CopyStr(No, 1, MaxStrLen(NewBC14GLAccount."No."));
                    NewBC14GLAccount.Name := CopyStr(Name, 1, MaxStrLen(NewBC14GLAccount.Name));
                    Evaluate(NewBC14GLAccount."Account Type", AccountType);
                    Evaluate(NewBC14GLAccount."Income/Balance", IncomeBalance);
                    Evaluate(NewBC14GLAccount."Debit/Credit", DebitCredit);
                    Evaluate(NewBC14GLAccount.Blocked, BlockedValue);
                    Evaluate(NewBC14GLAccount."Direct Posting", DirectPosting);
                    Evaluate(NewBC14GLAccount."Account Category", AccountCategory);
                    Evaluate(NewBC14GLAccount."Account Subcategory Entry No.", AccountSubcategoryEntryNo);
                    NewBC14GLAccount.Insert();

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
