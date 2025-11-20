// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Opportunity;

using Microsoft.CRM.Campaign;
using Microsoft.CRM.Comment;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Reports;
using Microsoft.CRM.Segment;
using Microsoft.CRM.Task;
using Microsoft.CRM.Team;
using Microsoft.Foundation.Attachment;
using Microsoft.Integration.Dataverse;

page 5123 "Opportunity List"
{
    AdditionalSearchTerms = 'prospects';
    ApplicationArea = RelationshipMgmt;
    Caption = 'Opportunities';
    CardPageID = "Opportunity Card";
    DataCaptionExpression = Caption();
    Editable = false;
    PageType = List;
    AboutTitle = 'About Opportunities';
    AboutText = 'Track, create, and manage sales opportunities by linking them to contacts, salespeople, campaigns, and sales documents, updating their progress through sales cycle stages, and recording outcomes such as won or lost with associated values and reasons.';
    SourceTable = Opportunity;
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Closed; Rec.Closed)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies that the opportunity is closed.';
                }
                field("Creation Date"; Rec."Creation Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date that the opportunity was created.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the opportunity.';
                }
                field("Contact No."; Rec."Contact No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of the contact that this opportunity is linked to.';
                }
                field("Contact Company No."; Rec."Contact Company No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of the company that is linked to this opportunity.';
                    Visible = false;
                }
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code of the salesperson that is responsible for the opportunity.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the status of the opportunity. There are four options:';
                }
                field("Sales Cycle Code"; Rec."Sales Cycle Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the code of the sales cycle that the opportunity is linked to.';
                    Visible = false;
                }
                field(CurrSalesCycleStage; CurrSalesCycleStage)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Current Sales Cycle Stage';
                    ToolTip = 'Specifies the current sales cycle stage of the opportunity.';
                }
                field("Campaign No."; Rec."Campaign No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of the campaign to which this opportunity is linked.';
                }
                field("Campaign Description"; Rec."Campaign Description")
                {
                    ApplicationArea = RelationshipMgmt;
                    DrillDown = false;
                    ToolTip = 'Specifies the description of the campaign to which the opportunity is linked. The program automatically fills in this field when you have entered a number in the Campaign No. field.';
                }
                field("Sales Document Type"; Rec."Sales Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the sales document (Quote, Order, Posted Invoice). The combination of Sales Document No. and Sales Document Type specifies which sales document is assigned to the opportunity.';
                }
                field("Sales Document No."; Rec."Sales Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the sales document that has been created for this opportunity.';
                }
                field("Estimated Closing Date"; Rec."Estimated Closing Date")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the estimated closing date of the opportunity.';
                }
                field("Estimated Value (LCY)"; Rec."Estimated Value (LCY)")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the estimated value of the opportunity.';
                }
                field("Calcd. Current Value (LCY)"; Rec."Calcd. Current Value (LCY)")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the current calculated value of the opportunity.';
                }
                field("Coupled to Dataverse"; Rec."Coupled to Dataverse")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies that the opportunity is coupled to an opportunity in Dynamics 365 Sales.';
                    Visible = CRMIntegrationEnabled;
                }
            }
            group(Control45)
            {
                ShowCaption = false;
                field("Contact Name"; Rec."Contact Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Contact Name';
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the contact to which this opportunity is linked. The program automatically fills in this field when you have entered a number in the No. field.';
                }
                field("Contact Company Name"; Rec."Contact Company Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the company of the contact person to which this opportunity is linked. The program automatically fills in this field when you have entered a number in the Contact Company No. field.';
                }
            }
        }
        area(factboxes)
        {
            part(Control5; "Opportunity Statistics FactBox")
            {
                ApplicationArea = RelationshipMgmt;
                SubPageLink = "No." = field("No.");
            }
            part("Attached Documents List"; "Doc. Attachment List Factbox")
            {
                ApplicationArea = All;
                Caption = 'Documents';
                UpdatePropagation = Both;
                SubPageLink = "Table ID" = const(Database::Opportunity),
                              "No." = field("No.");
            }
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
            group(Opportunity)
            {
                Caption = 'Oppo&rtunity';
                Image = Opportunity;
                action(Statistics)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Opportunity Statistics";
                    RunPageLink = "No." = field("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
                action("Interaction Log E&ntries")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Interaction Log E&ntries';
                    Image = InteractionLog;
                    RunObject = Page "Interaction Log Entries";
                    RunPageLink = "Opportunity No." = field("No.");
                    RunPageView = sorting("Opportunity No.", Date);
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View a list of the interactions that you have logged, for example, when you create an interaction, print a cover sheet, a sales order, and so on.';
                }
                action("Postponed &Interactions")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Postponed &Interactions';
                    Image = PostponedInteractions;
                    RunObject = Page "Postponed Interactions";
                    RunPageLink = "Opportunity No." = field("No.");
                    RunPageView = sorting("Opportunity No.", Date);
                    Scope = Repeater;
                    ToolTip = 'View postponed interactions for opportunities.';
                }
                action("T&asks")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'T&asks';
                    Image = TaskList;
                    RunObject = Page "Task List";
                    RunPageLink = "Opportunity No." = field("No."),
                                  "System To-do Type" = filter(Organizer);
                    RunPageView = sorting("Opportunity No.");
                    ToolTip = 'View all marketing tasks that involve the opportunity. ';
                }
                action("Co&mments")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Rlshp. Mgt. Comment Sheet";
                    RunPageLink = "Table Name" = const(Opportunity),
                                  "No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action("Show Sales Quote")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Show Sales Quote';
                    Image = Quote;
                    Scope = Repeater;
                    ToolTip = 'Show the assigned sales quote.';

                    trigger OnAction()
                    begin
                        Rec.ShowSalesQuoteWithCheck();
                    end;
                }
            }
            group(ActionGroupCRM)
            {
                Caption = 'Dynamics 365 Sales';
                Visible = CRMIntegrationEnabled;
                action(CRMGotoOpportunity)
                {
                    ApplicationArea = Suite;
                    Caption = 'Opportunity';
                    Image = CoupledContactPerson;
                    ToolTip = 'Open the coupled Dynamics 365 Sales opportunity.';

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
                    ToolTip = 'Send or get updated data to or from Dynamics 365 Sales.';

                    trigger OnAction()
                    var
                        Opportunity: Record Opportunity;
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        OpportunityRecordRef: RecordRef;
                    begin
                        CurrPage.SetSelectionFilter(Opportunity);
                        Opportunity.Next();

                        if Opportunity.Count = 1 then
                            CRMIntegrationManagement.UpdateOneNow(Opportunity.RecordId)
                        else begin
                            OpportunityRecordRef.GetTable(Opportunity);
                            CRMIntegrationManagement.UpdateMultipleNow(OpportunityRecordRef);
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
                        ToolTip = 'Create or modify the coupling to a Dynamics 365 Sales opportunity.';

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
                        Image = CoupledOpportunity;
                        ToolTip = 'Couple opportunities to opportunities in Dynamics 365 Sales based on criteria.';

                        trigger OnAction()
                        var
                            Opportunity: Record Opportunity;
                            CRMIntegrationManagement: Codeunit "CRM Integration Management";
                            RecRef: RecordRef;
                        begin
                            CurrPage.SetSelectionFilter(Opportunity);
                            RecRef.GetTable(Opportunity);
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
                        ToolTip = 'Delete the coupling to a Dynamics 365 Sales opportunity.';

                        trigger OnAction()
                        var
                            Opportunity: Record Opportunity;
                            CRMCouplingManagement: Codeunit "CRM Coupling Management";
                            RecRef: RecordRef;
                        begin
                            CurrPage.SetSelectionFilter(Opportunity);
                            RecRef.GetTable(Opportunity);
                            CRMCouplingManagement.RemoveCoupling(RecRef);
                        end;
                    }
                }
                action(ShowLog)
                {
                    ApplicationArea = Suite;
                    Caption = 'Synchronization Log';
                    Image = Log;
                    ToolTip = 'View integration synchronization jobs for the opportunity table.';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.ShowLog(Rec.RecordId);
                    end;
                }
            }
        }
        area(processing)
        {
            group(Functions)
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(Update)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Update';
                    Enabled = OppInProgress;
                    Image = Refresh;
                    Scope = Repeater;
                    ToolTip = 'Update all the actions that are related to your opportunities.';

                    trigger OnAction()
                    begin
                        Rec.UpdateOpportunity();
                    end;
                }
                action(Close)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Close';
                    Enabled = OppNotStarted or OppInProgress;
                    Image = Close;
                    Scope = Repeater;
                    ToolTip = 'Close all the actions that are related to your opportunities.';

                    trigger OnAction()
                    begin
                        Rec.CloseOpportunity();
                    end;
                }
                action("Activate First Stage")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Activate First Stage';
                    Enabled = OppNotStarted;
                    Image = "Action";
                    Scope = Repeater;
                    ToolTip = 'Specify if the opportunity is to be activated. The status is set to In Progress.';

                    trigger OnAction()
                    begin
                        Rec.StartActivateFirstStage();
                    end;
                }
                action(CreateSalesQuote)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Create Sales &Quote';
                    Enabled = OppInProgress;
                    Image = Allocate;
                    Scope = Repeater;
                    ToolTip = 'Create a new sales quote with the opportunity inserted as the customer.';

                    trigger OnAction()
                    begin
                        Rec.CreateQuote();
                    end;
                }
                action("Print Details")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Print Details';
                    Image = Print;
                    ToolTip = 'View information about your sales stages, activities and planned tasks for an opportunity.';

                    trigger OnAction()
                    var
                        Opp: Record Opportunity;
                    begin
                        Opp := Rec;
                        Opp.SetRecFilter();
                        REPORT.Run(REPORT::"Opportunity - Details", true, false, Opp);
                    end;
                }
                action("Create &Interaction")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Create &Interaction';
                    Image = CreateInteraction;
                    Scope = Repeater;
                    ToolTip = 'Create an interaction with a specified opportunity.';

                    trigger OnAction()
                    var
                        TempSegmentLine: Record "Segment Line" temporary;
                    begin
                        TempSegmentLine.CreateInteractionFromOpp(Rec);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("Activate First Stage_Promoted"; "Activate First Stage")
                {
                }
                actionref(Close_Promoted; Close)
                {
                }
                actionref(Update_Promoted; Update)
                {
                }
                actionref("Show Sales Quote_Promoted"; "Show Sales Quote")
                {
                }
                actionref(CreateSalesQuote_Promoted; CreateSalesQuote)
                {
                }
                actionref("Create &Interaction_Promoted"; "Create &Interaction")
                {
                }
                group(Category_Synchronize)
                {
                    Caption = 'Synchronize';
                    Visible = CRMIntegrationEnabled;

                    actionref(CRMGotoOpportunity_Promoted; CRMGotoOpportunity)
                    {
                    }
                    actionref(CRMSynchronizeNow_Promoted; CRMSynchronizeNow)
                    {
                    }
                    actionref(ShowLog_Promoted; ShowLog)
                    {
                    }
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
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnAfterGetCurrRecord(Rec, OppNotStarted, OppInProgress, IsHandled);
        if IsHandled then
            exit;

        Rec.CalcFields("Contact Name", "Contact Company Name");
        OppNotStarted := Rec.Status = Rec.Status::"Not Started";
        OppInProgress := Rec.Status = Rec.Status::"In Progress";
    end;

    trigger OnAfterGetRecord()
    var
        SalesCycleStage: Record "Sales Cycle Stage";
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
    begin
        Rec.CalcFields("Current Sales Cycle Stage");
        CurrSalesCycleStage := '';
        if SalesCycleStage.Get(Rec."Sales Cycle Code", Rec."Current Sales Cycle Stage") then
            CurrSalesCycleStage := SalesCycleStage.Description;

        if CRMIntegrationEnabled then
            CRMIsCoupledToRecord := CRMCouplingManagement.IsRecordCoupledToCRM(Rec.RecordId);
    end;

    trigger OnFindRecord(Which: Text): Boolean
    var
        RecordsFound: Boolean;
    begin
        RecordsFound := Rec.Find(Which);
        exit(RecordsFound);
    end;

    trigger OnOpenPage()
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        CurrPage.Editable := true;
        CRMIntegrationEnabled := CRMIntegrationManagement.IsCRMIntegrationEnabled();
    end;

    var
        OpportunitiesTxt: Label 'Opportunities';
        OppNotStarted: Boolean;
        OppInProgress: Boolean;
        CRMIntegrationEnabled: Boolean;
        CRMIsCoupledToRecord: Boolean;
        CurrSalesCycleStage: Text;

    procedure Caption(): Text
    var
        CaptionStr: Text;
    begin
        case true of
            BuildCaptionContact(CaptionStr, Rec.GetFilter("Contact Company No.")),
            BuildCaptionContact(CaptionStr, Rec.GetFilter("Contact No.")),
            BuildCaptionSalespersonPurchaser(CaptionStr, Rec.GetFilter("Salesperson Code")),
            BuildCaptionCampaign(CaptionStr, Rec.GetFilter("Campaign No.")),
            BuildCaptionSegmentHeader(CaptionStr, Rec.GetFilter("Segment No.")):
                exit(CaptionStr);
        end;

        exit(OpportunitiesTxt);
    end;

    local procedure BuildCaptionContact(var CaptionText: Text[260]; "Filter": Text): Boolean
    var
        Contact: Record Contact;
    begin
        exit(BuildCaption(CaptionText, Contact, Filter, Contact.FieldNo(Contact."No."), Contact.FieldNo(Name)));
    end;

    local procedure BuildCaptionSalespersonPurchaser(var CaptionText: Text[260]; "Filter": Text): Boolean
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        exit(BuildCaption(CaptionText, SalespersonPurchaser, Filter, SalespersonPurchaser.FieldNo(Code), SalespersonPurchaser.FieldNo(Name)));
    end;

    local procedure BuildCaptionCampaign(var CaptionText: Text[260]; "Filter": Text): Boolean
    var
        Campaign: Record Campaign;
    begin
        exit(BuildCaption(CaptionText, Campaign, Filter, Campaign.FieldNo("No."), Campaign.FieldNo(Description)));
    end;

    local procedure BuildCaptionSegmentHeader(var CaptionText: Text[260]; "Filter": Text): Boolean
    var
        SegmentHeader: Record "Segment Header";
    begin
        exit(BuildCaption(CaptionText, SegmentHeader, Filter, SegmentHeader.FieldNo("No."), SegmentHeader.FieldNo(Description)));
    end;

    local procedure BuildCaption(var CaptionText: Text[260]; RecVar: Variant; "Filter": Text; IndexFieldNo: Integer; TextFieldNo: Integer): Boolean
    var
        RecRef: RecordRef;
        IndexFieldRef: FieldRef;
        TextFieldRef: FieldRef;
    begin
        Filter := DelChr(Filter, '<>', '''');
        if Filter <> '' then begin
            RecRef.GetTable(RecVar);
            IndexFieldRef := RecRef.Field(IndexFieldNo);
            IndexFieldRef.SetFilter(Filter);
            if RecRef.FindFirst() then begin
                TextFieldRef := RecRef.Field(TextFieldNo);
                CaptionText := CopyStr(Format(IndexFieldRef.Value) + ' ' + Format(TextFieldRef.Value), 1, MaxStrLen(CaptionText));
            end;
        end;

        exit(Filter <> '');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnAfterGetCurrRecord(var Opportunity: Record Opportunity; var OppNotStarted: Boolean; var OppInProgress: Boolean; var IsHandled: Boolean)
    begin
    end;
}

