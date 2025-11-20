// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Foundation.Address;

report 742 "VAT Report Request Page"
{
    Caption = 'VAT Report Request Page';
    ProcessingOnly = true;

    dataset
    {
        dataitem("VAT Report Header"; "VAT Report Header")
        {

            trigger OnPostDataItem()
            begin
                "Created Date-Time" := CurrentDateTime();
                Modify();
            end;

            trigger OnPreDataItem()
            var
                VATStatementLine: Record "VAT Statement Line";
                VATStatementReportLine: Record "VAT Statement Report Line";
                VATStatementName: Record "VAT Statement Name";
                VATStatement: Report "VAT Statement";
                Base: Decimal;
                Amount: Decimal;
            begin
                Copy(Rec);

                VATStatementName.SetRange("Statement Template Name", "Statement Template Name");
                VATStatementName.SetRange(Name, "Statement Name");
                VATStatementName.SetRange("Date Filter", "Start Date", "End Date");

                VATStatementName.CopyFilter("Date Filter", VATStatementLine."Date Filter");

                VATStatementLine.SetRange("Statement Template Name", "Statement Template Name");
                VATStatementLine.SetRange("Statement Name", "Statement Name");
                VATStatementLine.SetFilter("Box No.", '<>%1', '');
                OnBeforeVATStatementLineFindSet(VATStatementLine, "VAT Report Header");
                VATStatementLine.FindSet();

                VATStatement.InitializeRequest(
                  VATStatementName, VATStatementLine, Selection, PeriodSelection, false, "Amounts in Add. Rep. Currency", "Country/Region Filter");

                VATStatementReportLine.SetRange("VAT Report No.", "No.");
                VATStatementReportLine.SetRange("VAT Report Config. Code", "VAT Report Config. Code");
                VATStatementReportLine.DeleteAll();
                repeat
                    OnBeforeCalcLineTotalWithBase(VATStatementReportLine, VATStatementLine, "VAT Report Header");
                    VATStatement.CalcLineTotalWithBase(VATStatementLine, Amount, Base, 0);
                    if VATStatementLine."Print with" = VATStatementLine."Print with"::"Opposite Sign" then begin
                        Amount := -Amount;
                        Base := -Base;
                    end;
                    VATStatementReportLine.Init();
                    VATStatementReportLine.Validate("VAT Report No.", "No.");
                    VATStatementReportLine.Validate("VAT Report Config. Code", "VAT Report Config. Code");
                    VATStatementReportLine.Validate("Line No.", VATStatementLine."Line No.");
                    VATStatementReportLine.Validate("Row No.", VATStatementLine."Row No.");
                    VATStatementReportLine.Validate(Description, VATStatementLine.Description);
                    VATStatementReportLine.Validate("Box No.", VATStatementLine."Box No.");
                    VATStatementReportLine.Validate(Amount, Amount);
                    VATStatementReportLine.Validate(Base, Base);
                    VATStatementReportLine.Insert();
                until VATStatementLine.Next() = 0;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;
        ShowFilter = false;
        SourceTable = "VAT Report Header";

        layout
        {
            area(content)
            {
                group(Options)
                {
                    field(Selection; Selection)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include VAT entries';
                        ShowMandatory = true;
                        ToolTip = 'Specifies whether to include VAT entries based on their status. For example, Open is useful when submitting for the first time, Open and Closed is useful when resubmitting.';
                    }
                    field(PeriodSelection; PeriodSelection)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include VAT entries';
                        ShowMandatory = true;
                        ToolTip = 'Specifies whether to include VAT entries only from the specified period, or also from previous periods within the specified year.';
                    }
                    field(VATStatementTemplate; Rec."Statement Template Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Statement Template';
                        ShowMandatory = true;
                        TableRelation = "VAT Statement Template";
                        ToolTip = 'Specifies the VAT Statement to generate the VAT report.';
                    }
                    field(VATStatementName; Rec."Statement Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Statement Name';
                        LookupPageID = "VAT Statement Names";
                        ShowMandatory = true;
                        TableRelation = "VAT Statement Name".Name where("Statement Template Name" = field("Statement Template Name"));
                        ToolTip = 'Specifies the VAT Statement to generate the VAT report.';
                    }
                    field("Period Year"; Rec."Period Year")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = PeriodIsEditable;
                        ToolTip = 'Specifies the year of the reporting period.';
                    }
                    field("Period Type"; Rec."Period Type")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = PeriodIsEditable;
                        ToolTip = 'Specifies the length of the reporting period.';
                    }
                    field("Period No."; Rec."Period No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = PeriodIsEditable;
                        ToolTip = 'Specifies the specific reporting period to use.';
                    }
                    field("Start Date"; Rec."Start Date")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = PeriodIsEditable;
                        Importance = Additional;
                        ShowMandatory = true;
                        ToolTip = 'Specifies the first date of the reporting period.';
                    }
                    field("End Date"; Rec."End Date")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = PeriodIsEditable;
                        Importance = Additional;
                        ShowMandatory = true;
                        ToolTip = 'Specifies the last date of the reporting period.';
                    }
                    field("Amounts in ACY"; Rec."Amounts in Add. Rep. Currency")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Amounts in Add. Reporting Currency';
                        Importance = Additional;
                        ToolTip = 'Specifies if you want to report amounts in the additional reporting currency.';
                    }
                    field("Country/Region Filter"; Rec."Country/Region Filter")
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
                                Rec."Country/Region Filter" := CountryRegion.Code;
                                exit(true);
                            end;
                            exit(false);
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        var
            VATStatementTemplate: Record "VAT Statement Template";
            VATStatementName: Record "VAT Statement Name";
        begin
            Rec.CopyFilters("VAT Report Header");
            Rec.FindFirst();

            if VATStatementTemplate.Count = 1 then begin
                VATStatementTemplate.FindFirst();
                Rec."Statement Template Name" := VATStatementTemplate.Name;
                Rec.Modify();

                VATStatementName.SetRange("Statement Template Name", VATStatementTemplate.Name);
                if VATStatementName.Count = 1 then begin
                    VATStatementName.FindFirst();
                    Rec."Statement Name" := VATStatementName.Name;
                    Rec.Modify();
                end;
            end;

            PeriodIsEditable := Rec."Return Period No." = '';
            OnAfterSetPeriodIsEditable(Rec, PeriodIsEditable);
        end;
    }

    labels
    {
    }

    var
        PeriodIsEditable: Boolean;

    protected var
        Selection: Enum "VAT Statement Report Selection";
        PeriodSelection: Enum "VAT Statement Report Period Selection";

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetPeriodIsEditable(VATReportHeader: Record "VAT Report Header"; var PeriodIsEditable: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVATStatementLineFindSet(var VATStatementLine: Record "VAT Statement Line"; VATReportHeader: Record "VAT Report Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcLineTotalWithBase(var VATStatementReportLine: Record "VAT Statement Report Line"; VATStatementLine: Record "VAT Statement Line"; VATReportHeader: Record "VAT Report Header")
    begin
    end;
}

