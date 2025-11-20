// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

using Microsoft.Integration.Dataverse;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Resources.Resource;

page 5364 "CRM Unit List"
{
    ApplicationArea = Suite;
    Caption = 'Units - Microsoft Dynamics 365 Sales';
    Editable = false;
    PageType = List;
    SourceTable = "CRM Uom";
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
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Suite;
                    Caption = 'Quantity';
                    ToolTip = 'Specifies the quantity of the record.';
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
        RecordID: RecordID;
    begin
        if CRMIntegrationRecord.FindRecordIDFromID(Rec.UoMId, Database::"Item Unit of Measure", RecordID) then
            if CurrentlyCoupledCRMUom.UoMId = Rec.UoMScheduleId then begin
                Coupled := 'Current';
                FirstColumnStyle := 'Strong';
                Rec.Mark(true);
            end else begin
                Coupled := 'Yes';
                FirstColumnStyle := 'Subordinate';
                Rec.Mark(false);
            end
        else
            if CRMIntegrationRecord.FindRecordIDFromID(Rec.UoMId, Database::"Resource Unit of Measure", RecordID) then
                if CurrentlyCoupledCRMUom.UoMId = Rec.UoMScheduleId then begin
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
        Codeunit.Run(Codeunit::"CRM Integration Management");
    end;

    trigger OnOpenPage()
    var
        LookupCRMTables: Codeunit "Lookup CRM Tables";
    begin
        Rec.FilterGroup(4);
        Rec.SetView(LookupCRMTables.GetIntegrationTableMappingView(Database::"CRM Uom"));
        Rec.FilterGroup(0);
    end;

    var
        CurrentlyCoupledCRMUom: Record "CRM Uom";
        Coupled: Text;
        FirstColumnStyle: Text;

    procedure SetCurrentlyCoupledCRMUnit(CRMUom: Record "CRM Uom")
    begin
        CurrentlyCoupledCRMUom := CRMUom;
    end;
}

