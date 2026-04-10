// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

/// <summary>
/// Provides web service interface for financial report KPI data access by external systems.
/// Exposes calculated KPI values from account schedules through OData endpoints for business intelligence integration.
/// </summary>
/// <remarks>
/// Primary functionality: KPI data web service exposure, external system integration endpoint.
/// Integration: Links with Account Schedule KPI Buffer and web service publishing framework.
/// Extensibility: Standard page extension patterns for additional KPI fields and service customization.
/// </remarks>
page 197 "Acc. Sched. KPI Web Service"
{
    AdditionalSearchTerms = 'financial report,business intelligence,bi,odata,account schedule kpi web service,financial reporting';
    ApplicationArea = Basic, Suite;
    Caption = 'Financial Report KPI Web Service';
    Editable = false;
    PageType = List;
    SourceTable = "Acc. Sched. KPI Buffer";
    SourceTableTemporary = true;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the financial report KPI web service.';
                    Visible = false;
                }
                field(Date; Rec.Date)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Date';
                    ToolTip = 'Specifies the date that the financial report KPI data is based on.';
                }
                field("Closed Period"; Rec."Closed Period")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Closed Period';
                }
                field("Account Schedule Name"; Rec."Account Schedule Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Account Schedule Name';
                    ToolTip = 'Specifies the name of the row definition that the KPI web service is based on.';
                }
                field("KPI Code"; Rec."KPI Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'KPI Code';
                }
                field("KPI Name"; Rec."KPI Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'KPI Name';
                    ToolTip = 'Specifies the name that will be shown on the KPI as a user-friendly name for the financial report values.';
                }
                field("Net Change Actual"; Rec."Net Change Actual")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Net Change Actual';
                }
                field("Balance at Date Actual"; Rec."Balance at Date Actual")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Balance at Date Actual';
                }
                field("Net Change Budget"; Rec."Net Change Budget")
                {
                    ApplicationArea = Suite;
                    Caption = 'Net Change Budget';
                }
                field("Balance at Date Budget"; Rec."Balance at Date Budget")
                {
                    ApplicationArea = Suite;
                    Caption = 'Balance at Date Budget';
                }
                field("Net Change Actual Last Year"; Rec."Net Change Actual Last Year")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Net Change Actual Last Year';
                    ToolTip = 'Specifies actual changes in the general ledger amount, based on closed accounting periods, through the previous accounting year.';
                }
                field("Balance at Date Actual Last Year"; Rec."Balance at Date Act. Last Year")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Balance at Date Actual Last Year';
                }
                field("Net Change Budget Last Year"; Rec."Net Change Budget Last Year")
                {
                    ApplicationArea = Suite;
                    Caption = 'Net Change Budget Last Year';
                    ToolTip = 'Specifies budgeted changes in the general ledger amount, up until the date in the Date field in the previous year.';
                }
                field("Balance at Date Budget Last Year"; Rec."Balance at Date Bud. Last Year")
                {
                    ApplicationArea = Suite;
                    Caption = 'Balance at Date Budget Last Year';
                }
                field("Net Change Forecast"; Rec."Net Change Forecast")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Net Change Forecast';
                }
                field("Balance at Date Forecast"; Rec."Balance at Date Forecast")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Balance at Date Forecast';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        AccSchedKPIBuffer: Record "Acc. Sched. KPI Buffer";
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        CODEUNIT.Run(CODEUNIT::"Update Acc. Sched. KPI Data");
        if AccSchedKPIBuffer.FindSet() then
            repeat
                AccScheduleLine.SetRange("Schedule Name", AccSchedKPIBuffer."Account Schedule Name");
                AccScheduleLine.SetRange("Row No.", AccSchedKPIBuffer."KPI Code");
                if AccScheduleLine.FindFirst() then;
                if AccScheduleLine.Show = "Acc. Schedule Line Show"::Yes then begin
                    Rec.Init();
                    Rec."No." += 1;
                    Rec.TransferFields(AccSchedKPIBuffer, false);
                    Rec.Insert();
                end;
            until AccSchedKPIBuffer.Next() = 0;
        Rec.Reset();
        Rec.FindFirst();
    end;
}

