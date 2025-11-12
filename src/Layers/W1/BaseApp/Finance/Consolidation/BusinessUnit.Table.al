// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using System.Environment;

table 220 "Business Unit"
{
    Caption = 'Business Unit';
    LookupPageID = "Business Unit List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Consolidate; Boolean)
        {
            Caption = 'Consolidate';
            InitValue = true;
        }
        field(3; "Consolidation %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Consolidation %';
            DecimalPlaces = 0 : 5;
            InitValue = 100;
            MaxValue = 100;
            MinValue = 0;
        }
        field(4; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
        }
        field(5; "Ending Date"; Date)
        {
            Caption = 'Ending Date';
        }
        field(6; "Income Currency Factor"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Income Currency Factor';
            DecimalPlaces = 0 : 15;
            Editable = false;
            InitValue = 1;
            MinValue = 0;
        }
        field(7; "Balance Currency Factor"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Balance Currency Factor';
            DecimalPlaces = 0 : 15;
            Editable = false;
            InitValue = 1;
            MinValue = 0;
        }
        field(8; "Exch. Rate Losses Acc."; Code[20])
        {
            Caption = 'Exch. Rate Losses Acc.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Exch. Rate Losses Acc.");
            end;
        }
        field(9; "Exch. Rate Gains Acc."; Code[20])
        {
            Caption = 'Exch. Rate Gains Acc.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Exch. Rate Gains Acc.");
            end;
        }
        field(10; "Residual Account"; Code[20])
        {
            Caption = 'Residual Account';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Residual Account");
            end;
        }
        field(11; "Last Balance Currency Factor"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Last Balance Currency Factor';
            DecimalPlaces = 0 : 15;
            Editable = false;
            InitValue = 1;
        }
        field(12; Name; Text[100])
        {
            Caption = 'Name';
        }
        field(13; "Company Name"; Text[30])
        {
            Caption = 'Company Name';
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
        field(14; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
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
        field(15; "Comp. Exch. Rate Gains Acc."; Code[20])
        {
            Caption = 'Comp. Exch. Rate Gains Acc.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Comp. Exch. Rate Gains Acc.");
            end;
        }
        field(16; "Comp. Exch. Rate Losses Acc."; Code[20])
        {
            Caption = 'Comp. Exch. Rate Losses Acc.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Comp. Exch. Rate Losses Acc.");
            end;
        }
        field(17; "Equity Exch. Rate Gains Acc."; Code[20])
        {
            Caption = 'Equity Exch. Rate Gains Acc.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Equity Exch. Rate Gains Acc.");
            end;
        }
        field(18; "Equity Exch. Rate Losses Acc."; Code[20])
        {
            Caption = 'Equity Exch. Rate Losses Acc.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Equity Exch. Rate Losses Acc.");
            end;
        }
        field(19; "Minority Exch. Rate Gains Acc."; Code[20])
        {
            Caption = 'Minority Exch. Rate Gains Acc.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Minority Exch. Rate Gains Acc.");
            end;
        }
        field(20; "Minority Exch. Rate Losses Acc"; Code[20])
        {
            Caption = 'Minority Exch. Rate Losses Acc';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Minority Exch. Rate Losses Acc");
            end;
        }
        field(21; "Currency Exchange Rate Table"; Option)
        {
            AccessByPermission = TableData Currency = R;
            Caption = 'Currency Exchange Rate Table';
            OptionCaption = 'Local,Business Unit';
            OptionMembers = "Local","Business Unit";

            trigger OnValidate()
            begin
                Validate("Currency Code");
            end;
        }
        field(22; "Data Source"; Option)
        {
            Caption = 'Data Source';
            OptionCaption = 'Local Curr. (LCY),Add. Rep. Curr. (ACY)';
            OptionMembers = "Local Curr. (LCY)","Add. Rep. Curr. (ACY)";
        }
        field(23; "File Format"; Enum "Business Unit File Format")
        {
            Caption = 'File Format';
        }
        field(24; "Last Run"; Date)
        {
            Caption = 'Last Run';
        }
        field(25; "Default Data Import Method"; Option)
        {
            Caption = 'Default Data Import Method';
            OptionCaption = 'Database,API';
            OptionMembers = "Database","API";
            DataClassification = SystemMetadata;
        }
        field(26; "BC API URL"; Text[2048])
        {
            Caption = 'BC API URL', Comment = 'URL of the API of the external Business Central instance';
            DataClassification = OrganizationIdentifiableInformation;
        }
        field(27; "AAD Tenant ID"; Guid)
        {
            Caption = 'Microsoft Entra tenant ID';
            DataClassification = OrganizationIdentifiableInformation;
        }
        field(28; "External Company Id"; Guid)
        {
            Caption = 'External Company Id';
            DataClassification = OrganizationIdentifiableInformation;
        }
        field(29; "External Company Name"; Text[1024])
        {
            Caption = 'External Company Name';
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
        field(30; "Log Requests"; Boolean)
        {
            Caption = 'Log Requests';
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
