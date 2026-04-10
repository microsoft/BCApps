// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Enums;

/// <summary>
/// Line definitions for VAT statement configurations used in VAT reporting and calculations.
/// Defines calculation rules, totaling formulas, and line types for generating VAT statement reports.
/// </summary>
table 256 "VAT Statement Line"
{
    Caption = 'VAT Statement Line';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Template name identifying the VAT statement structure and configuration.
        /// </summary>
        field(1; "Statement Template Name"; Code[10])
        {
            Caption = 'Statement Template Name';
            TableRelation = "VAT Statement Template";
        }
        /// <summary>
        /// Statement name within the template used for organizing related VAT calculation lines.
        /// </summary>
        field(2; "Statement Name"; Code[10])
        {
            Caption = 'Statement Name';
            TableRelation = "VAT Statement Name".Name where("Statement Template Name" = field("Statement Template Name"));
        }
        /// <summary>
        /// Line number for ordering and referencing lines within the VAT statement.
        /// </summary>
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        /// <summary>
        /// Row number displayed on VAT statement reports for line identification.
        /// </summary>
        field(4; "Row No."; Code[10])
        {
            Caption = 'Row No.';
            ToolTip = 'Specifies a number that identifies the line.';
        }
        /// <summary>
        /// Description text displayed on VAT statement reports and forms.
        /// </summary>
        field(5; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the VAT statement line.';
        }
        /// <summary>
        /// Type of VAT statement line determining calculation and processing behavior.
        /// </summary>
        field(6; Type; Enum "VAT Statement Line Type")
        {
            Caption = 'Type';
            ToolTip = 'Specifies what the VAT statement line will include.';

            trigger OnValidate()
            begin
                if Type <> xRec.Type then begin
                    TempType := Type;
                    Init();
                    "Statement Template Name" := xRec."Statement Template Name";
                    "Statement Name" := xRec."Statement Name";
                    "Line No." := xRec."Line No.";
                    "Row No." := xRec."Row No.";
                    Description := xRec.Description;
                    Type := TempType;
                end;
            end;
        }
        /// <summary>
        /// G/L account range or filter for calculating VAT amounts from posted entries.
        /// </summary>
        field(7; "Account Totaling"; Text[30])
        {
            Caption = 'Account Totaling';
            ToolTip = 'Specifies an account interval or a series of account numbers.';
            TableRelation = "G/L Account";
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                if "Account Totaling" <> '' then begin
                    GLAcc.SetFilter("No.", "Account Totaling");
                    GLAcc.SetFilter("Account Type", '<> 0');
                    if GLAcc.FindFirst() then
                        GLAcc.TestField("Account Type", GLAcc."Account Type"::Posting);
                end;
            end;
        }
        /// <summary>
        /// General posting type filter for VAT entry selection during calculation.
        /// </summary>
        field(8; "Gen. Posting Type"; Enum "General Posting Type")
        {
            Caption = 'Gen. Posting Type';
            ToolTip = 'Specifies the type of transaction.';
        }
        /// <summary>
        /// VAT business posting group filter for selecting relevant VAT entries.
        /// </summary>
        field(9; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            ToolTip = 'Specifies the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
            TableRelation = "VAT Business Posting Group";
        }
        /// <summary>
        /// VAT product posting group filter for selecting relevant VAT entries.
        /// </summary>
        field(10; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            ToolTip = 'Specifies the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
            TableRelation = "VAT Product Posting Group";
        }
        /// <summary>
        /// Row numbers to total when this line is a row totaling type.
        /// </summary>
        field(11; "Row Totaling"; Text[50])
        {
            Caption = 'Row Totaling';
            ToolTip = 'Specifies a row-number interval or a series of row numbers.';
        }
        /// <summary>
        /// Type of amount to calculate from VAT entries or G/L entries.
        /// </summary>
        field(12; "Amount Type"; Enum "VAT Statement Line Amount Type")
        {
            Caption = 'Amount Type';
            ToolTip = 'Specifies if the VAT statement line shows the VAT amounts, or the base amounts on which the VAT is calculated.';
        }
        /// <summary>
        /// Sign calculation method for amounts displayed on the VAT statement.
        /// </summary>
        field(13; "Calculate with"; Option)
        {
            Caption = 'Calculate with';
            ToolTip = 'Specifies whether amounts on the VAT statement will be calculated with their original sign or with the sign reversed.';
            OptionCaption = 'Sign,Opposite Sign';
            OptionMembers = Sign,"Opposite Sign";

            trigger OnValidate()
            begin
                if ("Calculate with" = "Calculate with"::"Opposite Sign") and (Type = Type::"Row Totaling") then
                    FieldError(Type, StrSubstNo(Text000, Type));
            end;
        }
        /// <summary>
        /// Controls whether this line should be included in printed VAT statement reports.
        /// </summary>
        field(14; Print; Boolean)
        {
            Caption = 'Print';
            ToolTip = 'Specifies whether the VAT statement line will be printed on the report that contains the finished VAT statement.';
            InitValue = true;
        }
        /// <summary>
        /// Sign used when printing amounts on VAT statement reports.
        /// </summary>
        field(15; "Print with"; Option)
        {
            Caption = 'Print with';
            ToolTip = 'Specifies whether amounts on the VAT statement will be printed with their original sign or with the sign reversed.';
            OptionCaption = 'Sign,Opposite Sign';
            OptionMembers = Sign,"Opposite Sign";
        }
        /// <summary>
        /// Date filter applied during VAT entry calculations for this line.
        /// </summary>
        field(16; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            Editable = false;
            FieldClass = FlowFilter;
        }
        /// <summary>
        /// Forces a page break before this line when printing VAT statement reports.
        /// </summary>
        field(17; "New Page"; Boolean)
        {
            Caption = 'New Page';
            ToolTip = 'Specifies whether a new page should begin immediately after this line when the VAT statement is printed. To start a new page after this line, place a check mark in the field.';
        }
        /// <summary>
        /// Tax jurisdiction code for sales tax calculations in localized scenarios.
        /// </summary>
        field(18; "Tax Jurisdiction Code"; Code[10])
        {
            Caption = 'Tax Jurisdiction Code';
            ToolTip = 'Specifies a tax jurisdiction code for the statement.';
            TableRelation = "Tax Jurisdiction";
        }
        /// <summary>
        /// Indicates if this line should include use tax entries in calculations.
        /// </summary>
        field(19; "Use Tax"; Boolean)
        {
            Caption = 'Use Tax';
            ToolTip = 'Specifies whether to use only entries from the VAT Entry table that are marked as Use Tax to be totaled on this line.';
        }
        /// <summary>
        /// Box number or field identifier used for electronic VAT return filing.
        /// </summary>
        field(20; "Box No."; Text[30])
        {
            Caption = 'Box No.';
            ToolTip = 'Specifies the number on the box that the VAT statement applies to.';
        }
    }

    keys
    {
        key(Key1; "Statement Template Name", "Statement Name", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        GLAcc: Record "G/L Account";
        TempType: Enum "VAT Statement Line Type";

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'must not be %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
}

