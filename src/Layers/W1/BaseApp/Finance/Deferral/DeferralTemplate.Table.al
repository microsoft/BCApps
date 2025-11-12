// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Deferral;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Resources.Resource;
using System.Telemetry;

/// <summary>
/// Master data table that defines deferral templates for deferred revenue and expense recognition.
/// Templates specify calculation methods, periods, and G/L accounts used to create deferral schedules.
/// </summary>
table 1700 "Deferral Template"
{
    Caption = 'Deferral Template';
    LookupPageID = "Deferral Template List";
    ReplicateData = true;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique identifier for the deferral template.
        /// </summary>
        field(1; "Deferral Code"; Code[10])
        {
            Caption = 'Deferral Code';
            NotBlank = true;
        }
        /// <summary>
        /// Descriptive text explaining the purpose and use of this deferral template.
        /// </summary>
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        /// <summary>
        /// G/L Account number where deferred amounts will be temporarily stored before recognition.
        /// Must be a posting account that is not blocked.
        /// </summary>
        field(3; "Deferral Account"; Code[20])
        {
            Caption = 'Deferral Account';
            NotBlank = true;
            TableRelation = "G/L Account" where("Account Type" = const(Posting),
                                                 Blocked = const(false));
        }
        /// <summary>
        /// Percentage of the source amount to defer (0-100%).
        /// Default is 100% which defers the entire amount.
        /// </summary>
        field(4; "Deferral %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Deferral %';
            DecimalPlaces = 0 : 5;
            InitValue = 100;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                if ("Deferral %" <= 0) or ("Deferral %" > 100) then
                    Error(DeferralPercentageErr);
            end;
        }
        /// <summary>
        /// Method used to calculate deferral amounts across periods (Straight-Line, Equal per Period, etc.).
        /// </summary>
        field(5; "Calc. Method"; Enum "Deferral Calculation Method")
        {
            Caption = 'Calc. Method';
        }
        /// <summary>
        /// Determines when the deferral schedule starts (Posting Date, Beginning of Period, etc.).
        /// </summary>
        field(6; "Start Date"; Enum "Deferral Calculation Start Date")
        {
            Caption = 'Start Date';
        }
        /// <summary>
        /// Number of accounting periods over which the deferral will be recognized.
        /// Must be at least 1 period.
        /// </summary>
        field(7; "No. of Periods"; Integer)
        {
            BlankZero = true;
            Caption = 'No. of Periods';
            MinValue = 1;

            trigger OnValidate()
            begin
                if "No. of Periods" < 1 then
                    Error(NumberofPeriodsErr);
            end;
        }
        /// <summary>
        /// Default description template for individual deferral schedule lines.
        /// Can include placeholders that are replaced when creating schedules.
        /// </summary>
        field(8; "Period Description"; Text[100])
        {
            Caption = 'Period Description';
        }
    }

    keys
    {
        key(Key1; "Deferral Code")
        {
            Clustered = true;
        }
        key(Key2; "Deferral Account")
        {
            MaintainSIFTIndex = false;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        GLAccount: Record "G/L Account";
        Item: Record Item;
        Resource: Record Resource;
    begin
        GLAccount.SetRange("Default Deferral Template Code", "Deferral Code");
        if GLAccount.FindFirst() then
            Error(CannotDeleteCodeErr, "Deferral Code", GLAccount.TableCaption(), GLAccount."No.");

        Item.SetRange("Default Deferral Template Code", "Deferral Code");
        if Item.FindFirst() then
            Error(CannotDeleteCodeErr, "Deferral Code", Item.TableCaption(), Item."No.");

        Resource.SetRange("Default Deferral Template Code", "Deferral Code");
        if Resource.FindFirst() then
            Error(CannotDeleteCodeErr, "Deferral Code", Resource.TableCaption(), Resource."No.");
    end;

    trigger OnInsert()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUptake('0000KLE', 'Deferral', Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000KLF', 'Deferral', 'Deferral Created');
    end;

    var
        CannotDeleteCodeErr: Label '%1 cannot be deleted because it is set as the default deferral template code for %2 %3.', Comment = '%1=Value of code that is attempting to be deleted;%2=Table caption;%3=Value for the code in the table';
        DeferralPercentageErr: Label 'The deferral percentage must be greater than 0 and less than 100.';
        NumberofPeriodsErr: Label 'You must specify one or more periods.';
}
