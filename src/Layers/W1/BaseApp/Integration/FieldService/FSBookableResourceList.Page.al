// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#if not CLEAN25
namespace Microsoft.Integration.FieldService;

using Microsoft.Integration.Dataverse;
using Microsoft.Projects.Resources.Resource;

page 6423 "FS Bookable Resource List"
{
    Caption = 'Bookable Resources - Dynamics 365 Field Service';
    Editable = false;
    PageType = List;
    SourceTable = "FS Bookable Resource";
    SourceTableView = sorting(Name);
    ObsoleteReason = 'Field Service is moved to Field Service Integration app.';
    ObsoleteState = Pending;
    ObsoleteTag = '25.0';

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = Suite;
                    Caption = 'Name';
                    StyleExpr = FirstColumnStyle;
                    ToolTip = 'Specifies the bookable resource name.';
                }
                field(HourlyRate; Rec.HourlyRate)
                {
                    ApplicationArea = Suite;
                    Caption = 'Hourly Rate';
                    ToolTip = 'Specifies the bookable resource hourly rate.';
                }
                field(ResourceType; Rec.ResourceType)
                {
                    ApplicationArea = Suite;
                    Caption = 'Resource Type';
                    ToolTip = 'Specifies the bookable resource type.';
                }
                field(Coupled; Coupled)
                {
                    ApplicationArea = Suite;
                    Caption = 'Coupled';
                    ToolTip = 'Specifies if the Dynamics 365 Field Service record is coupled to Business Central.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(CreateFromFS)
            {
                ApplicationArea = Suite;
                Caption = 'Create in Business Central';
                Image = NewResource;
                ToolTip = 'Generate the entity from the Field Service bookable resource.';

                trigger OnAction()
                var
                    FSBookableResource: Record "FS Bookable Resource";
                    CRMIntegrationManagement: Codeunit "CRM Integration Management";
                begin
                    CurrPage.SetSelectionFilter(FSBookableResource);
                    CRMIntegrationManagement.CreateNewRecordsFromSelectedCRMRecords(FSBookableResource);
                end;
            }
            action(ShowOnlyUncoupled)
            {
                ApplicationArea = Suite;
                Caption = 'Hide Coupled Records';
                Image = FilterLines;
                ToolTip = 'Do not show coupled records.';

                trigger OnAction()
                begin
                    Rec.MarkedOnly(true);
                end;
            }
            action(ShowAll)
            {
                ApplicationArea = Suite;
                Caption = 'Show Coupled Records';
                Image = ClearFilter;
                ToolTip = 'Show coupled records.';

                trigger OnAction()
                begin
                    Rec.MarkedOnly(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(CreateFromFS_Promoted; CreateFromFS)
                {
                }
                actionref(ShowOnlyUncoupled_Promoted; ShowOnlyUncoupled)
                {
                }
                actionref(ShowAll_Promoted; ShowAll)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        RecordID: RecordID;
    begin
        if CRMIntegrationRecord.FindRecordIDFromID(Rec.BookableResourceId, DATABASE::Resource, RecordID) then
            if CurrentlyCoupledFSBookableResource.BookableResourceId = Rec.BookableResourceId then begin
                Coupled := 'Current';
                FirstColumnStyle := 'Strong';
                Rec.Mark(true);
            end else begin
                Coupled := 'Yes';
                FirstColumnStyle := 'Subordinate';
                Rec.Mark(false);
            end
        else begin
            Coupled := 'No';
            FirstColumnStyle := 'None';
            Rec.Mark(true);
        end;
    end;

    trigger OnInit()
    begin
        CODEUNIT.Run(CODEUNIT::"CRM Integration Management");
    end;

    trigger OnOpenPage()
    var
        LookupCRMTables: Codeunit "Lookup CRM Tables";
    begin
        Rec.FilterGroup(4);
        Rec.SetView(LookupCRMTables.GetIntegrationTableMappingView(Database::"FS Bookable Resource"));
        Rec.FilterGroup(0);
    end;

    var
        CurrentlyCoupledFSBookableResource: Record "FS Bookable Resource";
        Coupled: Text;
        FirstColumnStyle: Text;

    procedure SetCurrentlyCoupledFSBookableResource(FSBookableResource: Record "FS Bookable Resource")
    begin
        CurrentlyCoupledFSBookableResource := FSBookableResource;
    end;
}
#endif
