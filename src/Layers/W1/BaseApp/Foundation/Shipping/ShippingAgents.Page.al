// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Shipping;

using Microsoft.Integration.Dataverse;

page 428 "Shipping Agents"
{
    AdditionalSearchTerms = 'transportation,carrier';
    ApplicationArea = Suite;
    Caption = 'Shipping Agents';
    PageType = List;
    SourceTable = "Shipping Agent";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a shipping agent code.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a description of the shipping agent.';
                }
                field("Internet Address"; Rec."Internet Address")
                {
                    Caption = 'Package Tracking URL';
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the URL for the shipping agent''s package tracking system. To let users track specific packages, add %1 to the URL. When users track a package, the tracking number will replace %1. Example, http://www.providername.com/track?awb=%1.';
                }
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the account number that the shipping agent has assigned to your company.';
                    Visible = false;
                }
                field("Coupled to Dataverse"; CDSIsCoupledToRecord)
                {
                    ApplicationArea = All;
                    Caption = 'Coupled to Dataverse';
                    ToolTip = 'Specifies that the shipping agent is coupled to a shipping method in Dataverse.';
                    Visible = CDSIntegrationEnabled;
                    Editable = false;
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
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(ShippingAgentServices)
                {
                    ApplicationArea = Suite;
                    Caption = 'Shipping A&gent Services';
                    Image = CheckList;
                    RunObject = Page "Shipping Agent Services";
                    RunPageLink = "Shipping Agent Code" = field(Code);
                    ToolTip = 'View the types of services that your shipping agent can offer you and their shipping time.';
                }
            }
            group(ActionGroupCRM)
            {
                Caption = 'Dataverse';
                Image = Administration;
                Visible = CDSIntegrationEnabled;
                action(CRMSynchronizeNow)
                {
                    AccessByPermission = TableData "CRM Integration Record" = IM;
                    ApplicationArea = Suite;
                    Caption = 'Synchronize';
                    Image = Refresh;
                    ToolTip = 'Send or get updated data to or from Dataverse.';

                    trigger OnAction()
                    var
                        ShippingAgent: Record "Shipping Agent";
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        ShippingAgentRecordRef: RecordRef;
                    begin
                        CurrPage.SetSelectionFilter(ShippingAgent);
                        ShippingAgentRecordRef.GetTable(ShippingAgent);
                        CRMIntegrationManagement.UpdateMultipleNow(ShippingAgentRecordRef, true);
                    end;
                }
                group(Coupling)
                {
                    Caption = 'Coupling', Comment = 'Coupling is a noun';
                    Image = LinkAccount;
                    ToolTip = 'Create, change, or delete a coupling between the Business Central record and a Dataverse record.';
                    action(ManageCRMCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = IM;
                        ApplicationArea = Suite;
                        Caption = 'Set Up Coupling';
                        Image = LinkAccount;
                        ToolTip = 'Create or modify the coupling to a Dataverse Shipping Method.';

                        trigger OnAction()
                        var
                            CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        begin
                            CRMIntegrationManagement.DefineOptionMapping(Rec.RecordId);
                        end;
                    }
                    action(MatchBasedCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = IM;
                        ApplicationArea = Suite;
                        Caption = 'Match-Based Coupling';
                        Image = CoupledUnitOfMeasure;
                        ToolTip = 'Couple shipping agent in Dataverse based on criteria.';

                        trigger OnAction()
                        var
                            ShippingAgent: Record "Shipping Agent";
                            CRMIntegrationManagement: Codeunit "CRM Integration Management";
                            RecRef: RecordRef;
                        begin
                            CurrPage.SetSelectionFilter(ShippingAgent);
                            RecRef.GetTable(ShippingAgent);
                            CRMIntegrationManagement.MatchBasedCoupling(RecRef);
                        end;
                    }
                    action(DeleteCRMCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = D;
                        ApplicationArea = Suite;
                        Caption = 'Delete Coupling';
                        Enabled = CDSIsCoupledToRecord;
                        Image = UnLinkAccount;
                        ToolTip = 'Delete the coupling to a Dataverse Shipping Method.';

                        trigger OnAction()
                        var
                            ShippingAgent: Record "Shipping Agent";
                            CRMIntegrationManagement: Codeunit "CRM Integration Management";
                            RecRef: RecordRef;
                        begin
                            CurrPage.SetSelectionFilter(ShippingAgent);
                            RecRef.GetTable(ShippingAgent);
                            CRMIntegrationManagement.RemoveOptionMapping(RecRef);
                        end;
                    }
                }
                action(ShowLog)
                {
                    ApplicationArea = Suite;
                    Caption = 'Synchronization Log';
                    Image = Log;
                    ToolTip = 'View integration synchronization jobs for the shipping agent table.';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.ShowOptionLog(Rec.RecordId);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Shipping_Agent)
            {
                Caption = 'Shipping Agent';

                actionref(ShippingAgentServices_Promoted; ShippingAgentServices)
                {
                }
            }
            group(Category_Synchronize)
            {
                Caption = 'Synchronize';
                Visible = CDSIntegrationEnabled;

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
                    actionref(MatchBasedCoupling_Promoted; MatchBasedCoupling)
                    {
                    }
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
    var
        CRMOptionMapping: Record "CRM Option Mapping";
    begin
        CDSIsCoupledToRecord := CDSIntegrationEnabled;
        if CDSIsCoupledToRecord then begin
            CRMOptionMapping.SetRange("Record ID", Rec.RecordId);
            CDSIsCoupledToRecord := not CRMOptionMapping.IsEmpty();
        end;
    end;

    trigger OnOpenPage()
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        CDSIntegrationEnabled := CRMIntegrationManagement.IsCDSIntegrationEnabled();
    end;

    var
        CDSIntegrationEnabled: Boolean;
        CDSIsCoupledToRecord: Boolean;
}
