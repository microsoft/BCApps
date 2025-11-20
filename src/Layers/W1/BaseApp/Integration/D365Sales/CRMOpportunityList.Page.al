// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

using Microsoft.CRM.Opportunity;
using Microsoft.Integration.Dataverse;

page 5343 "CRM Opportunity List"
{
    ApplicationArea = Suite;
    Caption = 'Opportunities - Microsoft Dynamics 365 Sales';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "CRM Opportunity";
    SourceTableView = sorting(Name);
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(StateCode; Rec.StateCode)
                {
                    ApplicationArea = Suite;
                    Caption = 'Status';
                    OptionCaption = 'Open,Won,Lost';
                    ToolTip = 'Specifies data from a corresponding field in a Dynamics 365 Sales entity. For more information about Dynamics 365 Sales, see Dynamics 365 Sales Help Center.';
                }
                field(StatusCode; Rec.StatusCode)
                {
                    ApplicationArea = Suite;
                    Caption = 'Status Reason';
                    OptionCaption = ' ,In Progress,On Hold,Won,Canceled,Out-Sold';
                    ToolTip = 'Specifies data from a corresponding field in a Dynamics 365 Sales entity. For more information about Dynamics 365 Sales, see Dynamics 365 Sales Help Center.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Suite;
                    Caption = 'Topic';
                    StyleExpr = FirstColumnStyle;
                    ToolTip = 'Specifies data from a corresponding field in a Dynamics 365 Sales entity. For more information about Dynamics 365 Sales, see Dynamics 365 Sales Help Center.';
                }
                field(EstimatedCloseDate; Rec.EstimatedCloseDate)
                {
                    ApplicationArea = Suite;
                    Caption = 'Est. Close Date';
                    ToolTip = 'Specifies data from a corresponding field in a Dynamics 365 Sales entity. For more information about Dynamics 365 Sales, see Dynamics 365 Sales Help Center.';
                }
                field(EstimatedValue; Rec.EstimatedValue)
                {
                    ApplicationArea = Suite;
                    Caption = 'Est. Revenue';
                    ToolTip = 'Specifies data from a corresponding field in a Dynamics 365 Sales entity. For more information about Dynamics 365 Sales, see Dynamics 365 Sales Help Center.';
                }
                field(TotalAmount; Rec.TotalAmount)
                {
                    ApplicationArea = Suite;
                    Caption = 'Total Amount';
                    ToolTip = 'Specifies data from a corresponding field in a Dynamics 365 Sales entity. For more information about Dynamics 365 Sales, see Dynamics 365 Sales Help Center.';
                }
                field(ParentContactIdName; Rec.ParentContactIdName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Contact Name';
                    ToolTip = 'Specifies data from a corresponding field in a Dynamics 365 Sales entity. For more information about Dynamics 365 Sales, see Dynamics 365 Sales Help Center.';
                }
                field(ParentAccountIdName; Rec.ParentAccountIdName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Account Name';
                    ToolTip = 'Specifies data from a corresponding field in a Dynamics 365 Sales entity. For more information about Dynamics 365 Sales, see Dynamics 365 Sales Help Center.';
                }
                field(CloseProbability; Rec.CloseProbability)
                {
                    ApplicationArea = Suite;
                    Caption = 'Probability';
                    ToolTip = 'Specifies data from a corresponding field in a Dynamics 365 Sales entity. For more information about Dynamics 365 Sales, see Dynamics 365 Sales Help Center.';
                }
                field(OpportunityRatingCode; Rec.OpportunityRatingCode)
                {
                    ApplicationArea = Suite;
                    Caption = 'Rating';
                    OptionCaption = 'Hot,Warm,Cold';
                    ToolTip = 'Specifies data from a corresponding field in a Dynamics 365 Sales entity. For more information about Dynamics 365 Sales, see Dynamics 365 Sales Help Center.';
                }
                field(Need; Rec.Need)
                {
                    ApplicationArea = Suite;
                    Caption = 'Need';
                    OptionCaption = ' ,Must have,Should have,Good to have,No need';
                    ToolTip = 'Specifies data from a corresponding field in a Dynamics 365 Sales entity. For more information about Dynamics 365 Sales, see Dynamics 365 Sales Help Center.';
                }
                field(Coupled; Coupled)
                {
                    ApplicationArea = Suite;
                    Caption = 'Coupled';
                    ToolTip = 'Specifies if the Dynamics 365 Sales record is coupled to Business Central.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group(ActionGroupCRM)
            {
                Caption = 'Dynamics 365 Sales';
                action(CRMGotoOpportunities)
                {
                    ApplicationArea = Suite;
                    Caption = 'Opportunity';
                    Image = CoupledOpportunity;
                    ToolTip = 'Specifies the sales opportunity that is coupled to this Dynamics 365 Sales opportunity.';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        HyperLink(CRMIntegrationManagement.GetCRMEntityUrlFromCRMID(DATABASE::"CRM Opportunity", Rec.OpportunityId));
                    end;
                }
            }
        }
        area(processing)
        {
            action(CreateFromCRM)
            {
                ApplicationArea = Suite;
                Caption = 'Create in Business Central';
                Image = NewOpportunity;
                ToolTip = 'Generate an opportunity from the coupled Dynamics 365 Sales opportunity.';

                trigger OnAction()
                var
                    CRMOpportunity: Record "CRM Opportunity";
                    CRMIntegrationManagement: Codeunit "CRM Integration Management";
                begin
                    CurrPage.SetSelectionFilter(CRMOpportunity);
                    CRMIntegrationManagement.CreateNewRecordsFromSelectedCRMRecords(CRMOpportunity);
                end;
            }
            action(ShowOnlyUncoupled)
            {
                ApplicationArea = Suite;
                Caption = 'Hide Coupled Opportunities';
                Image = FilterLines;
                ToolTip = 'Do not show coupled opportunities.';

                trigger OnAction()
                begin
                    Rec.MarkedOnly(true);
                end;
            }
            action(ShowAll)
            {
                ApplicationArea = Suite;
                Caption = 'Show Coupled Opportunities';
                Image = ClearFilter;
                ToolTip = 'Show coupled opportunities.';

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
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(CreateFromCRM_Promoted; CreateFromCRM)
                {
                }
                group(Category_Synchronize)
                {
                    Caption = 'Synchronize';

                    actionref(CRMGotoOpportunities_Promoted; CRMGotoOpportunities)
                    {
                    }
                }
                actionref(ShowOnlyUncoupled_Promoted; ShowOnlyUncoupled)
                {
                }
                actionref(ShowAll_Promoted; ShowAll)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Dynamics 365 Sales', Comment = 'Generated from the PromotedActionCategories property index 3.';

            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        RecordID: RecordID;
    begin
        if CRMIntegrationRecord.FindRecordIDFromID(Rec.OpportunityId, DATABASE::Opportunity, RecordID) then
            if CurrentlyCoupledCRMOpportunity.OpportunityId = Rec.OpportunityId then begin
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
        Rec.SetView(LookupCRMTables.GetIntegrationTableMappingView(DATABASE::"CRM Opportunity"));
        Rec.FilterGroup(0);
    end;

    var
        CurrentlyCoupledCRMOpportunity: Record "CRM Opportunity";
        Coupled: Text;
        FirstColumnStyle: Text;

    procedure SetCurrentlyCoupledCRMOpportunity(CRMOpportunity: Record "CRM Opportunity")
    begin
        CurrentlyCoupledCRMOpportunity := CRMOpportunity;
    end;
}

