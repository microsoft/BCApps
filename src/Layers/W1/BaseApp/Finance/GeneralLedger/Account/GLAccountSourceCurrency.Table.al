// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Account;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Ledger;

table 589 "G/L Account Source Currency"
{
    Caption = 'G/L Account Source Currency';
    DrillDownPageId = "Exchange Rate Adjmt. Register";
    LookupPageID = "Exchange Rate Adjmt. Register";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "G/L Account No."; Code[20])
        {
            Caption = 'G/L Account No.';
            TableRelation = "G/L Account";
        }
        field(2; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(28; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(29; "Global Dimension 1 Filter"; Code[20])
        {
            CaptionClass = '1,3,1';
            Caption = 'Global Dimension 1 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(30; "Global Dimension 2 Filter"; Code[20])
        {
            CaptionClass = '1,3,2';
            Caption = 'Global Dimension 2 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(31; "Balance at Date"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("G/L Entry".Amount where("G/L Account No." = field("G/L Account No."),
                                                        "Source Currency Code" = field("Currency Code"),
                                                        "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                        "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                        "Posting Date" = field(upperlimit("Date Filter"))));
            Caption = 'Balance at Date';
            Editable = false;
            FieldClass = FlowField;
        }
        field(75; "Source Currency Net Change"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("G/L Entry"."Source Currency Amount" where("G/L Account No." = field("G/L Account No."),
                                                                          "Source Currency Code" = field("Currency Code"),
                                                                          "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                          "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                          "Posting Date" = field("Date Filter")));
            Caption = 'Source Currency Net Change';
            Editable = false;
            FieldClass = FlowField;
        }
        field(76; "Source Curr. Balance at Date"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("G/L Entry"."Source Currency Amount" where("G/L Account No." = field("G/L Account No."),
                                                                          "Source Currency Code" = field("Currency Code"),
                                                                          "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                          "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                          "Posting Date" = field(upperlimit("Date Filter"))));
            Caption = 'Source Curr. Balance at Date';
            Editable = false;
            FieldClass = FlowField;
        }
        field(77; "Entries Exists"; Boolean)
        {
            CalcFormula = exist("G/L Entry" where("G/L Account No." = field("G/L Account No."),
                                                   "Source Currency Code" = field("Currency Code")));
            Caption = 'Entries Exists';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "G/L Account No.", "Currency Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        CalcFields("Entries Exists");
        TestField("Entries Exists", false);

        GLAccount.Get("G/L Account No.");
        if (GLAccount."Source Currency Code" = "Currency Code") and
           (GLAccount."Source Currency Posting" = GLAccount."Source Currency Posting"::"Same Currency")
        then
            error(CannotDeleteErr, "Currency Code", GLAccount.FieldCaption("Source Currency Code"), GLAccount.TableCaption);
    end;

    trigger OnInsert()
    begin
        GLAccount.Get("G/L Account No.");
        GLAccount.TestField("Source Currency Posting", GLAccount."Source Currency Posting"::"Multiple Currencies");
    end;

    trigger OnRename()
    begin
        Error(CannotRenameErr, "Currency Code");
    end;

    var
        GLAccount: Record "G/L Account";
        GLAccountSourceCurrency: Record "G/L Account Source Currency";
        CannotRenameErr: Label 'You cannot rename %1', Comment = '%1 - currency code';
        CannotDeleteErr: Label 'You cannot remove currency %1 because this currency code is set in field %2 in table %3', Comment = '%1 - currency code, %2 - field caption, %3 table caption';

    procedure BuildCurrencyList()
    var
        GLEntry: Record "G/L Entry";
        GLAccountNo: Code[20];
    begin
        if Rec.GetFilter("G/L Account No.") = '' then
            exit;

        GLAccountNo := Rec.GetRangeMin("G/L Account No.");
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        if GLEntry.FindSet() then
            repeat
                if not GLAccountSourceCurrency.Get(GLEntry."G/L Account No.", GLEntry."Source Currency Code") then
                    InsertRecord(GLEntry."G/L Account No.", GLEntry."Source Currency Code");
            until GLEntry.Next() = 0;
    end;

    procedure InsertRecord(GLAccountNo: Code[20]; CurrencyCode: Code[10])
    begin
        GLAccountSourceCurrency.Init();
        GLAccountSourceCurrency.Validate("G/L Account No.", GLAccountNo);
        GLAccountSourceCurrency.Validate("Currency Code", CurrencyCode);
        GLAccountSourceCurrency.Insert();
    end;
}
