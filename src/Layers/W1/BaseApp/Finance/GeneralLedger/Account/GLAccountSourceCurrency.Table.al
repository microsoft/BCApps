// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Account;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Ledger;

/// <summary>
/// Tracks source currency balances and transactions for general ledger accounts that support multi-currency operations.
/// Provides detailed currency-specific balance information for accounts configured with source currency posting.
/// </summary>
/// <remarks>
/// Key relationships: G/L Account, Currency, G/L Entry with source currency amounts.
/// Used for multi-currency accounting scenarios where accounts maintain balances in specific currencies.
/// Supports dimensional analysis and date-filtered balance calculations for source currency amounts.
/// Enables currency-specific reporting and exchange rate adjustment processes.
/// </remarks>
table 589 "G/L Account Source Currency"
{
    Caption = 'G/L Account Source Currency';
    DrillDownPageId = "Exchange Rate Adjmt. Register";
    LookupPageID = "Exchange Rate Adjmt. Register";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// General ledger account number that supports source currency posting and multi-currency transactions.
        /// </summary>
        field(1; "G/L Account No."; Code[20])
        {
            Caption = 'G/L Account No.';
            TableRelation = "G/L Account";
        }
        /// <summary>
        /// Currency code for the source currency used in transactions for this account.
        /// </summary>
        field(2; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            ToolTip = 'Specifies the source currency code.';
            TableRelation = Currency;
        }
        /// <summary>
        /// Date range filter for calculating currency-specific balance amounts in flowfields.
        /// </summary>
        field(28; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        /// <summary>
        /// Filter for first global dimension to restrict currency balance calculations to specific dimension values.
        /// </summary>
        field(29; "Global Dimension 1 Filter"; Code[20])
        {
            CaptionClass = '1,3,1';
            Caption = 'Global Dimension 1 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        /// <summary>
        /// Filter for second global dimension to restrict currency balance calculations to specific dimension values.
        /// </summary>
        field(30; "Global Dimension 2 Filter"; Code[20])
        {
            CaptionClass = '1,3,2';
            Caption = 'Global Dimension 2 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        /// <summary>
        /// Account balance in local currency as of the specified date filter for this source currency combination.
        /// </summary>
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
            ToolTip = 'Specifies the account balance in local currency.';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Net change amount in source currency for the account within the specified date filter period.
        /// </summary>
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
        /// <summary>
        /// Account balance in source currency as of the specified date filter for exchange rate analysis.
        /// </summary>
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
            ToolTip = 'Specifies the account balance in source currency.';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Indicates whether general ledger entries exist for this account and currency combination.
        /// </summary>
        field(77; "Entries Exists"; Boolean)
        {
            CalcFormula = exist("G/L Entry" where("G/L Account No." = field("G/L Account No."),
                                                   "Source Currency Code" = field("Currency Code")));
            Caption = 'Entries Exists';
            ToolTip = 'Specifies if general ledger entries with this source currency code exists.';
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

    /// <summary>
    /// Builds a complete list of source currency records for a general ledger account based on existing entries.
    /// Scans all general ledger entries for the filtered account and creates source currency records as needed.
    /// </summary>
    /// <remarks>
    /// Creates missing source currency records for currencies found in general ledger entries.
    /// Requires a G/L Account No. filter to be set before calling this procedure.
    /// Used to initialize source currency tracking for accounts with multi-currency transactions.
    /// </remarks>
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

    /// <summary>
    /// Creates a new source currency record for the specified general ledger account and currency combination.
    /// Initializes the record with proper validation for account and currency relationships.
    /// </summary>
    /// <param name="GLAccountNo">General ledger account number for the source currency record</param>
    /// <param name="CurrencyCode">Currency code for the source currency configuration</param>
    procedure InsertRecord(GLAccountNo: Code[20]; CurrencyCode: Code[10])
    begin
        GLAccountSourceCurrency.Init();
        GLAccountSourceCurrency.Validate("G/L Account No.", GLAccountNo);
        GLAccountSourceCurrency.Validate("Currency Code", CurrencyCode);
        GLAccountSourceCurrency.Insert();
    end;
}
