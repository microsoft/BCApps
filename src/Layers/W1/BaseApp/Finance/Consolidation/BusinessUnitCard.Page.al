// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

using System.Environment;
using System.Telemetry;

/// <summary>
/// Provides comprehensive business unit configuration interface for consolidation setup and management.
/// Supports both database and API-based consolidation configurations with validation and testing capabilities.
/// </summary>
/// <remarks>
/// Primary user interface for configuring business units including currency settings, exchange rate accounts,
/// data import methods, and API endpoint configurations. Integrates validation and connection testing functionality.
/// </remarks>
page 241 "Business Unit Card"
{
    Caption = 'Business Unit Card';
    PageType = Card;
    SourceTable = "Business Unit";
    RefreshOnActivate = true;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the identifier for the business unit in the consolidated company.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Suite;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                }
                field("Currency Exchange Rate Table"; Rec."Currency Exchange Rate Table")
                {
                    ApplicationArea = Suite;
                }
                field(Consolidate; Rec.Consolidate)
                {
                    ApplicationArea = Suite;
                }
                field("Consolidation %"; Rec."Consolidation %")
                {
                    ApplicationArea = Suite;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Suite;
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Suite;
                }
                field("Data Source"; Rec."Data Source")
                {
                    ApplicationArea = Suite;
                }
                field("Last Run"; Rec."Last Run")
                {
                    ApplicationArea = Suite;
                }
            }
            group("Data import")
            {
                field("Default Data Import Method"; Rec."Default Data Import Method")
                {
                    ApplicationArea = Suite;
                    Visible = IsSaaS;

                    trigger OnValidate()
                    begin
                        Clear(Rec."Company Name");
                        Clear(Rec."BC API URL");
                        Clear(Rec."AAD Tenant ID");
                        Clear(Rec."External Company Id");
                        Clear(Rec."External Company Name");
                        UpdateAPISettingsVisible();
                    end;
                }
                group("DB Settings")
                {
                    ShowCaption = false;
                    Visible = not APISettingsVisible;
                    field("Company Name"; Rec."Company Name")
                    {
                        ApplicationArea = Suite;
                        ShowMandatory = true;
                    }
                }
                group("API Settings")
                {
                    ShowCaption = false;
                    Visible = APISettingsVisible;
                    field("BC API URL"; Rec."BC API URL")
                    {
                        Caption = 'API''s Endpoint';
                        ApplicationArea = Suite;
                        ShowMandatory = true;

                        trigger OnValidate()
                        var
                            ImportConsolidationFromAPI: Codeunit "Import Consolidation from API";
                        begin
                            if Rec."BC API URL" = '' then begin
                                Clear(Rec."AAD Tenant ID");
                                Clear(Rec."External Company Id");
                                Clear(Rec."External Company Name");
                                exit;
                            end;
                            if not ImportConsolidationFromAPI.ValidateBCUrl(Rec."BC API URL") then
                                Error(UrlOfBCInstanceInvalidErr);
                            Rec."AAD Tenant ID" := CopyStr(ImportConsolidationFromAPI.GetAADTenantIdFromBCUrl(Rec."BC API URL"), 1, MaxStrLen(Rec."AAD Tenant ID"));
                            ImportConsolidationFromAPI.SelectCompanyForBusinessUnit(Rec);
                        end;
                    }
                    field("BC Company Name"; Rec."External Company Name")
                    {
                        ApplicationArea = Suite;
                        Editable = false;
                    }
                    field("Log Requests"; Rec."Log Requests")
                    {
                        ApplicationArea = Suite;
                        Visible = false;
                    }
                }
                field("File Format"; Rec."File Format")
                {
                    ApplicationArea = Suite;
                }
            }
            group("G/L Accounts")
            {
                Caption = 'G/L Accounts';
                field("Exch. Rate Gains Acc."; Rec."Exch. Rate Gains Acc.")
                {
                    ApplicationArea = Suite;
                }
                field("Exch. Rate Losses Acc."; Rec."Exch. Rate Losses Acc.")
                {
                    ApplicationArea = Suite;
                }
                field("Comp. Exch. Rate Gains Acc."; Rec."Comp. Exch. Rate Gains Acc.")
                {
                    ApplicationArea = Suite;
                }
                field("Comp. Exch. Rate Losses Acc."; Rec."Comp. Exch. Rate Losses Acc.")
                {
                    ApplicationArea = Suite;
                }
                field("Equity Exch. Rate Gains Acc."; Rec."Equity Exch. Rate Gains Acc.")
                {
                    ApplicationArea = Suite;
                }
                field("Equity Exch. Rate Losses Acc."; Rec."Equity Exch. Rate Losses Acc.")
                {
                    ApplicationArea = Suite;
                }
                field("Residual Account"; Rec."Residual Account")
                {
                    ApplicationArea = Suite;
                }
                field("Minority Exch. Rate Gains Acc."; Rec."Minority Exch. Rate Gains Acc.")
                {
                    ApplicationArea = Suite;
                }
                field("Minority Exch. Rate Losses Acc"; Rec."Minority Exch. Rate Losses Acc")
                {
                    ApplicationArea = Suite;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action(ConfigureExchangeRates)
            {
                ApplicationArea = Suite;
                Caption = 'Exchange Rates';
                ToolTip = 'Edit the currency exchange rates used for this business unit in the next consolidation process.';
                Image = Currencies;
                trigger OnAction()
                var
                    ConsolidationCurrency: Codeunit "Consolidation Currency";
                begin
                    ConsolidationCurrency.ConfigureBusinessUnitCurrencies(Rec);
                    Rec.Modify();
                end;
            }
            group("&Reports")
            {
                Caption = '&Reports';
                Image = "Report";
                action(Eliminations)
                {
                    ApplicationArea = Suite;
                    Caption = 'Eliminations';
                    Ellipsis = true;
                    Image = "Report";
                    RunObject = Report "G/L Consolidation Eliminations";
                    ToolTip = 'View or edit elimination entries to remove transactions that are recorded across more than one company or remove entries involving intercompany transactions.';
                }
                action("Trial B&alance")
                {
                    ApplicationArea = Suite;
                    Caption = 'Trial B&alance';
                    Ellipsis = true;
                    Image = "Report";
                    RunObject = Report "Consolidated Trial Balance";
                    ToolTip = 'View general ledger balances and activities.';
                }
                action("Trial &Balance (4)")
                {
                    ApplicationArea = Suite;
                    Caption = 'Trial &Balance (4)';
                    Ellipsis = true;
                    Image = "Report";
                    RunObject = Report "Consolidated Trial Balance (4)";
                    ToolTip = 'View detailed general ledger balances.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Test Database")
                {
                    ApplicationArea = Suite;
                    Caption = 'Test Database (same environment)';
                    Ellipsis = true;
                    Image = TestDatabase;
                    ToolTip = 'Preview the consolidation, without transferring data.';

                    trigger OnAction()
                    begin
                        if Rec."Default Data Import Method" <> Rec."Default Data Import Method"::Database then
                            if not Confirm(ConfirmRunInAPIBusinessUnitMsg) then
                                exit;
                        Report.Run(Report::"Consolidation - Test Database");
                    end;

                }
                action("T&est File")
                {
                    ApplicationArea = Suite;
                    Caption = 'T&est File';
                    Ellipsis = true;
                    Image = TestFile;
                    RunObject = Report "Consolidation - Test File";
                    ToolTip = 'Preview the consolidation in a file, without transferring data.';
                }
                separator(Action54)
                {
                }
                action("Run Consolidation")
                {
                    ApplicationArea = Suite;
                    Caption = 'Run Consolidation (same environment)';
                    Ellipsis = true;
                    Image = ImportDatabase;
                    ToolTip = 'Run consolidation for business units in the same environment.';

                    trigger OnAction()
                    begin
                        if Rec."Default Data Import Method" <> Rec."Default Data Import Method"::Database then
                            if not Confirm(ConfirmRunInAPIBusinessUnitMsg) then
                                exit;
                        Report.Run(Report::"Import Consolidation from DB");
                    end;
                }
                action("I&mport File")
                {
                    ApplicationArea = Suite;
                    Caption = 'I&mport File';
                    Ellipsis = true;
                    Image = Import;
                    RunObject = Report "Import Consolidation from File";
                    ToolTip = 'Run consolidation for the file that you import.';
                }
                action("Export File")
                {
                    ApplicationArea = Suite;
                    Caption = 'Export File';
                    Image = Export;
                    RunObject = Report "Export Consolidation";
                    ToolTip = 'Export transactions from the business units to a file.';
                }
            }
        }
        area(Promoted)
        {
            actionref(ConfigureExchangeRates_Promoted; ConfigureExchangeRates)
            {
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    var
        UrlOfBCInstanceInvalidErr: Label 'The URL of the Business Central business unit is invalid. You can get this URL from the page "Consolidation Setup" in the other Business Central environment.';
        ConfirmRunInAPIBusinessUnitMsg: Label 'The current business unit is not set up to import data from another Business Central company in the same environment. Do you want to continue?';
        APISettingsVisible: Boolean;
        IsSaaS: Boolean;

    trigger OnOpenPage()
    var
        EnvironmentInformation: Codeunit "Environment Information";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ImportConsolidationFromAPI: Codeunit "Import Consolidation from API";
    begin
        FeatureTelemetry.LogUptake('0000KOM', ImportConsolidationFromAPI.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Discovered);
        IsSaaS := EnvironmentInformation.IsSaaS();
        UpdateAPISettingsVisible();
    end;

    local procedure UpdateAPISettingsVisible()
    begin
        APISettingsVisible := IsSaaS and (Rec."Default Data Import Method" = Rec."Default Data Import Method"::API);
    end;

}
