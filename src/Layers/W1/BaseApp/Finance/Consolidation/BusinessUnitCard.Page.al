// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

using System.Environment;
using System.Telemetry;

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
                    ToolTip = 'Specifies the name of the business unit in the consolidated company.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the currency to use for this business unit during consolidation.';
                }
                field("Currency Exchange Rate Table"; Rec."Currency Exchange Rate Table")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies where to get currency exchange rates from when importing consolidation data. If you choose Local, the currency exchange rate table in the current (local) company is used. If you choose Business Unit, the currency exchange rate table in the business unit is used.';
                }
                field(Consolidate; Rec.Consolidate)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies whether to include the business unit in the Consolidation report.';
                }
                field("Consolidation %"; Rec."Consolidation %")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the percentage of each transaction for the business unit to include in the consolidation. For example, if a sales invoice is for $1000, and you specify 70%, consolidation will include $700 for the invoice. This is useful when you own only a percentage of a business unit.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the starting date of the fiscal year that the business unit uses. Enter a date only if the business unit and consolidated company have different fiscal years.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the ending date of the business unit''s fiscal year. Enter a date only if the business unit and the consolidated company have different fiscal years.';
                }
                field("Data Source"; Rec."Data Source")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies whether data is retrieved in the local currency (LCY) or the additional reporting currency (ACY) from the business unit.';
                }
                field("Last Run"; Rec."Last Run")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the last date on which consolidation was run.';
                }
            }
            group("Data import")
            {
                field("Default Data Import Method"; Rec."Default Data Import Method")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the data import method to use when importing data from the business unit. Database is for companies within the same environment and API is for companies in different environments.';
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
                        ToolTip = 'Specifies the company that will become a business unit in the consolidated company.';
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
                        ToolTip = 'Specifies the URL for the API of the Business Central company from which data will be imported. You can get this value from the page "Consolidation Setup" in the Business Central company for this business unit.';
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
                        ToolTip = 'Specifies the company name of the Business Central company from which data will be imported.';
                        Editable = false;
                    }
                    field("Log Requests"; Rec."Log Requests")
                    {
                        ApplicationArea = Suite;
                        ToolTip = 'Specifies if requests should be logged for this Business Unit on the "Consolidation Log Entry" table. This is useful for troubleshooting.';
                        Visible = false;
                    }
                }
                field("File Format"; Rec."File Format")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the file format to use for the business unit data. If the business unit has version 3.70 or earlier, it must submit a .txt file. If the version is 4.00 or later, it must use an XML file.';
                }
            }
            group("G/L Accounts")
            {
                Caption = 'G/L Accounts';
                field("Exch. Rate Gains Acc."; Rec."Exch. Rate Gains Acc.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the general ledger account that revenue gained from exchange rates during consolidation is posted to.';
                }
                field("Exch. Rate Losses Acc."; Rec."Exch. Rate Losses Acc.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the general ledger account that revenue losses due to exchange rates during consolidation are posted.';
                }
                field("Comp. Exch. Rate Gains Acc."; Rec."Comp. Exch. Rate Gains Acc.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the general ledger account where gains from exchange rates during consolidation are posted for accounts that use the Composite Rate in the Consol. Translation Method field.';
                }
                field("Comp. Exch. Rate Losses Acc."; Rec."Comp. Exch. Rate Losses Acc.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the general ledger account where losses due to exchange rates during consolidation are posted for accounts that use the Composite Rate in the Consol. Translation Method field.';
                }
                field("Equity Exch. Rate Gains Acc."; Rec."Equity Exch. Rate Gains Acc.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the general ledger account for gains from exchange rates during consolidation are posted to for accounts that use the Equity Rate. If this field is blank, the account in the Exch. Rate Gains Acc. field is used.';
                }
                field("Equity Exch. Rate Losses Acc."; Rec."Equity Exch. Rate Losses Acc.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the general ledger account where losses due to exchange rates during consolidation are posted for accounts that use the Equity Rate. If this field is blank, the account in the Exch. Rate Losses Acc. field is used.';
                }
                field("Residual Account"; Rec."Residual Account")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the general ledger account for residual amounts that occur during consolidation.';
                }
                field("Minority Exch. Rate Gains Acc."; Rec."Minority Exch. Rate Gains Acc.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the general ledger account where gains from exchange rates during consolidation are posted for business units that you do not own 100%. If this field is blank, the account in the Exch. Rate Gains Acc. field is used.';
                }
                field("Minority Exch. Rate Losses Acc"; Rec."Minority Exch. Rate Losses Acc")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the general ledger account that losses due to exchange rates during consolidation are posted to for business units that you do not own 100%. If this field is blank, the account in the Exch. Rate Losses Acc. field is used.';
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
