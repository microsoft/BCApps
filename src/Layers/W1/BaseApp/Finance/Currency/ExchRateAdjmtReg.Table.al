// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Currency;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Payables;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;

/// <summary>
/// Maintains a register of exchange rate adjustment runs for audit and tracking purposes.
/// Records details of each adjustment process including date ranges, account types processed,
/// and statistical information about the adjustments performed.
/// </summary>
/// <remarks>
/// Linked to Exchange Rate Adjustment Ledger Entries for detailed transaction tracking.
/// Provides drill-down capabilities to view specific adjustments and supports
/// audit trail requirements for currency revaluation procedures.
/// </remarks>
table 86 "Exch. Rate Adjmt. Reg."
{
    Caption = 'Exch. Rate Adjmt. Reg.';
    DrillDownPageId = "Exchange Rate Adjmt. Register";
    LookupPageID = "Exchange Rate Adjmt. Register";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Integer)
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
        }
        field(2; "Creation Date"; Date)
        {
            Caption = 'Creation Date';
            ToolTip = 'Specifies the posting date for the exchange rate adjustment register.';
        }
        field(3; "Account Type"; Enum "Exch. Rate Adjmt. Account Type")
        {
            Caption = 'Account Type';
            ToolTip = 'Specifies the account type that was adjusted for exchange rate fluctuations when you ran the Adjust Exchange Rates batch job.';
        }
        field(4; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            ToolTip = 'Specifies the posting group of the exchange rate adjustment register on this line.';
            TableRelation = if ("Account Type" = const(Customer)) "Customer Posting Group"
            else
            if ("Account Type" = const(Vendor)) "Vendor Posting Group"
            else
            if ("Account Type" = const("Bank Account")) "Bank Account Posting Group"
            else
            if ("Account Type" = const(Employee)) "Employee Posting Group";

        }
        field(5; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            ToolTip = 'Specifies the code for the currency whose exchange rate was adjusted.';
            TableRelation = Currency;
        }
        field(6; "Currency Factor"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Currency Factor';
            DecimalPlaces = 0 : 15;
            MinValue = 0;
        }
        field(7; "Adjusted Base"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Adjusted Base';
            ToolTip = 'Specifies the amount that was adjusted by the batch job for customer, vendor and/or bank ledger entries.';
        }
        field(8; "Adjusted Base (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Adjusted Base (LCY)';
        }
        field(9; "Adjusted Amt. (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Adjusted Amt. (LCY)';
        }
        field(10; "Adjusted Base (Add.-Curr.)"; Decimal)
        {
            AccessByPermission = TableData Currency = R;
            AutoFormatExpression = GetCurrencyCodeFromGLSetup();
            AutoFormatType = 1;
            Caption = 'Adjusted Base (Add.-Curr.)';
        }
        field(11; "Adjusted Amt. (Add.-Curr.)"; Decimal)
        {
            AccessByPermission = TableData Currency = R;
            AutoFormatExpression = GetCurrencyCodeFromGLSetup();
            AutoFormatType = 1;
            Caption = 'Adjusted Amt. (Add.-Curr.)';
        }
        field(14; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
        }
        field(15; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
        }
        field(21; "Adjusted Customers"; Integer)
        {
            Caption = 'No. of Adj. Cust. Ledger Entries';
            ToolTip = 'Specifies the number of customer ledger entries with remaining amount that was adjusted.';
            CalcFormula = count("Detailed Cust. Ledg. Entry" where("Exch. Rate Adjmt. Reg. No." = field("No.")));
            Editable = false;
            FieldClass = FlowField;
        }
        field(22; "Adjusted Vendors"; Integer)
        {
            Caption = 'No. of Adj. Vend. Ledger Entries';
            ToolTip = 'Specifies the number of vendor ledger entries with remaining amount that was adjusted.';
            CalcFormula = count("Detailed Vendor Ledg. Entry" where("Exch. Rate Adjmt. Reg. No." = field("No.")));
            Editable = false;
            FieldClass = FlowField;
        }
        field(23; "Adjustment Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Adjustment Amount';
            ToolTip = 'Specifies the total adjustment amount of exchange rate adjustment ledger entries.';
            CalcFormula = sum("Exch. Rate Adjmt. Ledg. Entry"."Adjustment Amount" where("Register No." = field("No.")));
            Editable = false;
            FieldClass = FlowField;
        }
        field(24; "Adjusted Employees"; Integer)
        {
            Caption = 'No. of Adj. Empl. Ledger Entries';
            ToolTip = 'Specifies the number of emplooyee ledger entries with remaining amount that was adjusted.';
            CalcFormula = count("Detailed Employee Ledger Entry" where("Exch. Rate Adjmt. Reg. No." = field("No.")));
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        ExchRateAdjmtLedgEntry: Record "Exch. Rate Adjmt. Ledg. Entry";
    begin
        ExchRateAdjmtLedgEntry.SetRange("Register No.", "No.");
        ExchRateAdjmtLedgEntry.DeleteAll();
    end;

    local procedure GetCurrencyCodeFromGLSetup(): Code[10]
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        exit(GLSetup."Additional Reporting Currency");
    end;
}
