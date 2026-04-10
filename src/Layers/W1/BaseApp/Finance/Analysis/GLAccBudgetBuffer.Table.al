// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Budget;

/// <summary>
/// Temporary buffer table for G/L account budget analysis and reporting operations.
/// Provides structured data storage for budget calculations with dimensional filtering capabilities.
/// </summary>
/// <remarks>
/// Used by budget analysis pages and reports for temporary data processing.
/// Supports multi-dimensional budget filtering and aggregation operations.
/// Integrates with G/L Budget Entry data and dimension filtering.
/// </remarks>
table 374 "G/L Acc. Budget Buffer"
{
    Caption = 'G/L Acc. Budget Buffer';
    DataCaptionFields = "Code";
    DrillDownPageID = "Chart of Accounts";
    LookupPageID = "G/L Account List";
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// G/L account code or dimension value code used for budget analysis grouping.
        /// </summary>
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            DataClassification = SystemMetadata;
            NotBlank = true;
        }
        /// <summary>
        /// Filter for specific budget name to limit budget data analysis scope.
        /// </summary>
        field(3; "Budget Filter"; Code[10])
        {
            Caption = 'Budget Filter';
            FieldClass = FlowFilter;
            TableRelation = "G/L Budget Name";
        }
        /// <summary>
        /// Filter for specific G/L account or account range in budget analysis.
        /// </summary>
        field(4; "G/L Account Filter"; Code[20])
        {
            Caption = 'G/L Account Filter';
            FieldClass = FlowFilter;
            TableRelation = "G/L Account";
            ValidateTableRelation = false;
        }
        /// <summary>
        /// Filter for specific business unit or business unit range in budget analysis.
        /// </summary>
        field(5; "Business Unit Filter"; Code[20])
        {
            Caption = 'Business Unit Filter';
            FieldClass = FlowFilter;
            TableRelation = "Business Unit";
        }
        /// <summary>
        /// Filter for specific global dimension 1 values in budget analysis.
        /// </summary>
        field(6; "Global Dimension 1 Filter"; Code[20])
        {
            CaptionClass = '1,3,1';
            Caption = 'Global Dimension 1 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        /// <summary>
        /// Filter for specific global dimension 2 values in budget analysis.
        /// </summary>
        field(7; "Global Dimension 2 Filter"; Code[20])
        {
            CaptionClass = '1,3,2';
            Caption = 'Global Dimension 2 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        /// <summary>
        /// Filter for specific budget dimension 1 values in budget analysis.
        /// </summary>
        field(8; "Budget Dimension 1 Filter"; Code[20])
        {
            CaptionClass = GetCaptionClass(1);
            Caption = 'Budget Dimension 1 Filter';
            FieldClass = FlowFilter;
        }
        /// <summary>
        /// Filter for specific budget dimension 2 values in budget analysis.
        /// </summary>
        field(9; "Budget Dimension 2 Filter"; Code[20])
        {
            CaptionClass = GetCaptionClass(2);
            Caption = 'Budget Dimension 2 Filter';
            FieldClass = FlowFilter;
        }
        /// <summary>
        /// Filter for specific budget dimension 3 values in budget analysis.
        /// </summary>
        field(10; "Budget Dimension 3 Filter"; Code[20])
        {
            CaptionClass = GetCaptionClass(3);
            Caption = 'Budget Dimension 3 Filter';
            FieldClass = FlowFilter;
        }
        /// <summary>
        /// Filter for specific budget dimension 4 values in budget analysis.
        /// </summary>
        field(11; "Budget Dimension 4 Filter"; Code[20])
        {
            CaptionClass = GetCaptionClass(4);
            Caption = 'Budget Dimension 4 Filter';
            FieldClass = FlowFilter;
        }
        /// <summary>
        /// Filter for specific date or date range in budget analysis.
        /// </summary>
        field(12; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            ClosingDates = true;
            FieldClass = FlowFilter;
        }
        /// <summary>
        /// Calculated budgeted amount from G/L Budget Entry based on applied filters.
        /// </summary>
        field(13; "Budgeted Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            CalcFormula = sum("G/L Budget Entry".Amount where("Budget Name" = field("Budget Filter"),
                                                               "G/L Account No." = field("G/L Account Filter"),
                                                               "Business Unit Code" = field("Business Unit Filter"),
                                                               "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                               "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                               "Budget Dimension 1 Code" = field("Budget Dimension 1 Filter"),
                                                               "Budget Dimension 2 Code" = field("Budget Dimension 2 Filter"),
                                                               "Budget Dimension 3 Code" = field("Budget Dimension 3 Filter"),
                                                               "Budget Dimension 4 Code" = field("Budget Dimension 4 Filter"),
                                                               Date = field("Date Filter")));
            Caption = 'Budgeted Amount';
            FieldClass = FlowField;
        }
        /// <summary>
        /// Income or balance classification of the associated G/L account.
        /// </summary>
        field(14; "Income/Balance"; Enum "G/L Account Income/Balance")
        {
            Caption = 'Income/Balance';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Account category classification of the associated G/L account.
        /// </summary>
        field(15; "Account Category"; Enum "G/L Account Category")
        {
            Caption = 'Account Category';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        GLBudgetName: Record "G/L Budget Name";

#pragma warning disable AA0074
        Text000: Label '1,6,,Budget Dimension 1 Filter';
        Text001: Label '1,6,,Budget Dimension 2 Filter';
        Text002: Label '1,6,,Budget Dimension 3 Filter';
        Text003: Label '1,6,,Budget Dimension 4 Filter';
#pragma warning restore AA0074

    /// <summary>
    /// Retrieves caption class text for budget dimension filter fields based on budget dimension configuration.
    /// Returns appropriate caption class string for dynamic dimension field captioning.
    /// </summary>
    /// <param name="BudgetDimType">Budget dimension type number (1-4) to get caption class for</param>
    /// <returns>Caption class text for the specified budget dimension type</returns>
    procedure GetCaptionClass(BudgetDimType: Integer): Text[250]
    begin
        if GLBudgetName.Name <> GetFilter("Budget Filter") then
            GLBudgetName.Get(GetFilter("Budget Filter"));
        case BudgetDimType of
            1:
                begin
                    if GLBudgetName."Budget Dimension 1 Code" <> '' then
                        exit('1,6,' + GLBudgetName."Budget Dimension 1 Code");

                    exit(Text000);
                end;
            2:
                begin
                    if GLBudgetName."Budget Dimension 2 Code" <> '' then
                        exit('1,6,' + GLBudgetName."Budget Dimension 2 Code");

                    exit(Text001);
                end;
            3:
                begin
                    if GLBudgetName."Budget Dimension 3 Code" <> '' then
                        exit('1,6,' + GLBudgetName."Budget Dimension 3 Code");

                    exit(Text002);
                end;
            4:
                begin
                    if GLBudgetName."Budget Dimension 4 Code" <> '' then
                        exit('1,6,' + GLBudgetName."Budget Dimension 4 Code");

                    exit(Text003);
                end;
        end;
    end;
}
