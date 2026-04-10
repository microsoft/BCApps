// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using Microsoft.Foundation.UOM;
using Microsoft.Integration.Dataverse;

page 5400 "Item Unit Group List"
{
    Caption = 'Item Unit Group List';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Unit Group";
    SourceTableView = where("Source Type" = const(Item));
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Code"; CodeLbl)
                {
                    ApplicationArea = All;
                    Caption = 'Code';
                    ToolTip = 'Specifies the code of the record.';
                }
                field("Item No."; Rec."Source No.")
                {
                    ApplicationArea = All;
                    Caption = 'Item No.';
                    ToolTip = 'Specifies the item number that associated with the record.';
                }
                field("Item Description"; SourceNameLbl)
                {
                    ApplicationArea = All;
                    Caption = 'Item Description';
                    ToolTip = 'Specifies the item description that associated with the record.';
                }
                field("Coupled to Dataverse"; Rec."Coupled to Dataverse")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies that the item unit group is coupled to a unit group in Dynamics 365 Sales.';
                    Visible = CRMIntegrationEnabled;
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
                Image = Administration;
                Visible = CRMIntegrationEnabled;
                action(CRMGotoUnitGroup)
                {
                    ApplicationArea = Suite;
                    Caption = 'Unit Group';
                    Image = CoupledUnitOfMeasure;
                    ToolTip = 'Open the coupled Dynamics 365 Sales unit group.';

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
                        UnitGroup: Record "Unit Group";
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        UnitGroupRecordRef: RecordRef;
                    begin
                        CurrPage.SetSelectionFilter(UnitGroup);
                        UnitGroup.Next();

                        if UnitGroup.Count() = 1 then
                            CRMIntegrationManagement.UpdateOneNow(UnitGroup.RecordId)
                        else begin
                            UnitGroupRecordRef.GetTable(UnitGroup);
                            CRMIntegrationManagement.UpdateMultipleNow(UnitGroupRecordRef);
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
                        ToolTip = 'Create or modify the coupling to a Dynamics 365 Sales unit group.';

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
                        ToolTip = 'Delete the coupling to a Dynamics 365 Sales unit group.';

                        trigger OnAction()
                        var
                            UnitGroup: Record "Unit Group";
                            CRMCouplingManagement: Codeunit "CRM Coupling Management";
                            UnitGroupRecordRef: RecordRef;
                        begin
                            CurrPage.SetSelectionFilter(UnitGroup);
                            UnitGroupRecordRef.GetTable(UnitGroup);
                            CRMCouplingManagement.RemoveCoupling(UnitGroupRecordRef);
                        end;
                    }
                }
                action(ShowLog)
                {
                    ApplicationArea = Suite;
                    Caption = 'Synchronization Log';
                    Image = Log;
                    ToolTip = 'View integration synchronization jobs for the unit group table.';

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
                Visible = CRMIntegrationEnabled;

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
                actionref(CRMGotoUnitGroup_Promoted; CRMGotoUnitGroup)
                {
                }
                actionref(CRMSynchronizeNow_Promoted; CRMSynchronizeNow)
                {
                }
                actionref(ShowLog_Promoted; ShowLog)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CodeLbl := Rec.GetCode();
        SourceNameLbl := Rec.GetSourceName();
    end;

    trigger OnAfterGetCurrRecord()
    var
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
    begin
        CRMIsCoupledToRecord := CRMIntegrationEnabled;
        if CRMIsCoupledToRecord then
            CRMIsCoupledToRecord := CRMCouplingManagement.IsRecordCoupledToCRM(Rec.RecordId);
    end;

    trigger OnOpenPage()
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        CRMIntegrationEnabled := CRMIntegrationManagement.IsCRMIntegrationEnabled() and CRMIntegrationManagement.IsUnitGroupMappingEnabled();
    end;

    var
        CRMIntegrationEnabled: Boolean;
        CRMIsCoupledToRecord: Boolean;
        CodeLbl: Code[50];
        SourceNameLbl: Text[100];
}
