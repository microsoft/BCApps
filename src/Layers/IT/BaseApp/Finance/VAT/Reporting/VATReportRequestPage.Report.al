// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Foundation.Address;

/// <summary>
/// Request page interface for configuring VAT report generation parameters and options.
/// Provides user interface for setting up VAT report criteria, periods, and processing preferences.
/// </summary>
report 742 "VAT Report Request Page"
{
    Caption = 'VAT Report Request Page';
    ProcessingOnly = true;

    dataset
    {
        dataitem("VAT Report Header"; "VAT Report Header")
        {
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                field(Selection; Selection)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Include VAT entries';
                    ToolTip = 'Specifies whether to include VAT entries based on their status. For example, Open is useful when submitting for the first time, Open and Closed is useful when resubmitting.';
                }
                field(PeriodSelection; PeriodSelection)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Include VAT entries';
                    ToolTip = 'Specifies whether to include VAT entries only from the specified period, or also from previous periods within the specified year.';
                }
                field("""VAT Report Header"".""Start Date"""; "VAT Report Header"."Start Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Start Date';
                    Importance = Additional;
                    ToolTip = 'Specifies the first date of the reporting period.';
                }
                field("""VAT Report Header"".""End Date"""; "VAT Report Header"."End Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'End Date';
                    Importance = Additional;
                    ToolTip = 'Specifies the last date of the reporting period.';
                }
                field("Amounts in ACY"; "VAT Report Header"."Amounts in Add. Rep. Currency")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amounts in Add. Reporting Currency';
                    Importance = Additional;
                    ToolTip = 'Specifies if you want to report amounts in the additional reporting currency.';
                }
                field("Country/Region Filter"; "VAT Report Header"."Country/Region Filter")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region to filter the VAT entries.';
                    Importance = Additional;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        CountryRegion: Record "Country/Region";
                        CountriesRegions: Page "Countries/Regions";
                    begin
                        CountriesRegions.LookupMode(true);
                        if CountriesRegions.RunModal() = Action::LookupOK then begin
                            CountriesRegions.GetRecord(CountryRegion);
                            "VAT Report Header"."Country/Region Filter" := CountryRegion.Code;
                        end;
                    end;
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    protected var
        Selection: Enum "VAT Statement Report Selection";
        PeriodSelection: Enum "VAT Statement Report Period Selection";
}

