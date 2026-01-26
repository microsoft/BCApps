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
        }
        /// <summary>
        /// Description text displayed on VAT statement reports and forms.
        /// </summary>
        field(5; Description; Text[100])
        {
            Caption = 'Description';
        }
        /// <summary>
        /// Type of VAT statement line determining calculation and processing behavior.
        /// </summary>
        field(6; Type; Enum "VAT Statement Line Type")
        {
            Caption = 'Type';

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
        }
        /// <summary>
        /// VAT business posting group filter for selecting relevant VAT entries.
        /// </summary>
        field(9; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        /// <summary>
        /// VAT product posting group filter for selecting relevant VAT entries.
        /// </summary>
        field(10; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        /// <summary>
        /// Row numbers to total when this line is a row totaling type.
        /// </summary>
        field(11; "Row Totaling"; Text[50])
        {
            Caption = 'Row Totaling';
        }
        /// <summary>
        /// Type of amount to calculate from VAT entries or G/L entries.
        /// </summary>
        field(12; "Amount Type"; Enum "VAT Statement Line Amount Type")
        {
            Caption = 'Amount Type';
        }
        /// <summary>
        /// Sign calculation method for amounts displayed on the VAT statement.
        /// </summary>
        field(13; "Calculate with"; Option)
        {
            Caption = 'Calculate with';
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
            InitValue = true;
        }
        /// <summary>
        /// Sign used when printing amounts on VAT statement reports.
        /// </summary>
        field(15; "Print with"; Option)
        {
            Caption = 'Print with';
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
        }
        /// <summary>
        /// Tax jurisdiction code for sales tax calculations in localized scenarios.
        /// </summary>
        field(18; "Tax Jurisdiction Code"; Code[10])
        {
            Caption = 'Tax Jurisdiction Code';
            TableRelation = "Tax Jurisdiction";
        }
        /// <summary>
        /// Indicates if this line should include use tax entries in calculations.
        /// </summary>
        field(19; "Use Tax"; Boolean)
        {
            Caption = 'Use Tax';
        }
        /// <summary>
        /// Box number or field identifier used for electronic VAT return filing.
        /// </summary>
        field(20; "Box No."; Text[30])
        {
            Caption = 'Box No.';
        }
        field(11600; "BAS Adjustment"; Boolean)
        {
            Caption = 'BAS Adjustment';
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

