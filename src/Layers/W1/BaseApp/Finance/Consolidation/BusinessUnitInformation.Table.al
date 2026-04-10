// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

using Microsoft.Finance.GeneralLedger.Account;

/// <summary>
/// Stores business unit metadata and configuration settings imported from external consolidation sources.
/// Contains temporary information used during consolidation data import processes.
/// </summary>
/// <remarks>
/// Support table for consolidation import workflows providing business unit context and configuration.
/// Used primarily during data import processes to validate and map external business unit settings.
/// </remarks>
table 1828 "Business Unit Information"
{
    Caption = 'Business Unit Information';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique identifier for the business unit from external consolidation data source.
        /// </summary>
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
        }
        /// <summary>
        /// Descriptive name for the business unit imported from external source.
        /// </summary>
        field(2; Name; Text[30])
        {
            Caption = 'Name';
        }
        /// <summary>
        /// Company name associated with the business unit in the external data source.
        /// </summary>
        field(3; "Company Name"; Text[30])
        {
            Caption = 'Company Name';
        }
        /// <summary>
        /// Currency code used by the business unit in the external consolidation system.
        /// </summary>
        field(4; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
        }
        /// <summary>
        /// Exchange rate table source configuration imported from external business unit settings.
        /// </summary>
        field(5; "Currency Exchange Rate Table"; Option)
        {
            Caption = 'Currency Exchange Rate Table';
            OptionCaption = 'Local,Business Unit';
            OptionMembers = "Local","Business Unit";
        }
        /// <summary>
        /// Starting date for the consolidation period defined in external business unit configuration.
        /// </summary>
        field(6; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
        }
        /// <summary>
        /// Ending date for the consolidation period defined in external business unit configuration.
        /// </summary>
        field(7; "Ending Date"; Date)
        {
            Caption = 'Ending Date';
        }
        /// <summary>
        /// G/L Account for exchange rate gains imported from external business unit setup.
        /// </summary>
        field(8; "Exch. Rate Gains Acc."; Code[20])
        {
            Caption = 'Exch. Rate Gains Acc.';
        }
        /// <summary>
        /// G/L Account for exchange rate losses imported from external business unit setup.
        /// </summary>
        field(9; "Exch. Rate Losses Acc."; Code[20])
        {
            Caption = 'Exch. Rate Losses Acc.';
        }
        /// <summary>
        /// G/L Account for residual amounts imported from external business unit configuration.
        /// </summary>
        field(10; "Residual Account"; Code[20])
        {
            Caption = 'Residual Account';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Residual Account");
            end;
        }
        /// <summary>
        /// G/L Account for comprehensive income exchange rate gains imported from external setup.
        /// </summary>
        field(11; "Comp. Exch. Rate Gains Acc."; Code[20])
        {
            Caption = 'Comp. Exch. Rate Gains Acc.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Comp. Exch. Rate Gains Acc.");
            end;
        }
        /// <summary>
        /// G/L Account for comprehensive income exchange rate losses imported from external setup.
        /// </summary>
        field(12; "Comp. Exch. Rate Losses Acc."; Code[20])
        {
            Caption = 'Comp. Exch. Rate Losses Acc.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Comp. Exch. Rate Losses Acc.");
            end;
        }
        /// <summary>
        /// G/L Account for equity exchange rate gains imported from external business unit setup.
        /// </summary>
        field(13; "Equity Exch. Rate Gains Acc."; Code[20])
        {
            Caption = 'Equity Exch. Rate Gains Acc.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Equity Exch. Rate Gains Acc.");
            end;
        }
        /// <summary>
        /// G/L Account for equity exchange rate losses imported from external business unit setup.
        /// </summary>
        field(14; "Equity Exch. Rate Losses Acc."; Code[20])
        {
            Caption = 'Equity Exch. Rate Losses Acc.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Equity Exch. Rate Losses Acc.");
            end;
        }
        /// <summary>
        /// G/L Account for minority interest exchange rate gains imported from external setup.
        /// </summary>
        field(15; "Minority Exch. Rate Gains Acc."; Code[20])
        {
            Caption = 'Minority Exch. Rate Gains Acc.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Minority Exch. Rate Gains Acc.");
            end;
        }
        /// <summary>
        /// G/L Account for minority interest exchange rate losses imported from external setup.
        /// </summary>
        field(16; "Minority Exch. Rate Losses Acc"; Code[20])
        {
            Caption = 'Minority Exch. Rate Losses Acc';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Minority Exch. Rate Losses Acc");
            end;
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

    local procedure CheckGLAcc(AccNo: Code[20])
    var
        GLAcc: Record "G/L Account";
    begin
        if AccNo <> '' then begin
            GLAcc.Get(AccNo);
            GLAcc.CheckGLAcc();
        end;
    end;
}

