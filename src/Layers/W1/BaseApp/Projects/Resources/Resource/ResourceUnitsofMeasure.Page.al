// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Resource;

using Microsoft.Foundation.UOM;
using Microsoft.Integration.Dataverse;

page 210 "Resource Units of Measure"
{
    Caption = 'Resource Units of Measure';
    DataCaptionFields = "Resource No.";
    PageType = List;
    SourceTable = "Resource Unit of Measure";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Resource No."; Rec."Resource No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the resource.';
                    Visible = false;
                }
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Jobs;
                    Style = Strong;
                    StyleExpr = StyleName;
                    ToolTip = 'Specifies one of the unit of measure codes that has been set up in the Unit of Measure table.';
                }
                field("Qty. per Unit of Measure"; Rec."Qty. per Unit of Measure")
                {
                    ApplicationArea = Jobs;
                    Style = Strong;
                    StyleExpr = StyleName;
                    ToolTip = 'Specifies the number of units of the code. If, for example, the base unit of measure is hour, and the code is day, enter 8 in this field.';
                }
                field("Related to Base Unit of Meas."; Rec."Related to Base Unit of Meas.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies that the unit of measure can be calculated into the base unit of measure. For example, 2 days equals 16 hours.';
                }
                field("Coupled to Dataverse"; Rec."Coupled to Dataverse")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies that the resource unit of measure is coupled to a unit of measure in Dynamics 365 Sales.';
                    Visible = CRMIntegrationEnabled;
                }
            }
            group("Current Base Unit of Measure")
            {
                Caption = 'Current Base Unit of Measure';
                field(ResUnitOfMeasure; ResBaseUOM)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Base Unit of Measure';
                    Lookup = true;
                    TableRelation = "Unit of Measure".Code;
                    ToolTip = 'Specifies the unit in which the resource is managed internally. The base unit of measure also serves as the conversion basis for alternate units of measure.';

                    trigger OnValidate()
                    begin
                        Res.Validate("Base Unit of Measure", ResBaseUOM);
                        Res.Modify(true);
                        CurrPage.Update();
                    end;
                }
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
        area(navigation)
        {
            group(ActionGroupCRM)
            {
                Caption = 'Dynamics 365 Sales';
                Image = Administration;
                Visible = CRMIntegrationEnabled;
                action(CRMGotoUnitGroup)
                {
                    ApplicationArea = Suite;
                    Caption = 'Unit';
                    Image = CoupledUnitOfMeasure;
                    ToolTip = 'Open the coupled Dynamics 365 Sales unit of measure.';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.ShowCRMEntityFromRecordID(Rec.RecordId);
                    end;
                }
                action(CRMSynchronizeNow)
                {
                    AccessByPermission = TableData "CRM Integration Record" = IM;
                    ApplicationArea = Suite;
                    Caption = 'Synchronize';
                    Image = Refresh;
                    ToolTip = 'Send updated data to Dynamics 365 Sales.';

                    trigger OnAction()
                    var
                        ResourceUnitOfMeasure: Record "Resource Unit of Measure";
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        ResourceUnitOfMeasureRecordRef: RecordRef;
                    begin
                        CurrPage.SetSelectionFilter(ResourceUnitOfMeasure);
                        ResourceUnitOfMeasure.Next();

                        if ResourceUnitOfMeasure.Count() = 1 then
                            CRMIntegrationManagement.UpdateOneNow(ResourceUnitOfMeasure.RecordId)
                        else begin
                            ResourceUnitOfMeasureRecordRef.GetTable(ResourceUnitOfMeasure);
                            CRMIntegrationManagement.UpdateMultipleNow(ResourceUnitOfMeasureRecordRef);
                        end
                    end;
                }
                group(Coupling)
                {
                    Caption = 'Coupling', Comment = 'Coupling is a noun';
                    Image = LinkAccount;
                    ToolTip = 'Create, change, or delete a coupling between the Business Central record and a Dynamics 365 Sales record.';
                    action(ManageCRMCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = IM;
                        ApplicationArea = Suite;
                        Caption = 'Set Up Coupling';
                        Image = LinkAccount;
                        ToolTip = 'Create or modify the coupling to a Dynamics 365 Sales unit of measure.';

                        trigger OnAction()
                        var
                            CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        begin
                            CRMIntegrationManagement.DefineCoupling(Rec.RecordId);
                        end;
                    }
                    action(DeleteCRMCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = D;
                        ApplicationArea = Suite;
                        Caption = 'Delete Coupling';
                        Enabled = CRMIsCoupledToRecord;
                        Image = UnLinkAccount;
                        ToolTip = 'Delete the coupling to a Dynamics 365 Sales unit of measure.';

                        trigger OnAction()
                        var
                            ResourceUnitOfMeasure: Record "Resource Unit of Measure";
                            CRMCouplingManagement: Codeunit "CRM Coupling Management";
                            ResourceUnitOfMeasureRecordRef: RecordRef;
                        begin
                            CurrPage.SetSelectionFilter(ResourceUnitOfMeasure);
                            ResourceUnitOfMeasureRecordRef.GetTable(ResourceUnitOfMeasure);
                            CRMCouplingManagement.RemoveCoupling(ResourceUnitOfMeasureRecordRef);
                        end;
                    }
                }
                action(ShowLog)
                {
                    ApplicationArea = Suite;
                    Caption = 'Synchronization Log';
                    Image = Log;
                    ToolTip = 'View integration synchronization jobs for the resource unit of measure table.';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.ShowLog(Rec.RecordId);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Synchronize)
            {
                Caption = 'Synchronize';

                group(Category_Coupling)
                {
                    Caption = 'Coupling';
                    ShowAs = SplitButton;

                    actionref(ManageCRMCoupling_Promoted; ManageCRMCoupling)
                    {
                    }
                    actionref(DeleteCRMCoupling_Promoted; DeleteCRMCoupling)
                    {
                    }
                }
                actionref(CRMSynchronizeNow_Promoted; CRMSynchronizeNow)
                {
                }
                actionref(CRMGotoUnitGroup_Promoted; CRMGotoUnitGroup)
                {
                }
                actionref(ShowLog_Promoted; ShowLog)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
    begin
        CRMIsCoupledToRecord := CRMIntegrationEnabled;
        if CRMIsCoupledToRecord then
            CRMIsCoupledToRecord := CRMCouplingManagement.IsRecordCoupledToCRM(Rec.RecordId);
    end;

    trigger OnAfterGetRecord()
    begin
        SetStyle();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        SetStyle();
    end;

    trigger OnOpenPage()
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        if Res.Get(Rec."Resource No.") then
            ResBaseUOM := Res."Base Unit of Measure";
        CRMIntegrationEnabled := CRMIntegrationManagement.IsCRMIntegrationEnabled() and CRMIntegrationManagement.IsUnitGroupMappingEnabled();
    end;

    var
        Res: Record Resource;
        CRMIntegrationEnabled: Boolean;
        CRMIsCoupledToRecord: Boolean;
        ResBaseUOM: Code[10];
        StyleName: Text;

    local procedure SetStyle()
    begin
        if Rec.Code = ResBaseUOM then
            StyleName := 'Strong'
        else
            StyleName := '';
    end;
}

