// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Ledger;

using Microsoft.Finance.VAT.Ledger;
using Microsoft.Foundation.NoSeries;
using Microsoft.HumanResources.Payables;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;

/// <summary>
/// Provides sequential numbering for all G/L Transaction entries.
/// </summary>
table 57 "G/L Transaction"
{
    Caption = 'G/L Transaction';
    DataClassification = SystemMetadata;
    DrillDownPageId = "G/L Transactions";
    LookupPageId = "G/L Transactions";
    Permissions = TableData "G/L Transaction" = ri;

    fields
    {
        /// <summary>
        /// Sequential register number for G/L Transaction entries.
        /// </summary>
        field(1; "No."; Integer)
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the general ledger register.';
        }
        /// <summary>
        /// Contains the sequential register number for G/L Transaction entry.
        /// </summary>
        field(2; "G/L Register No."; Integer)
        {
            Caption = 'G/L Register No.';
            ToolTip = 'Specifies the number of the general ledger register.';
        }
        /// <summary>
        /// Contains the outstanding balance that has not yet been applied or paid, expressed in local currency.
        /// </summary>
        field(5; "No. of G/L Entries"; Integer)
        {
            CalcFormula = count("G/L Entry" where("Transaction No." = field("No.")));
            Caption = 'G/L Entries';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the number of general ledger entries in this transaction.';
        }
        field(6; "No. of VAT Entries"; Integer)
        {
            CalcFormula = count("VAT Entry" where("Transaction No." = field("No.")));
            Caption = 'VAT Entries';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the number of VAT entries in this transaction.';
        }
        field(7; "No. of Customer Ledger Entries"; Integer)
        {
            CalcFormula = count("Cust. Ledger Entry" where("Transaction No." = field("No.")));
            Caption = 'Customer Ledger Entries';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the number of customer ledger entries in this transaction.';
        }
        field(8; "No. of Vendor Ledger Entries"; Integer)
        {
            CalcFormula = count("Vendor Ledger Entry" where("Transaction No." = field("No.")));
            Caption = 'Vendor Ledger Entries';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the number of vendor ledger entries in this transaction.';
        }
        field(9; "No. of Employee Ledger Entries"; Integer)
        {
            CalcFormula = count("Employee Ledger Entry" where("Transaction No." = field("No.")));
            Caption = 'Employee Ledger Entries';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the number of employee ledger entries in this transaction.';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "G/L Register No.", "No.")
        {
        }
    }

    trigger OnInsert()
    begin
        TestField("G/L Register No.");
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"G/L Transaction", 'r')]
    procedure GetNextTransactionNo(): Integer
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        exit(SequenceNoMgt.GetNextSeqNo(Database::"G/L Transaction"));
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"G/L Entry", 'r')]
    [InherentPermissions(PermissionObjectType::TableData, Database::"G/L Transaction", 'i')]
    procedure InsertFromGLEntry(var GLEntry: Record "G/L Entry"; var GLRegisterNo: Record "G/L Register")
    begin
        GLEntry.TestField("Transaction No.");
        GLEntry.TestField("G/L Register No.");

        if Rec.Get(GLEntry."Transaction No.") then
            exit;

        Init();
        "No." := GLEntry."Transaction No.";
        "G/L Register No." := GLRegisterNo."No.";
        Insert();
    end;
}
