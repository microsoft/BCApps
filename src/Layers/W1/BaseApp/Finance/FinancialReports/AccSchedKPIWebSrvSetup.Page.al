// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using System.Integration;

page 195 "Acc. Sched. KPI Web Srv. Setup"
{
    AdditionalSearchTerms = 'financial report setup,business intelligence setup,bi setup,odata setup,account schedule kpi web service setup,financial reporting';
    ApplicationArea = Basic, Suite;
    Caption = 'Financial Report KPI Web Service Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Acc. Sched. KPI Web Srv. Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(Period; Rec.Period)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the period that the financial-report KPI web service is based on.';
                }
                field("View By"; Rec."View By")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which time interval the financial-report KPI is shown in.';
                }
                field("G/L Budget Name"; Rec."G/L Budget Name")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the name of the general ledger budget that provides budgeted values to the financial-report KPI web service.';
                }
                field("Forecasted Values Start"; Rec."Forecasted Values Start")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies at what point in time forecasted values are shown on the financial-report KPI graphic. The forecasted values are retrieved from the selected general ledger budget.';
                }
                field("Web Service Name"; Rec."Web Service Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the financial-report KPI web service. This name will be shown under the displayed financial-report KPI.';
                }
                field(Published; Rec.Published)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the financial-report KPI web service has been published. Published web services are listed in the Web Services window.';
                }
                field("Data Last Updated"; Rec."Data Last Updated")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last time data was refreshed through the web service. ';
                }
                field("Data Time To Live (hours)"; Rec."Data Time To Live (hours)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how long data is stored in Business Central before being refreshed from the service. The longer the duration is the smaller the performance impact.';
                }
                field(GetLastClosedAccDate; Rec.GetLastClosedAccDate())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Last Locked Posting Date';
                    ToolTip = 'Specifies the last date that posting was locked and actual transaction values were not supplied to the financial-report KPI.';
                }
                field(GetLastBudgetChangedDate; Rec.GetLastBudgetChangedDate())
                {
                    ApplicationArea = Suite;
                    Caption = 'Last Changed Budget Date';
                    ToolTip = 'Specifies when the general ledger budget for this financial-report KPI was last modified.';
                }
            }
            part("Account Schedules"; "Acc. Sched. KPI Web Srv. Lines")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Row definitions';
                ShowFilter = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(PublishWebService)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Publish Web Service';
                Image = Add;
                ToolTip = 'Publish the financial report as a web service. The Published field is set to Yes.';

                trigger OnAction()
                begin
                    Rec.PublishWebService();
                end;
            }
            action(DeleteWebService)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Remove Web Service';
                Image = Delete;
                ToolTip = 'Unpublish the financial report web service. The Published field is set to No.';

                trigger OnAction()
                begin
                    Rec.DeleteWebService();
                end;
            }
            action(RefreshBufferData)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Refresh Data';
                Ellipsis = true;
                Image = RefreshLines;
                ToolTip = 'Refresh the buffered data. All the lines will be recalculated. This may take a minute or so.';

                trigger OnAction()
                begin
                    if not Confirm(ResetQst) then
                        exit;
                    Rec.LockTable();
                    Rec.Find();
                    Rec."Data Last Updated" := 0DT;
                    Rec."Last G/L Entry Included" := 0;
                    Rec.Modify();
                    CODEUNIT.Run(CODEUNIT::"Update Acc. Sched. KPI Data");
                end;
            }
        }
        area(navigation)
        {
            action(KPIData)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Financial Report KPI Web Service';
                Image = List;
                RunObject = Page "Acc. Sched. KPI Web Service";
                ToolTip = 'View the data that is published as a web service based on the financial reports that you have set up in this window.';
            }
            action(WebServices)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Web Services';
                Image = Web;
                RunObject = Page "Web Services";
                ToolTip = 'Opens the Web Services window so you can see all available web services.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(PublishWebService_Promoted; PublishWebService)
                {
                }
                actionref(DeleteWebService_Promoted; DeleteWebService)
                {
                }
                actionref(RefreshBufferData_Promoted; RefreshBufferData)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;

    var
        ResetQst: Label 'Do you want to refresh the buffered data?';
}

