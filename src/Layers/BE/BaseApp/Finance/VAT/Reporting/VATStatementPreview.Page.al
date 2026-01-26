// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Foundation.Address;
using System.Text;

/// <summary>
/// Interactive preview interface for VAT statement calculations with parameter adjustment capabilities.
/// Provides real-time calculation preview with configurable periods, selection criteria, and currency options.
/// </summary>
#pragma warning disable AS0106 // Protected variable VATDateType was removed before AS0106 was introduced.
page 474 "VAT Statement Preview"
#pragma warning restore AS0106
{
    Caption = 'VAT Statement Preview';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPlus;
    SaveValues = true;
    SourceTable = "VAT Statement Name";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(Selection; Selection)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Include VAT entries';
                    ToolTip = 'Specifies that VAT entries are included in the VAT Statement Preview window. This only works for lines of type VAT Entry Totaling. It does not work for lines of type Account Totaling.';

                    trigger OnValidate()
                    begin
                        if Selection = Selection::"Open and Closed" then
                            OpenandClosedSelectionOnValida();
                        if Selection = Selection::Closed then
                            ClosedSelectionOnValidate();
                        if Selection = Selection::Open then
                            OpenSelectionOnValidate();
                    end;
                }
                field(PeriodSelection; PeriodSelection)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Include VAT entries';
                    ToolTip = 'Specifies that VAT entries are included in the VAT Statement Preview window. This only works for lines of type VAT Entry Totaling. It does not work for lines of type Account Totaling.';

                    trigger OnValidate()
                    begin
                        if PeriodSelection = PeriodSelection::"Before and Within Period" then
                            BeforeandWithinPeriodSelection();
                        if PeriodSelection = PeriodSelection::"Within Period" then
                            WithinPeriodPeriodSelectionOnV();
                    end;
                }
                field(UseAmtsInAddCurr; UseAmtsInAddCurr)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Amounts in Add. Reporting Currency';
                    MultiLine = true;
                    ToolTip = 'Specifies that the VAT Statement Preview window shows amounts in the additional reporting currency.';

                    trigger OnValidate()
                    begin
                        UseAmtsInAddCurrOnPush();
                    end;
                }
                field(DateFilter; DateFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Date Filter';
                    ToolTip = 'Specifies the dates that will be used to filter the amounts in the window.';

                    trigger OnValidate()
                    var
                        FilterTokens: Codeunit "Filter Tokens";
                    begin
                        FilterTokens.MakeDateFilter(DateFilter);
                        Rec.SetFilter("Date Filter", DateFilter);
                        UpdateSubForm();
                        CurrPage.Update();
                    end;
                }
                field("Country/Region Filter"; CountryRegionFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Country/Region Filter';
                    ToolTip = 'Specifies the country/region to filter the VAT entries.';
                    Importance = Additional;

                    trigger OnValidate()
                    begin
                        UpdateSubForm();
                        CurrPage.Update();
                    end;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        CountryRegion: Record "Country/Region";
                        CountriesRegions: Page "Countries/Regions";
                    begin
                        CountriesRegions.LookupMode(true);
                        if CountriesRegions.RunModal() = Action::LookupOK then begin
                            CountriesRegions.GetRecord(CountryRegion);
                            CountryRegionFilter := CountryRegion.Code;
                            exit(true);
                        end;
                        exit(false);
                    end;
                }
            }
            part(VATStatementLineSubForm; "VAT Statement Preview Line")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Statement Template Name" = field("Statement Template Name"),
                              "Statement Name" = field(Name);
                SubPageView = sorting("Statement Template Name", "Statement Name", "Line No.");
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
        area(reporting)
        {
            action(DetailedReport)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Detailed Report';
                Ellipsis = true;
                Image = VATStatement;
                ToolTip = 'View a statement of posted VAT and calculates the duty liable to the customs authorities for the selected period. The report is printed on the basis of the definition of the VAT statement in the VAT Statement Line table. The report can be used in connection with VAT settlement to the customs authorities and for your own documentation.';

                trigger OnAction()
                begin
                    RunReport(REPORT::"VAT Statement")
                end;
            }
            action(FormIntervatDeclaration)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Form/Intervat Declaration';
                Ellipsis = true;
                Image = ExportElectronicDocument;
                RunObject = Report "VAT - Form";
                ToolTip = 'Send monthly or quarterly VAT declarations to an XML file. You can choose to print your VAT declaration and send the printed document to your tax authorities or you can send an electronic VAT declaration via the internet using Intervat. Note: This report is based on the VAT Statement template that is defined in the general ledger setup. Therefore, it may export data that is not the same as what is shown in the VAT Statement Preview window.';
            }
            action(DeclarationSummaryReport)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Declaration Summary Report';
                Ellipsis = true;
                Image = VATLedger;
                ToolTip = 'View a summary of the VAT declarations for different accounting periods. You can also use the report to verify the amounts in the different VAT rows. For example, you can check if the sum of two rows equals the amount in another row.';

                trigger OnAction()
                begin
                    RunReport(REPORT::"VAT Statement Summary");
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Reports';

                actionref(DetailedReport_Promoted; DetailedReport)
                {
                }
                actionref(FormIntervatDeclaration_Promoted; FormIntervatDeclaration)
                {
                }
                actionref(DeclarationSummaryReport_Promoted; DeclarationSummaryReport)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateSubForm();
    end;

    trigger OnOpenPage()
    begin
        if ValuesPassed then begin
            Selection := PassedSelection;
            PeriodSelection := PassedPeriodSelection;
            DateFilter := PassedDateFilter;
            Rec.SetFilter("Date Filter", PassedDateFilter);
        end else
            DateFilter := '';
        UpdateSubForm();
    end;

    var
        PassedSelection: Enum "VAT Statement Report Selection";
        PassedPeriodSelection: Enum "VAT Statement Report Period Selection";
        PassedDateFilter: Text[30];
        ValuesPassed: Boolean;

    protected var
        Selection: Enum "VAT Statement Report Selection";
        PeriodSelection: Enum "VAT Statement Report Period Selection";
        UseAmtsInAddCurr: Boolean;
        DateFilter: Text[30];
        CountryRegionFilter: Text;

    /// <summary>
    /// Refreshes the VAT statement line subform with current parameter settings.
    /// Updates preview calculations based on current selection criteria and period settings.
    /// </summary>
    procedure UpdateSubForm()
    begin
        OnBeforeUpdateSubForm(Rec);
        CurrPage.VATStatementLineSubForm.PAGE.UpdateForm(Rec, Selection, PeriodSelection, UseAmtsInAddCurr, CountryRegionFilter);
    end;

    /// <summary>
    /// Retrieves current VAT statement preview parameters for external use.
    /// Returns the current selection criteria, period settings, and currency preferences.
    /// </summary>
    /// <param name="NewSelection">Returns current selection type setting</param>
    /// <param name="NewPeriodSelection">Returns current period selection setting</param>
    /// <param name="NewUseAmtsInAddCurr">Returns current additional currency preference</param>
    procedure GetParameters(var NewSelection: Enum "VAT Statement Report Selection"; var NewPeriodSelection: Enum "VAT Statement Report Period Selection"; var NewUseAmtsInAddCurr: Boolean)
    begin
        NewSelection := Selection;
        NewPeriodSelection := PeriodSelection;
        NewUseAmtsInAddCurr := UseAmtsInAddCurr;
    end;

    /// <summary>
    /// Configures VAT statement preview parameters with new calculation criteria.
    /// Sets selection type, period selection, and date filter for preview calculations.
    /// </summary>
    /// <param name="NewSelection">Selection type for VAT calculation criteria</param>
    /// <param name="NewPeriodSelection">Period selection for calculation scope</param>
    /// <param name="NewDateFilter">Date filter string for period specification</param>
    procedure SetParameters(NewSelection: Enum "VAT Statement Report Selection"; NewPeriodSelection: Enum "VAT Statement Report Period Selection"; NewDateFilter: Text[30])
    begin
        PassedSelection := NewSelection;
        PassedPeriodSelection := NewPeriodSelection;
        PassedDateFilter := NewDateFilter;
        Rec.SetFilter("Date Filter", PassedDateFilter);
        ValuesPassed := true;
    end;

    local procedure OpenandClosedSelectionOnPush()
    begin
        UpdateSubForm();
    end;

    local procedure ClosedSelectionOnPush()
    begin
        UpdateSubForm();
    end;

    local procedure OpenSelectionOnPush()
    begin
        UpdateSubForm();
    end;

    local procedure BeforeandWithinPeriodSelOnPush()
    begin
        UpdateSubForm();
    end;

    local procedure WithinPeriodPeriodSelectOnPush()
    begin
        UpdateSubForm();
    end;

    local procedure UseAmtsInAddCurrOnPush()
    begin
        UpdateSubForm();
    end;

    local procedure OpenSelectionOnValidate()
    begin
        OpenSelectionOnPush();
    end;

    local procedure ClosedSelectionOnValidate()
    begin
        ClosedSelectionOnPush();
    end;

    local procedure OpenandClosedSelectionOnValida()
    begin
        OpenandClosedSelectionOnPush();
    end;

    local procedure WithinPeriodPeriodSelectionOnV()
    begin
        WithinPeriodPeriodSelectOnPush();
    end;

    local procedure BeforeandWithinPeriodSelection()
    begin
        BeforeandWithinPeriodSelOnPush();
    end;

    local procedure RunReport(ReportID: Integer)
    var
        VATStatementName: Record "VAT Statement Name";
    begin
        VATStatementName.SetRange("Statement Template Name", Rec."Statement Template Name");
        VATStatementName.SetRange(Name, Rec.Name);
        REPORT.Run(ReportID, true, false, VATStatementName);
    end;

    /// <summary>
    /// Integration event raised before updating the VAT statement preview subform.
    /// Enables custom preprocessing of VAT statement name configuration before subform refresh.
    /// </summary>
    /// <param name="VATStatementName">VAT statement name record being used for preview update</param>
    [IntegrationEvent(true, false)]
    local procedure OnBeforeUpdateSubForm(var VATStatementName: Record "VAT Statement Name")
    begin
    end;
}

