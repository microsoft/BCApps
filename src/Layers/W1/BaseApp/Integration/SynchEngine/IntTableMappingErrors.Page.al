// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.SyncEngine;
using Microsoft.Integration.Dataverse;

page 5327 "Int. Table Mapping Errors"
{
    Caption = 'Troubleshooting';
    PageType = CardPart;
    SourceTable = "Integration Table Mapping";

    layout
    {
        area(content)
        {
            field("Name"; Rec.Name)
            {
                ApplicationArea = All;
                Caption = ' ';
                ShowCaption = false;
            }
            group(Control23)
            {
                ShowCaption = false;
                Visible = false;
                field("No. of Errors"; Rec."No. of Errors")
                {
                    ApplicationArea = All;
                    Caption = 'Errors';
                    ToolTip = 'Specifies the number of errors for this mapping.';
                }
                field("No. of Skipped"; Rec."No. of Skipped")
                {
                    ApplicationArea = Suite;
                    Caption = 'Skipped Records';
                    ToolTip = 'Specifies the number of records that are excluded from the synchronization because of repetitive errors.';
                }
            }
            cuegroup(Control2)
            {
                ShowCaption = false;
                field(NoOfErrorsTile; Rec."No. of Errors")
                {
                    ApplicationArea = All;
                    Caption = 'Integration Errors';
                    ToolTip = 'Specifies the number of errors for this mapping.';
                    StyleExpr = IntegrationErrorsCue;

                    trigger OnDrillDown()
                    var
                        IntegrationSynchJob: Record "Integration Synch. Job";
                    begin
                        IntegrationSynchJob.SetRange("Integration Table Mapping Name", Rec.Name);
                        IntegrationSynchJob.SetFilter(Failed, '>0');
                        if not IntegrationSynchJob.IsEmpty() then
                            Page.Run(Page::"Integration Synch. Job List", IntegrationSynchJob);
                    end;
                }
                field(NoOfSkippedTile; Rec."No. of Skipped")
                {
                    ApplicationArea = All;
                    Caption = 'Coupled Data Sync Errors';
                    ToolTip = 'Specifies the number of records that are excluded from the synchronization because of repetitive errors.';
                    StyleExpr = CoupledErrorsCue;

                    trigger OnDrillDown()
                    var
                        CRMSkippedRecords: Page "CRM Skipped Records";
                    begin
                        CRMSkippedRecords.SetInitialTableDataFilter(Format(Rec."Table ID"));
                        CRMSkippedRecords.Run();
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        IntegrationSynchJob: Record "Integration Synch. Job";
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        IntegrationSynchJob.SetRange("Integration Table Mapping Name", Rec.Name);
        IntegrationSynchJob.SetFilter(Failed, '>0');
        if IntegrationSynchJob.IsEmpty() then
            IntegrationErrorsCue := 'Favorable'
        else
            IntegrationErrorsCue := 'Unfavorable';
        CRMIntegrationRecord.SetRange("Table ID", Rec."Table ID");
        CRMIntegrationRecord.SetRange(Skipped, true);
        if CRMIntegrationRecord.IsEmpty() then
            CoupledErrorsCue := 'Favorable'
        else
            CoupledErrorsCue := 'Unfavorable';
    end;

    var
        IntegrationErrorsCue: Text;
        CoupledErrorsCue: Text;
}

