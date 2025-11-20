// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

using Microsoft.Foundation.UOM;
using Microsoft.Integration.Dataverse;

page 5362 "CRM UnitGroup List"
{
    ApplicationArea = Suite;
    Caption = 'Unit Groups - Microsoft Dynamics 365 Sales';
    Editable = false;
    PageType = List;
    SourceTable = "CRM Uomschedule";
    SourceTableView = sorting(Name);
    UsageCategory = Lists;

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
                    ToolTip = 'Specifies the name of the record.';
                }
                field(BaseUoMName; Rec.BaseUoMName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Base Unit Name';
                    ToolTip = 'Specifies the base unit of measure of the Dynamics 365 Sales record.';
                }
                field(StateCode; Rec.StateCode)
                {
                    ApplicationArea = Suite;
                    Caption = 'Status';
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection. ';
                }
                field(StatusCode; Rec.StatusCode)
                {
                    ApplicationArea = Suite;
                    Caption = 'Status Reason';
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection. ';
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
        area(processing)
        {
            action(ShowOnlyUncoupled)
            {
                ApplicationArea = Suite;
                Caption = 'Hide Coupled Unit Groups';
                Image = FilterLines;
                ToolTip = 'Do not show coupled unit groups.';

                trigger OnAction()
                begin
                    Rec.MarkedOnly(true);
                end;
            }
            action(ShowAll)
            {
                ApplicationArea = Suite;
                Caption = 'Show Coupled Unit Groups';
                Image = ClearFilter;
                ToolTip = 'Show coupled unit groups.';

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
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        RecordID: RecordID;
        MappedTableId: Integer;
    begin
        if CRMIntegrationManagement.IsUnitGroupMappingEnabled() then
            MappedTableId := Database::"Unit Group"
        else
            MappedTableId := Database::"Unit of Measure";

        if CRMIntegrationRecord.FindRecordIDFromID(Rec.UoMScheduleId, MappedTableId, RecordID) then
            if CurrentlyCoupledCRMUomschedule.UoMScheduleId = Rec.UoMScheduleId then begin
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
        Rec.SetView(LookupCRMTables.GetIntegrationTableMappingView(DATABASE::"CRM Uomschedule"));
        Rec.FilterGroup(0);
    end;

    var
        CurrentlyCoupledCRMUomschedule: Record "CRM Uomschedule";
        Coupled: Text;
        FirstColumnStyle: Text;

    procedure SetCurrentlyCoupledCRMUomschedule(CRMUomschedule: Record "CRM Uomschedule")
    begin
        CurrentlyCoupledCRMUomschedule := CRMUomschedule;
    end;
}

