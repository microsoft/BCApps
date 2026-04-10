// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using System.Environment;

/// <summary>
/// Defines business units for consolidation processes with subsidiary companies and foreign currency handling.
/// Contains configuration for currency conversion factors, exchange rate accounts, and data import methods.
/// </summary>
/// <remarks>
/// Core table for multi-company consolidation supporting database and API-based data import.
/// Integrates with G/L Account structure for exchange rate handling and residual account management.
/// Extensibility: OnBeforeValidate and OnAfterModify events available for custom business logic.
/// </remarks>
table 220 "Business Unit"
{
    Caption = 'Business Unit';
    LookupPageID = "Business Unit List";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique identifier for the business unit used across consolidation processes.
        /// </summary>
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            ToolTip = 'Specifies the code of the business unit.';
            NotBlank = true;
        }
        /// <summary>
        /// Determines whether this business unit should be included in consolidation runs.
        /// </summary>
        field(2; Consolidate; Boolean)
        {
            Caption = 'Consolidate';
            ToolTip = 'Specifies whether to include the business unit in the Consolidation report.';
            InitValue = true;
        }
        /// <summary>
        /// Percentage of ownership to consolidate for this business unit, typically 100% for full consolidation.
        /// </summary>
        field(3; "Consolidation %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Consolidation %';
            ToolTip = 'Specifies the percentage of each transaction for the business unit to include in the consolidation. For example, if a sales invoice is for $1000, and you specify 70%, consolidation will include $700 for the invoice. This is useful when you own only a percentage of a business unit.';
            DecimalPlaces = 0 : 5;
            InitValue = 100;
            MaxValue = 100;
            MinValue = 0;
        }
        /// <summary>
        /// Start date for the consolidation period for this business unit.
        /// </summary>
        field(4; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            ToolTip = 'Specifies the starting date of the fiscal year that the business unit uses. Enter a date only if the business unit and consolidated company have different fiscal years.';
        }
        /// <summary>
        /// End date for the consolidation period for this business unit.
        /// </summary>
        field(5; "Ending Date"; Date)
        {
            Caption = 'Ending Date';
            ToolTip = 'Specifies the ending date of the business unit''s fiscal year. Enter a date only if the business unit and the consolidated company have different fiscal years.';
        }
        /// <summary>
        /// Exchange rate factor used for converting income statement amounts from subsidiary currency.
        /// </summary>
        field(6; "Income Currency Factor"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Income Currency Factor';
            ToolTip = 'Specifies the exchange rate to use for balance sheet accounts.';
            DecimalPlaces = 0 : 15;
            Editable = false;
            InitValue = 1;
            MinValue = 0;
        }
        /// <summary>
        /// Exchange rate factor used for converting balance sheet amounts from subsidiary currency.
        /// </summary>
        field(7; "Balance Currency Factor"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Balance Currency Factor';
            ToolTip = 'Specifies the exchange rate to use for income statement accounts.';
            DecimalPlaces = 0 : 15;
            Editable = false;
            InitValue = 1;
            MinValue = 0;
        }
        /// <summary>
        /// G/L Account for posting exchange rate losses during consolidation currency conversion.
        /// </summary>
        field(8; "Exch. Rate Losses Acc."; Code[20])
        {
            Caption = 'Exch. Rate Losses Acc.';
            ToolTip = 'Specifies the general ledger account that revenue losses due to exchange rates during consolidation are posted.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Exch. Rate Losses Acc.");
            end;
        }
        /// <summary>
        /// G/L Account for posting exchange rate gains during consolidation currency conversion.
        /// </summary>
        field(9; "Exch. Rate Gains Acc."; Code[20])
        {
            Caption = 'Exch. Rate Gains Acc.';
            ToolTip = 'Specifies the general ledger account that revenue gained from exchange rates during consolidation is posted to.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Exch. Rate Gains Acc.");
            end;
        }
        /// <summary>
        /// G/L Account for posting residual amounts that cannot be allocated during consolidation.
        /// </summary>
        field(10; "Residual Account"; Code[20])
        {
            Caption = 'Residual Account';
            ToolTip = 'Specifies the general ledger account for residual amounts that occur during consolidation.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Residual Account");
            end;
        }
        /// <summary>
        /// Balance currency factor from the previous consolidation run for comparison purposes.
        /// </summary>
        field(11; "Last Balance Currency Factor"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Last Balance Currency Factor';
            ToolTip = 'Specifies the last closing currency factor used in the previous reconciliation. This will be used to adjust the balance entries.';
            DecimalPlaces = 0 : 15;
            Editable = false;
            InitValue = 1;
        }
        /// <summary>
        /// Descriptive name for the business unit for identification purposes.
        /// </summary>
        field(12; Name; Text[100])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the name of the business unit in the consolidated company.';
        }
        /// <summary>
        /// Name of the company that corresponds to this business unit in database-based imports.
        /// </summary>
        field(13; "Company Name"; Text[30])
        {
            Caption = 'Company Name';
            ToolTip = 'Specifies the company that will become a business unit in the consolidated company.';
            TableRelation = Company.Name;
            ValidateTableRelation = false;
            trigger OnValidate()
            begin
                if Rec."Default Data Import Method" <> Rec."Default Data Import Method"::Database then
                    exit;
                if Rec.Name <> '' then
                    exit;
                Rec.Name := Rec."Company Name";
            end;
        }
        /// <summary>
        /// Currency code used by the subsidiary business unit for currency conversion during consolidation.
        /// </summary>
        field(14; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            ToolTip = 'Specifies the currency to use for this business unit during consolidation.';
            TableRelation = Currency;

            trigger OnValidate()
            var
                CurrencyFactor: Decimal;
            begin
                WarnIfDifferentCurrencyUsedForPreviousConsolidation(Rec."Currency Code");
                if "Currency Exchange Rate Table" = "Currency Exchange Rate Table"::"Business Unit" then
                    CurrencyFactor := GetCurrencyFactorFromBusinessUnit()
                else
                    CurrencyFactor := CurrExchRate.ExchangeRate(WorkDate(), "Currency Code");

                "Income Currency Factor" := CurrencyFactor;
                "Balance Currency Factor" := CurrencyFactor;
            end;
        }
        /// <summary>
        /// G/L Account for posting exchange rate gains on comprehensive income accounts during consolidation.
        /// </summary>
        field(15; "Comp. Exch. Rate Gains Acc."; Code[20])
        {
            Caption = 'Comp. Exch. Rate Gains Acc.';
            ToolTip = 'Specifies the general ledger account where gains from exchange rates during consolidation are posted for accounts that use the Composite Rate in the Consol. Translation Method field.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Comp. Exch. Rate Gains Acc.");
            end;
        }
        /// <summary>
        /// G/L Account for posting exchange rate losses on comprehensive income accounts during consolidation.
        /// </summary>
        field(16; "Comp. Exch. Rate Losses Acc."; Code[20])
        {
            Caption = 'Comp. Exch. Rate Losses Acc.';
            ToolTip = 'Specifies the general ledger account where losses due to exchange rates during consolidation are posted for accounts that use the Composite Rate in the Consol. Translation Method field.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Comp. Exch. Rate Losses Acc.");
            end;
        }
        /// <summary>
        /// G/L Account for posting exchange rate gains on equity accounts during consolidation.
        /// </summary>
        field(17; "Equity Exch. Rate Gains Acc."; Code[20])
        {
            Caption = 'Equity Exch. Rate Gains Acc.';
            ToolTip = 'Specifies the general ledger account for gains from exchange rates during consolidation are posted to for accounts that use the Equity Rate. If this field is blank, the account in the Exch. Rate Gains Acc. field is used.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Equity Exch. Rate Gains Acc.");
            end;
        }
        /// <summary>
        /// G/L Account for posting exchange rate losses on equity accounts during consolidation.
        /// </summary>
        field(18; "Equity Exch. Rate Losses Acc."; Code[20])
        {
            Caption = 'Equity Exch. Rate Losses Acc.';
            ToolTip = 'Specifies the general ledger account where losses due to exchange rates during consolidation are posted for accounts that use the Equity Rate. If this field is blank, the account in the Exch. Rate Losses Acc. field is used.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Equity Exch. Rate Losses Acc.");
            end;
        }
        /// <summary>
        /// G/L Account for posting exchange rate gains on minority interest accounts during consolidation.
        /// </summary>
        field(19; "Minority Exch. Rate Gains Acc."; Code[20])
        {
            Caption = 'Minority Exch. Rate Gains Acc.';
            ToolTip = 'Specifies the general ledger account where gains from exchange rates during consolidation are posted for business units that you do not own 100%. If this field is blank, the account in the Exch. Rate Gains Acc. field is used.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Minority Exch. Rate Gains Acc.");
            end;
        }
        /// <summary>
        /// G/L Account for posting exchange rate losses on minority interest accounts during consolidation.
        /// </summary>
        field(20; "Minority Exch. Rate Losses Acc"; Code[20])
        {
            Caption = 'Minority Exch. Rate Losses Acc';
            ToolTip = 'Specifies the general ledger account that losses due to exchange rates during consolidation are posted to for business units that you do not own 100%. If this field is blank, the account in the Exch. Rate Losses Acc. field is used.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Minority Exch. Rate Losses Acc");
            end;
        }
        /// <summary>
        /// Determines whether to use local currency exchange rates or business unit specific rates for conversion.
        /// </summary>
        field(21; "Currency Exchange Rate Table"; Option)
        {
            AccessByPermission = TableData Currency = R;
            Caption = 'Currency Exchange Rate Table';
            ToolTip = 'Specifies where to get currency exchange rates from when importing consolidation data. If you choose Local, the currency exchange rate table in the current (local) company is used. If you choose Business Unit, the currency exchange rate table in the business unit is used.';
            OptionCaption = 'Local,Business Unit';
            OptionMembers = "Local","Business Unit";

            trigger OnValidate()
            begin
                Validate("Currency Code");
            end;
        }
        /// <summary>
        /// Specifies whether to consolidate using local currency or additional reporting currency amounts.
        /// </summary>
        field(22; "Data Source"; Option)
        {
            Caption = 'Data Source';
            ToolTip = 'Specifies whether data is retrieved in the local currency (LCY) or the additional reporting currency (ACY) from the business unit.';
            OptionCaption = 'Local Curr. (LCY),Add. Rep. Curr. (ACY)';
            OptionMembers = "Local Curr. (LCY)","Add. Rep. Curr. (ACY)";
        }
        /// <summary>
        /// File format used for importing consolidation data from external files.
        /// </summary>
        field(23; "File Format"; Enum "Business Unit File Format")
        {
            Caption = 'File Format';
            ToolTip = 'Specifies the file format to use for the business unit data. If the business unit has version 3.70 or earlier, it must submit a .txt file. If the version is 4.00 or later, it must use an XML file.';
        }
        /// <summary>
        /// Date of the last consolidation run executed for this business unit.
        /// </summary>
        field(24; "Last Run"; Date)
        {
            Caption = 'Last Run';
            ToolTip = 'Specifies the last date on which consolidation was run.';
        }
        /// <summary>
        /// Default method for importing consolidation data, either from database or API endpoint.
        /// </summary>
        field(25; "Default Data Import Method"; Option)
        {
            Caption = 'Default Data Import Method';
            ToolTip = 'Specifies the data import method to use when importing data from the business unit. Database is for companies within the same environment and API is for companies in different environments.';
            OptionCaption = 'Database,API';
            OptionMembers = "Database","API";
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// URL endpoint for the Business Central API when using API-based data import method.
        /// </summary>
        field(26; "BC API URL"; Text[2048])
        {
            ToolTip = 'Specifies the URL for the API of the Business Central company from which data will be imported. You can get this value from the page "Consolidation Setup" in the Business Central company for this business unit.';
            Caption = 'BC API URL', Comment = 'URL of the API of the external Business Central instance';
            DataClassification = OrganizationIdentifiableInformation;
        }
        /// <summary>
        /// Microsoft Entra tenant identifier for authenticating API connections to external Business Central.
        /// </summary>
        field(27; "AAD Tenant ID"; Guid)
        {
            Caption = 'Microsoft Entra tenant ID';
            DataClassification = OrganizationIdentifiableInformation;
        }
        /// <summary>
        /// Unique identifier of the external company when using API-based consolidation import.
        /// </summary>
        field(28; "External Company Id"; Guid)
        {
            Caption = 'External Company Id';
            DataClassification = OrganizationIdentifiableInformation;
        }
        /// <summary>
        /// Name of the external company corresponding to this business unit for API-based imports.
        /// </summary>
        field(29; "External Company Name"; Text[1024])
        {
            Caption = 'External Company Name';
            ToolTip = 'Specifies the company name of the Business Central company from which data will be imported.';
            DataClassification = OrganizationIdentifiableInformation;
            trigger OnValidate()
            begin
                if Rec."Default Data Import Method" <> Rec."Default Data Import Method"::API then
                    exit;
                if Rec.Name <> '' then
                    exit;
                Rec.Name := CopyStr(Rec."External Company Name", 1, MaxStrLen(Rec.Name));
            end;
        }
        /// <summary>
        /// Enables logging of API requests for debugging and audit purposes during consolidation data import.
        /// </summary>
        field(30; "Log Requests"; Boolean)
        {
            Caption = 'Log Requests';
            ToolTip = 'Specifies if requests should be logged for this Business Unit on the "Consolidation Log Entry" table. This is useful for troubleshooting.';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
        key(Key2; "Company Name")
        {
        }
    }

    fieldgroups
    {
    }

    var
        CurrExchRate: Record "Currency Exchange Rate";
        UnsupportedDataImportMethodErr: Label 'Unsupported data import method.';
        DifferentCurrenciesHaveBeenUsedInPreviousConsolidationsForBusinessUnitsErr: Label 'Different currencies have been used in previous consolidations for this business unit. Changing it may have an impact in currency adjustments. Do you want to continue?';

    /// <summary>
    /// Validates that the specified G/L Account exists and is properly configured for consolidation use.
    /// </summary>
    /// <param name="AccNo">G/L Account number to validate</param>
    procedure CheckGLAcc(AccNo: Code[20])
    var
        GLAcc: Record "G/L Account";
    begin
        if AccNo <> '' then begin
            GLAcc.Get(AccNo);
            GLAcc.CheckGLAcc();
        end;
    end;

    local procedure GetCurrencyFactorFromBusinessUnit(): Decimal
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ImportConsolidationFromAPI: Codeunit "Import Consolidation from API";
        CurrencyFactor: Decimal;
    begin
        CurrencyFactor := 1;
        if Rec."Currency Code" = '' then
            exit(CurrencyFactor);

        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.TestField("LCY Code");

        if Rec."Default Data Import Method" = Rec."Default Data Import Method"::Database then
            exit(GetCurrencyFactorFromBusinessUnitDB());
        if Rec."Default Data Import Method" = Rec."Default Data Import Method"::API then
            exit(ImportConsolidationFromAPI.GetCurrencyFactorFromBusinessUnit(Rec));
        Error(UnsupportedDataImportMethodErr);
    end;

    local procedure GetCurrencyFactorFromBusinessUnitDB(): Decimal
    var
        GLSetup: Record "General Ledger Setup";
        CurrencyFactor: Decimal;
        DummyDate: Date;
    begin
        GLSetup.Get();
        CurrExchRate.ChangeCompany("Company Name");
        CurrExchRate.SetRange("Starting Date", 0D, WorkDate());
        CurrExchRate.GetLastestExchangeRate(GLSetup."LCY Code", DummyDate, CurrencyFactor);
        exit(CurrencyFactor);
    end;

    local procedure WarnIfDifferentCurrencyUsedForPreviousConsolidation(CurrencyCode: Code[10])
    var
        BusUnitInConsProcess: Record "Bus. Unit In Cons. Process";
    begin
        if not GuiAllowed() then
            exit;
        BusUnitInConsProcess.SetRange("Business Unit Code", Rec.Code);
        BusUnitInConsProcess.SetFilter("Currency Code", '<> %1', CurrencyCode);
        BusUnitInConsProcess.SetRange(Status, BusUnitInConsProcess.Status::Finished);
        if not BusUnitInConsProcess.IsEmpty() then
            if not Confirm(DifferentCurrenciesHaveBeenUsedInPreviousConsolidationsForBusinessUnitsErr) then
                Error('');
    end;

}
