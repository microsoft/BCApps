// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

using Microsoft.Finance.Currency;
using System.Environment;
using System.Text;

/// <summary>
/// Displays a list of all business units configured for consolidation with management and consolidation actions.
/// Provides overview of business unit consolidation status and quick access to consolidation operations.
/// </summary>
/// <remarks>
/// Central list page for business unit management supporting batch operations like consolidation execution,
/// access management, and business unit configuration. Integrates with consolidation workflow and validation.
/// </remarks>
page 240 "Business Unit List"
{
    AdditionalSearchTerms = 'department,consolidation';
    ApplicationArea = Suite;
    Caption = 'Business Units';
    CardPageID = "Business Unit Card";
    Editable = false;
    PageType = List;
    SourceTable = "Business Unit";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the identifier for the business unit in the consolidated company.';
                }
                field("Company Name"; CompanyName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Company Name';
                    ToolTip = 'Specifies the company that will become a business unit in the consolidated company.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    LookupPageID = Currencies;
                }
                field("Currency Exchange Rate Table"; Rec."Currency Exchange Rate Table")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Data Source"; Rec."Data Source")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field(Consolidate; Rec.Consolidate)
                {
                    ApplicationArea = Suite;
                }
                field("Consolidation %"; Rec."Consolidation %")
                {
                    ApplicationArea = Suite;
                    Editable = true;
                }
                field("Exch. Rate Gains Acc."; Rec."Exch. Rate Gains Acc.")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Exch. Rate Losses Acc."; Rec."Exch. Rate Losses Acc.")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Residual Account"; Rec."Residual Account")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Suite;
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Suite;
                }
                field("File Format"; Rec."File Format")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Last Run"; Rec."Last Run")
                {
                    ApplicationArea = Suite;
                }
                field(LastConsolidationEndingDate; LastConsolidationEndingDate)
                {
                    ApplicationArea = Suite;
                    Caption = 'Last Consolidation Ending Date';
                    ToolTip = 'Specifies the ending date of the last consolidation run for this business unit.';
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
                    if Rec.IsEmpty() then
                        Error(CreateBusinessUnitFirstErr);
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
                    RunObject = Report "Consolidation - Test Database";
                    ToolTip = 'Preview the consolidation, without transferring data.';
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
                separator(Action43)
                {
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
                action(StartConsolidation)
                {
                    ApplicationArea = Suite;
                    Caption = 'Consolidate';
                    Ellipsis = true;
                    Image = LaunchWeb;
                    ToolTip = 'Consolidate the configured business units.';

                    trigger OnAction()
                    begin
                        Page.Run(Page::"Consolidate Wizard");
                    end;
                }
                action(ConsolidationsInProgress)
                {
                    ApplicationArea = Suite;
                    Caption = 'Consolidation runs status';
                    Image = JobJournal;
                    ToolTip = 'Shows the consolidation runs.';
                    RunObject = Page "Consolidations in Progress";
                }
                action(Setup)
                {
                    ApplicationArea = Suite;
                    Caption = 'Setup';
                    Image = Setup;
                    Tooltip = 'Setup of the consolidation parameters';
                    RunObject = Page "Consolidation Setup";
                    Visible = IsSaaS;
                }
            }
        }
        area(Promoted)
        {
            actionref(ConfigureExchangeRates_Promoted; ConfigureExchangeRates)
            {
            }
            actionref(Setup_Promoted; Setup)
            {
            }
            actionref(StartConsolidation_Promoted; StartConsolidation)
            {
            }
        }
    }

    var
        ConsolidateBusinessUnits: Codeunit "Consolidate Business Units";
        CompanyName: Text;
        LastConsolidationEndingDate: Date;
        IsSaaS: Boolean;
        CreateBusinessUnitFirstErr: Label 'You need to create a Business Unit first to configure its exchange rates.';

    trigger OnOpenPage()
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        IsSaaS := EnvironmentInformation.IsSaaS();
    end;

    trigger OnAfterGetRecord()
    begin
        if Rec."Default Data Import Method" = Rec."Default Data Import Method"::Database then
            CompanyName := Rec."Company Name";
        if Rec."Default Data Import Method" = Rec."Default Data Import Method"::API then
            CompanyName := Rec."External Company Name";
        LastConsolidationEndingDate := ConsolidateBusinessUnits.GetLastConsolidationEndingDate(Rec);
    end;

    /// <summary>
    /// Returns a selection filter text for currently selected business units on the page.
    /// Used for filtering operations based on user selection in the business unit list.
    /// </summary>
    /// <returns>Filter text representing selected business unit codes</returns>
    procedure GetSelectionFilter(): Text
    var
        BusUnit: Record "Business Unit";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        CurrPage.SetSelectionFilter(BusUnit);
        exit(SelectionFilterManagement.GetSelectionFilterForBusinessUnit(BusUnit));
    end;
}
