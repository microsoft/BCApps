// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Segment;

using Microsoft.CRM.Campaign;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Opportunity;

page 5147 "Make Phone Call"
{
    Caption = 'Make Phone Call';
    DataCaptionExpression = Caption();
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = NavigatePage;
    SourceTable = "Segment Line";

    layout
    {
        area(content)
        {
            group(Step1)
            {
                Visible = Step1Visible;
                group("Phone Call")
                {
                    Caption = 'Who do you want to call?';
                    field("Wizard Contact Name"; Rec."Wizard Contact Name")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Contact Name';
                        Editable = WizardContactNameEditable;
                        Importance = Promoted;
                        ToolTip = 'Specifies a contact name from the wizard.';
                    }
                    field("Contact Via"; Rec."Contact Via")
                    {
                        ApplicationArea = RelationshipMgmt;
                        AssistEdit = true;
                        Caption = 'Contact Phone No.';
                        ExtendedDatatype = PhoneNo;
                        Importance = Promoted;
                        ShowMandatory = true;
                        ToolTip = 'Specifies the telephone number you used when calling the contact, or the email address you used when sending an email to the contact.';

                        trigger OnAssistEdit()
                        var
                            TAPIManagement: Codeunit TAPIManagement;
                        begin
                            Clear(TAPIManagement);
                            Rec."Contact Via" :=
                              CopyStr(TAPIManagement.ShowNumbers(Rec."Contact No.", Rec."Contact Alt. Address Code"), 1, MaxStrLen(Rec."Contact Via"));
                        end;
                    }
                    field(Description; Rec.Description)
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Phone Call Description';
                        Importance = Promoted;
                        ShowMandatory = true;
                        ToolTip = 'Specifies the description of the segment line.';
                    }
                    field(ShowMoreLess1; GetShowMoreLessLbl(ShowLessStep1))
                    {
                        ShowCaption = false;
                        ApplicationArea = RelationshipMgmt;
                        ToolTip = 'Show more/fewer fields.';

                        trigger OnDrillDown()
                        begin
                            ShowLessStep1 := not ShowLessStep1;
                            CurrPage.Update(true);
                        end;
                    }
                    group(AdditionalFieldsStep1)
                    {
                        ShowCaption = false;
                        Visible = ShowLessStep1;
                        field("Salesperson Code"; Rec."Salesperson Code")
                        {
                            ApplicationArea = Suite, RelationshipMgmt;
                            Caption = 'Salesperson Code';
                            Importance = Additional;
                            ShowMandatory = true;
                            ToolTip = 'Specifies the code of the salesperson responsible for this segment line and/or interaction.';
                        }
                        field("Initiated By"; Rec."Initiated By")
                        {
                            ApplicationArea = RelationshipMgmt;
                            Caption = 'Initiated By';
                            Importance = Additional;
                            ToolTip = 'Specifies whether the interaction recorded for this segment line was initiated by your company or by one of your contacts. The Us option indicates that your company was the initiator; the Them option indicates that a contact was the initiator.';
                        }
                        field(Date; Rec.Date)
                        {
                            ApplicationArea = RelationshipMgmt;
                            Caption = 'Date';
                            Importance = Additional;
                            ToolTip = 'Specifies the date when the contact was called.';
                        }
                        field("Time of Interaction"; Rec."Time of Interaction")
                        {
                            ApplicationArea = RelationshipMgmt;
                            Caption = 'Time of Interaction';
                            Importance = Additional;
                            ToolTip = 'Specifies the time when the call to the contact started.';
                        }
                    }
                }
            }
            group(Step2)
            {
                Visible = Step2Visible;
                group("Phone Call Result")
                {
                    Caption = 'What was the result of the call?';
                    field(Description2; Rec.Description)
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Phone Call Result Description';
                        ToolTip = 'Specifies the description of the segment line.';
                    }
                    field(Evaluation; Rec.Evaluation)
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Phone Call Evaluation';
                        ToolTip = 'Specifies the evaluation of the interaction involving the contact in the segment.';
                    }
                    field(ShowMoreLess2; GetShowMoreLessLbl(ShowLessStep2))
                    {
                        ShowCaption = false;
                        ApplicationArea = RelationshipMgmt;
                        ToolTip = 'Show more/fewer fields.';

                        trigger OnDrillDown()
                        begin
                            ShowLessStep2 := not ShowLessStep2;
                            CurrPage.Update(true);
                        end;
                    }
                    group(AdditionalFieldsStep2)
                    {
                        ShowCaption = false;
                        Visible = ShowLessStep2;
                        field("Cost (LCY)"; Rec."Cost (LCY)")
                        {
                            ApplicationArea = RelationshipMgmt;
                            Caption = 'Cost (LCY)';
                            Importance = Additional;
                            ToolTip = 'Specifies the cost of the interaction with the contact that this segment line applies to.';
                        }
                        field("Duration (Min.)"; Rec."Duration (Min.)")
                        {
                            ApplicationArea = RelationshipMgmt;
                            Caption = 'Duration (Min.)';
                            ToolTip = 'Specifies the duration of the interaction with the contact to which this segment line applies.';
                        }
                        field("Interaction Successful"; Rec."Interaction Successful")
                        {
                            ApplicationArea = RelationshipMgmt;
                            Caption = 'Successful Attempt';
                            ToolTip = 'Specifies if the interaction was successful. Clear this check box to indicate that the interaction was not a success.';
                        }
                    }
                }
            }
            group(Step3)
            {
                Visible = Step3Visible;
                group(Details)
                {
                    Caption = 'What was the call related to?';
                    field("Campaign Description"; Rec."Campaign Description")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Campaign Description';
                        Editable = CampaignDescriptionEditable;
                        Importance = Promoted;
                        Lookup = false;
                        TableRelation = Campaign;
                        ToolTip = 'Specifies a description of the campaign that is related to the segment. The description is copied from the campaign card.';

                        trigger OnAssistEdit()
                        var
                            Campaign: Record Campaign;
                        begin
                            if Campaign.Get(Rec."Campaign No.") then;
                            if PAGE.RunModal(0, Campaign) = ACTION::LookupOK then begin
                                Rec.Validate("Campaign No.", Campaign."No.");
                                Rec."Campaign Description" := Campaign.Description;
                                CurrPage.SetSelectionFilter(Rec);
                            end;
                        end;
                    }
                    field("Campaign Target"; Rec."Campaign Target")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Campaign Target';
                        Editable = CampaignTargetEditable;
                        Importance = Additional;
                        ToolTip = 'Specifies that the segment involved in this interaction is the target of a campaign. This is used to measure the response rate of a campaign.';
                    }
                    field("Campaign Response"; Rec."Campaign Response")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Campaign Response';
                        Editable = CampaignResponseEditable;
                        Importance = Additional;
                        ToolTip = 'Specifies that the interaction created for the segment is the response to a campaign. For example, coupons that are sent as a response to a campaign.';
                    }
                    field("Opportunity Description"; Rec."Opportunity Description")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Opportunity Description';
                        Editable = OpportunityDescriptionEditable;
                        Importance = Promoted;
                        Lookup = false;
                        TableRelation = Opportunity;
                        ToolTip = 'Specifies a description of the opportunity that is related to the segment. The description is copied from the opportunity card.';

                        trigger OnAssistEdit()
                        var
                            Opportunity: Record Opportunity;
                        begin
                            Rec.FilterContactCompanyOpportunities(Opportunity);
                            if PAGE.RunModal(0, Opportunity) = ACTION::LookupOK then begin
                                Rec.Validate("Opportunity No.", Opportunity."No.");
                                Rec."Opportunity Description" := Opportunity.Description;
                            end;
                        end;
                    }
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Make Phone Call")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Make Phone Call';
                Image = Calls;
                Visible = CallEnable;
                InFooterBar = true;
                ToolTip = 'Call the selected contact.';

                trigger OnAction()
                begin
                    Rec.CheckPhoneCallStatus();
                    HyperLink(StrSubstNo('tel:%1', Rec."Contact Via"));
                end;
            }
            action(Finish)
            {
                ApplicationArea = RelationshipMgmt;
                Image = Approve;
                Visible = FinishEnable;
                InFooterBar = true;
                ToolTip = 'Create an opportunity if needed, log the phone call interaction, and close the page.';

                trigger OnAction()
                begin
                    if Rec."Opportunity No." = '' then
                        if Confirm(CreateOpportunityQst) then
                            Rec.Validate("Opportunity No.", Rec.CreateOpportunity());
                    LogCall();
                    CurrPage.Close();
                end;
            }
            action(OpenCommentsPage)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Co&mments';
                Image = ViewComments;
                InFooterBar = true;
                ToolTip = 'View or add comments for the record.';

                trigger OnAction()
                begin
                    Rec.ShowComment();
                end;
            }
            action(Back)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = '&Back';
                Visible = BackEnable;
                Image = PreviousRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    ShowStep(false);
                    WizardStep -= 1;
                    ShowStep(true);
                    CurrPage.Update(true);
                end;
            }
            action(Next)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = '&Next';
                Visible = NextEnable;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    ShowStep(false);
                    WizardStep += 1;
                    ShowStep(true);
                    CurrPage.Update(true);
                end;
            }
        }
    }

    trigger OnInit()
    begin
        CampaignTargetEditable := true;
        CampaignResponseEditable := true;
        OpportunityDescriptionEditable := true;
        CampaignDescriptionEditable := true;

        NextEnable := true;
        WizardStep := 1;
    end;

    trigger OnOpenPage()
    var
        Campaign: Record Campaign;
    begin
        CampaignDescriptionEditable := false;
        OpportunityDescriptionEditable := false;
        WizardContactNameEditable := (Rec.GetFilter("Contact No.") = '') and (Rec.GetFilter("Contact Company No.") = '');
        if Campaign.Get(Rec.GetFilter("Campaign No.")) then begin
            CampaignResponseEditable := false;
            CampaignTargetEditable := false;
        end;
        ShowStep(true);
    end;

    var
        ShowMoreLbl: Label 'Show more';
        ShowLessLbl: Label 'Show less';
        UntitledTxt: Label 'untitled';
        WizardStep: Integer;
        ShowLessStep1: Boolean;
        ShowLessStep2: Boolean;
        Step1Visible: Boolean;
        Step2Visible: Boolean;
        Step3Visible: Boolean;
        NextEnable: Boolean;
        BackEnable: Boolean;
        CallEnable: Boolean;
        FinishEnable: Boolean;
        CampaignDescriptionEditable: Boolean;
        OpportunityDescriptionEditable: Boolean;
        WizardContactNameEditable: Boolean;
        CampaignResponseEditable: Boolean;
        CampaignTargetEditable: Boolean;
        CreateOpportunityQst: Label 'Do you want to create an opportunity?';

    procedure Caption(): Text
    var
        Contact: Record Contact;
        CaptionStr: Text;
    begin
        if Contact.Get(Rec.GetFilter("Contact Company No.")) then
            CaptionStr := CopyStr(Contact."No." + ' ' + Contact.Name, 1, MaxStrLen(CaptionStr));
        if Contact.Get(Rec.GetFilter("Contact No.")) then
            CaptionStr := CopyStr(CaptionStr + ' ' + Contact."No." + ' ' + Contact.Name, 1, MaxStrLen(CaptionStr));
        if CaptionStr = '' then
            CaptionStr := UntitledTxt;

        exit(CaptionStr);
    end;

    local procedure GetShowMoreLessLbl(ShowLess: Boolean): Text;
    begin
        if ShowLess then
            exit(ShowLessLbl);
        exit(ShowMoreLbl);
    end;

    local procedure LogCall()
    begin
        Rec.CheckPhoneCallStatus();
        Rec.LogSegLinePhoneCall();
    end;

    local procedure ShowStep(Visible: Boolean)
    begin
        case WizardStep of
            1:
                begin
                    Step1Visible := Visible;
                    NextEnable := true;
                    BackEnable := false;
                    CallEnable := true;
                    FinishEnable := false;
                end;
            2:
                begin
                    Step2Visible := Visible;
                    BackEnable := true;
                    NextEnable := true;
                    CallEnable := false;
                    FinishEnable := false;
                end;
            3:
                begin
                    Step3Visible := Visible;
                    BackEnable := true;
                    NextEnable := false;
                    CallEnable := false;
                    FinishEnable := true;
                end;
        end;
    end;

}

