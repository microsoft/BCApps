// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Team;

using Microsoft.CRM.Campaign;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Opportunity;
using Microsoft.CRM.Segment;
using Microsoft.CRM.Task;
using Microsoft.Finance.Dimension;
using Microsoft.Integration.Dataverse;
using System.Email;
using System.Text;

page 14 "Salespersons/Purchasers"
{
    AdditionalSearchTerms = 'sales representative,salesperson';
    ApplicationArea = Basic, Suite;
    Caption = 'Salespeople/Purchasers';
    CardPageID = "Salesperson/Purchaser Card";
    Editable = false;
    PageType = List;
    AboutTitle = 'About Salespeople/Purchasers';
    AboutText = 'Set up and manage salespeople and purchasers by assigning codes, tracking contact details, calculating commissions, and linking them to customers, vendors, and opportunities for performance analysis and reporting in sales and purchasing processes.';
    SourceTable = "Salesperson/Purchaser";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code of the record.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Suite, RelationshipMgmt;
                    ToolTip = 'Specifies the name of the record.';
                }
                field("Commission %"; Rec."Commission %")
                {
                    ApplicationArea = Suite, RelationshipMgmt;
                    ToolTip = 'Specifies the percentage to use to calculate the salesperson''s commission.';
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = Suite, RelationshipMgmt;
                    ToolTip = 'Specifies the salesperson''s or purchaser''s telephone number.';
                }
                field("Privacy Blocked"; Rec."Privacy Blocked")
                {
                    ApplicationArea = Suite, RelationshipMgmt;
                    Importance = Additional;
                    ToolTip = 'Specifies whether to limit access to data for the data subject during daily operations. This is useful, for example, when protecting data from changes while it is under privacy review.';
                    Visible = false;
                }
                field("Coupled to Dataverse"; Rec."Coupled to Dataverse")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies that the salesperson/purchaser is coupled to a user in Dataverse.';
                    Visible = CRMIntegrationEnabled or CDSIntegrationEnabled;
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
            group("&Salesperson")
            {
                Caption = '&Salesperson';
                Image = SalesPerson;
                action("Tea&ms")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Tea&ms';
                    Image = TeamSales;
                    RunObject = Page "Salesperson Teams";
                    RunPageLink = "Salesperson Code" = field(Code);
                    RunPageView = sorting("Salesperson Code");
                    ToolTip = 'View or edit any teams that the salesperson/purchaser is a member of.';
                }
                action("Con&tacts")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Con&tacts';
                    Image = CustomerContact;
                    RunObject = Page "Contact List";
                    RunPageLink = "Salesperson Code" = field(Code);
                    RunPageView = sorting("Salesperson Code");
                    ToolTip = 'View a list of contacts that are associated with the salesperson/purchaser.';
                }
                group(Dimensions)
                {
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    action("Dimensions-Single")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Dimensions-Single';
                        Image = Dimensions;
                        RunObject = Page "Default Dimensions";
                        RunPageLink = "Table ID" = const(13),
                                      "No." = field(Code);
                        ShortCutKey = 'Alt+D';
                        ToolTip = 'View or edit the single set of dimensions that are set up for the selected record.';
                    }
                    action("Dimensions-&Multiple")
                    {
                        AccessByPermission = TableData Dimension = R;
                        ApplicationArea = Dimensions;
                        Caption = 'Dimensions-&Multiple';
                        Image = DimensionSets;
                        ToolTip = 'View or edit dimensions for a group of records. You can assign dimension codes to transactions to distribute costs and analyze historical information.';

                        trigger OnAction()
                        var
                            SalespersonPurchaser: Record "Salesperson/Purchaser";
                            DefaultDimMultiple: Page "Default Dimensions-Multiple";
                        begin
                            CurrPage.SetSelectionFilter(SalespersonPurchaser);
                            DefaultDimMultiple.SetMultiRecord(SalespersonPurchaser, Rec.FieldNo(Code));
                            DefaultDimMultiple.RunModal();
                        end;
                    }
                }
                action(Statistics)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Salesperson Statistics";
                    RunPageLink = Code = field(Code);
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
                action("C&ampaigns")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'C&ampaigns';
                    Image = Campaign;
                    RunObject = Page "Campaign List";
                    RunPageLink = "Salesperson Code" = field(Code);
                    RunPageView = sorting("Salesperson Code");
                    ToolTip = 'View or edit any campaigns that the salesperson/purchaser is assigned to.';
                }
                action("S&egments")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'S&egments';
                    Image = Segment;
                    RunObject = Page "Segment List";
                    RunPageLink = "Salesperson Code" = field(Code);
                    RunPageView = sorting("Salesperson Code");
                    ToolTip = 'View a list of all segments.';
                }
                separator(Action22)
                {
                    Caption = '';
                }
                action("Interaction Log E&ntries")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Interaction Log E&ntries';
                    Image = InteractionLog;
                    RunObject = Page "Interaction Log Entries";
                    RunPageLink = "Salesperson Code" = field(Code);
                    RunPageView = sorting("Salesperson Code");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View a list of the interactions that you have logged, for example, when you create an interaction, print a cover sheet, a sales order, and so on.';
                }
                action("Postponed &Interactions")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Postponed &Interactions';
                    Image = PostponedInteractions;
                    RunObject = Page "Postponed Interactions";
                    RunPageLink = "Salesperson Code" = field(Code);
                    RunPageView = sorting("Salesperson Code");
                    ToolTip = 'View postponed interactions for the salesperson/purchaser.';
                }
                action("T&asks")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'T&asks';
                    Image = TaskList;
                    RunObject = Page "Task List";
                    RunPageLink = "Salesperson Code" = field(Code),
                                  "System To-do Type" = filter(Organizer | "Salesperson Attendee");
                    RunPageView = sorting("Salesperson Code");
                    ToolTip = 'View tasks for the salesperson/purchaser.';
                }
                action("Oppo&rtunities")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Oppo&rtunities';
                    Image = OpportunitiesList;
                    RunObject = Page "Opportunity List";
                    RunPageLink = "Salesperson Code" = field(Code);
                    RunPageView = sorting("Salesperson Code");
                    ToolTip = 'View opportunities for the salesperson/purchaser.';
                }
            }
            group(ActionGroupCRM)
            {
                Caption = 'Dataverse';
                Visible = CDSIntegrationEnabled or CRMIntegrationEnabled;
                action(CRMGotoSystemUser)
                {
                    ApplicationArea = Suite;
                    Caption = 'User';
                    Image = CoupledUser;
                    ToolTip = 'Open the coupled Dataverse system user.';

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
                    ToolTip = 'Send or get updated data to or from Dataverse.';

                    trigger OnAction()
                    var
                        SalespersonPurchaser: Record "Salesperson/Purchaser";
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        SalespersonPurchaserRecordRef: RecordRef;
                    begin
                        CurrPage.SetSelectionFilter(SalespersonPurchaser);
                        SalespersonPurchaser.Next();

                        if SalespersonPurchaser.Count = 1 then
                            CRMIntegrationManagement.UpdateOneNow(SalespersonPurchaser.RecordId)
                        else begin
                            SalespersonPurchaserRecordRef.GetTable(SalespersonPurchaser);
                            CRMIntegrationManagement.UpdateMultipleNow(SalespersonPurchaserRecordRef);
                        end
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
                        ToolTip = 'Create or modify the coupling to a Dataverse user.';

                        trigger OnAction()
                        var
                            CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        begin
                            CRMIntegrationManagement.DefineCoupling(Rec.RecordId);
                        end;
                    }
                    action(MatchBasedCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = IM;
                        ApplicationArea = Suite;
                        Caption = 'Match-Based Coupling';
                        Image = CoupledContactPerson;
                        ToolTip = 'Couple salespeople to users in Dataverse based on criteria.';

                        trigger OnAction()
                        var
                            SalespersonPurchaser: Record "Salesperson/Purchaser";
                            CRMIntegrationManagement: Codeunit "CRM Integration Management";
                            RecRef: RecordRef;
                        begin
                            CurrPage.SetSelectionFilter(SalespersonPurchaser);
                            RecRef.GetTable(SalespersonPurchaser);
                            CRMIntegrationManagement.MatchBasedCoupling(RecRef);
                        end;
                    }
                    action(DeleteCRMCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = D;
                        ApplicationArea = Suite;
                        Caption = 'Delete Coupling';
                        Enabled = CRMIsCoupledToRecord;
                        Image = UnLinkAccount;
                        ToolTip = 'Delete the coupling to a Dataverse user.';

                        trigger OnAction()
                        var
                            SalespersonPurchaser: Record "Salesperson/Purchaser";
                            CRMCouplingManagement: Codeunit "CRM Coupling Management";
                            RecRef: RecordRef;
                        begin
                            CurrPage.SetSelectionFilter(SalespersonPurchaser);
                            RecRef.GetTable(SalespersonPurchaser);
                            CRMCouplingManagement.RemoveCoupling(RecRef);
                        end;
                    }
                }
                action(ShowLog)
                {
                    ApplicationArea = Suite;
                    Caption = 'Synchronization Log';
                    Image = Log;
                    ToolTip = 'View integration synchronization jobs for the salesperson/purchaser table.';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.ShowLog(Rec.RecordId);
                    end;
                }
            }
            group(History)
            {
                Caption = 'History';
                Image = History;
                action("Sent Emails")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sent Emails';
                    Image = ShowList;
                    ToolTip = 'View a list of emails that you have sent to this salesperson/purchaser.';

                    trigger OnAction()
                    var
                        Email: Codeunit Email;
                    begin
                        Email.OpenSentEmails(Database::"Salesperson/Purchaser", Rec.SystemId);
                    end;
                }
            }
        }
        area(processing)
        {
            action(CreateInteraction)
            {
                AccessByPermission = TableData Attachment = R;
                ApplicationArea = All;
                Caption = 'Create &Interaction';
                Ellipsis = true;
                Image = CreateInteraction;
                ToolTip = 'Use a batch job to help you create interactions for the involved salespeople or purchasers.';
                Visible = CreateInteractionVisible;

                trigger OnAction()
                begin
                    Rec.CreateInteraction();
                end;
            }
            action(Email)
            {
                ApplicationArea = All;
                Caption = 'Send Email';
                Image = Email;
                ToolTip = 'Send an email to this person.';
                Enabled = CanSendEmail;

                trigger OnAction()
                var
                    TempEmailItem: Record "Email Item" temporary;
                    EmailScenario: Enum "Email Scenario";
                begin
                    TempEmailItem.AddSourceDocument(Database::"Salesperson/Purchaser", Rec.SystemId);
                    TempEmailitem."Send to" := Rec."E-Mail";
                    TempEmailItem.Send(false, EmailScenario::Default);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(CreateInteraction_Promoted; CreateInteraction)
                {
                }
                actionref(Email_Promoted; Email)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Salesperson', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(Statistics_Promoted; Statistics)
                {
                }
                group(Category_Dimensions)
                {
                    Caption = 'Dimensions';
                    ShowAs = SplitButton;

                    actionref("Dimensions-&Multiple_Promoted"; "Dimensions-&Multiple")
                    {
                    }
                    actionref("Dimensions-Single_Promoted"; "Dimensions-Single")
                    {
                    }
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Synchronize)
            {
                Caption = 'Synchronize';
                Visible = CRMIntegrationEnabled or CDSIntegrationEnabled;

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
                actionref(CRMGotoSystemUser_Promoted; CRMGotoSystemUser)
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

    trigger OnAfterGetCurrRecord()
    var
        Record: Record "Salesperson/Purchaser";
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
    begin
        if CDSIntegrationEnabled or CRMIntegrationEnabled then
            CRMIsCoupledToRecord := CRMCouplingManagement.IsRecordCoupledToCRM(Rec.RecordId);

        CurrPage.SetSelectionFilter(Record);
        CanSendEmail := Record.Count() = 1;
    end;

    trigger OnInit()
    var
        SegmentLine: Record "Segment Line";
    begin
        CreateInteractionVisible := SegmentLine.ReadPermission;
    end;

    trigger OnOpenPage()
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        CDSIntegrationEnabled := CRMIntegrationManagement.IsCDSIntegrationEnabled();
        CRMIntegrationEnabled := CRMIntegrationManagement.IsCRMIntegrationEnabled();
    end;

    var
        CanSendEmail: Boolean;
        CreateInteractionVisible: Boolean;
        CDSIntegrationEnabled: Boolean;
        CRMIntegrationEnabled: Boolean;
        CRMIsCoupledToRecord: Boolean;

    procedure GetSelectionFilter(): Text
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        CurrPage.SetSelectionFilter(SalespersonPurchaser);
        exit(SelectionFilterManagement.GetSelectionFilterForSalesPersonPurchaser(SalespersonPurchaser));
    end;
}

