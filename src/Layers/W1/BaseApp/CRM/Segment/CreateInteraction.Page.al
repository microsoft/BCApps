// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Segment;

using Microsoft.CRM.Campaign;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Opportunity;
using Microsoft.CRM.Task;
using Microsoft.CRM.Team;
using System.Environment;

page 5077 "Create Interaction"
{
    Caption = 'Create Interaction';
    DataCaptionExpression = Caption();
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
#pragma warning disable AS0035 // Changed from Card to NavigatePage
    PageType = NavigatePage;
#pragma warning restore AS0035
    ShowFilter = false;
    SourceTable = "Segment Line";

    layout
    {
        area(content)
        {
            group(General)
            {
                Visible = Step = Step::"Step 1";
                group(Step1)
                {

                    Caption = 'What is the type of interaction?';
                    ShowCaption = true;

                    field(Note1; Step1InstructionTxt)
                    {
                        ApplicationArea = All;
                        MultiLine = true;
                        ShowCaption = false;
                    }

                    field("Wizard Contact Name"; Rec."Wizard Contact Name")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Contact';
                        Editable = IsContactEditable;
                        ShowMandatory = true;
                        ToolTip = 'Specifies the contact that you are interacting with.';

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            Contact: Record Contact;
                        begin
                            if IsContactEditable then begin
                                if Contact.Get(Rec."Contact No.") then;
                                if PAGE.RunModal(0, Contact) = ACTION::LookupOK then
                                    SetContactNo(Contact);
                            end;
                        end;

                        trigger OnValidate()
                        var
                            Contact: Record Contact;
                            FilterWithoutQuotes: Text;
                        begin
                            Rec."Wizard Contact Name" := DelChr(Rec."Wizard Contact Name", '<>');
                            if Rec."Wizard Contact Name" = Rec."Contact Name" then
                                exit;
                            if Rec."Wizard Contact Name" = '' then
                                Clear(Contact)
                            else begin
                                FilterWithoutQuotes := ConvertStr(Rec."Wizard Contact Name", '''', '?');
                                Contact.SetFilter(Name, '''@*' + FilterWithoutQuotes + '*''');
                                if not Contact.FindFirst() then
                                    Clear(Contact);
                            end;
                            SetContactNo(Contact)
                        end;
                    }
                    field("Interaction Template Code"; Rec."Interaction Template Code")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Importance = Promoted;
                        NotBlank = true;
                        ShowMandatory = true;
                        ToolTip = 'Specifies the type of the interaction.';

                        trigger OnValidate()
                        var
                        begin
                            UpdateUIFlags();

                            if Campaign.Get(Rec."Campaign No.") then
                                Rec."Campaign Description" := Campaign.Description;

                            if Rec."Attachment No." <> xRec."Attachment No." then
                                AttachmentReload();

                            InteractionTemplate.Get(Rec."Interaction Template Code");
                            Rec."Correspondence Type" := InteractionTemplate."Correspondence Type (Default)";
                        end;
                    }
                    field(Description; Rec.Description)
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Description';
                        Importance = Promoted;
                        NotBlank = true;
                        ShowMandatory = true;
                        ToolTip = 'Specifies what the interaction is about.';
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
                            Caption = 'Salesperson';
                            Editable = SalespersonCodeEditable;
                            ShowMandatory = true;
                            ToolTip = 'Specifies the salesperson who is responsible for this interaction.';
                        }
                        field("Language Code"; Rec."Language Code")
                        {
                            ApplicationArea = RelationshipMgmt;
                            Enabled = IsMainInfoSet;
                            ToolTip = 'Specifies the language that is used when translating specified text on documents to foreign business partner, such as an item description on an order confirmation.';

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                Rec.LanguageCodeOnLookup();
                                if Rec."Attachment No." <> xRec."Attachment No." then
                                    AttachmentReload();
                            end;

                            trigger OnValidate()
                            begin
                                if Rec."Attachment No." <> xRec."Attachment No." then
                                    AttachmentReload();
                            end;
                        }
                        field(Date; Rec.Date)
                        {
                            ApplicationArea = RelationshipMgmt;
                            Caption = 'Date of Interaction';
                            Enabled = IsMainInfoSet;
                            Importance = Additional;
                            ToolTip = 'Specifies the date when the interaction took place.';
                        }
                        field("Time of Interaction"; Rec."Time of Interaction")
                        {
                            ApplicationArea = RelationshipMgmt;
                            Enabled = IsMainInfoSet;
                            Importance = Additional;
                            ToolTip = 'Specifies the time when the interaction took place';
                        }
                        field("Correspondence Type"; Rec."Correspondence Type")
                        {
                            ApplicationArea = RelationshipMgmt;
                            Enabled = IsMainInfoSet;
                            Importance = Additional;
                            ToolTip = 'Specifies the type of correspondence for the interaction. NOTE: If you use the Web client, you must not select the Hard Copy option because printing is not possible from the web client.';

                            trigger OnValidate()
                            begin
                                Rec.ValidateCorrespondenceType();
                            end;
                        }
                        field("Information Flow"; Rec."Information Flow")
                        {
                            ApplicationArea = RelationshipMgmt;
                            Enabled = IsMainInfoSet;
                            Importance = Additional;
                            ToolTip = 'Specifies the direction of the interaction, inbound or outbound.';
                        }
                        field("Initiated By"; Rec."Initiated By")
                        {
                            ApplicationArea = RelationshipMgmt;
                            Enabled = IsMainInfoSet;
                            Importance = Additional;
                            ToolTip = 'Specifies if the interaction was initiated by your company or by one of your contacts. The Us option indicates that your company was the initiator; the Them option indicates that a contact was the initiator.';
                        }
                    }
                }
            }
            group(MidDetails)
            {
                Visible = Step = Step::"Step 2";
                group(Step2)
                {

                    Caption = 'What content will be used for this interaction?';
                    ShowCaption = true;

                    field(Step2InstructionTxt; Step2InstructionTxt)
                    {
                        ApplicationArea = All;
                        MultiLine = true;
                        ShowCaption = false;
                    }
                    field(Step2OpenInstructionTxt; Step2OpenInstructionTxt)
                    {
                        ApplicationArea = All;
                        ShowCaption = false;
                    }
                    field(Step2ImportInstructionTxt; Step2ImportInstructionTxt)
                    {
                        ApplicationArea = All;
                        ShowCaption = false;
                    }
                    field(Step2MergeInstructionTxt; Step2MergeInstructionTxt)
                    {
                        ApplicationArea = All;
                        ShowCaption = false;
                    }
                    field("Wizard Action"; InteractionTemplate."Wizard Action")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Wizard Action';
                        Editable = false;
                        ToolTip = 'Specifies the action that is performed for the interaction.';
                    }
                    group(BodyContent)
                    {
                        Caption = 'Content';
                        Visible = HTMLAttachment;

                        field(HTMLContentBodyText; HTMLContentBodyText)
                        {
                            ApplicationArea = RelationshipMgmt;
                            MultiLine = true;
                            ShowCaption = false;

                            trigger OnValidate()
                            begin
                                Rec.UpdateContentBodyTextInCustomLayoutAttachment(HTMLContentBodyText);
                            end;
                        }
                    }
                }
            }
            group(InteractionDetails)
            {
                Visible = Step = Step::"Step 3";
                group(Step3)
                {

                    ShowCaption = true;
                    Caption = 'What is the interaction related to?';
                    Enabled = IsMainInfoSet;

                    field(Step3InstructionTxt; Step3InstructionTxt)
                    {
                        ApplicationArea = All;
                        MultiLine = true;
                        ShowCaption = false;
                    }
                    field("Campaign Description"; Rec."Campaign Description")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'What campaign is this interaction linked to?';
                        Editable = CampaignDescriptionEditable;
                        Enabled = IsMainInfoSet;
                        Importance = Promoted;
                        Lookup = false;
                        TableRelation = Campaign;
                        ToolTip = 'Specifies the campaign that is related to the segment. The description is copied from the campaign card.';

                        trigger OnAssistEdit()
                        var
                            Campaign: Record Campaign;
                        begin
                            if Rec.GetFilter(Rec."Campaign No.") = '' then begin
                                if Campaign.Get(Rec."Campaign No.") then;
                                if PAGE.RunModal(0, Campaign) = ACTION::LookupOK then begin
                                    Rec.Validate(Rec."Campaign No.", Campaign."No.");
                                    Rec."Campaign Description" := Campaign.Description;
                                end;
                            end;
                        end;
                    }
                    field("Campaign Target"; Rec."Campaign Target")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'This contact is being targeted as part of campaign';
                        Enabled = IsMainInfoSet;
                        Importance = Additional;
                        ToolTip = 'Specifies that the segment involved in this interaction is the target of a campaign. This is used to measure the response rate of a campaign.';
                    }
                    field("Campaign Response"; Rec."Campaign Response")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'This interaction is a response to a campaign';
                        Enabled = IsMainInfoSet;
                        Importance = Additional;
                        ToolTip = 'Specifies that the interaction created for the segment is the response to a campaign. For example, coupons that are sent as a response to a campaign.';
                    }
                    field("Opportunity Description"; Rec."Opportunity Description")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'What is the opportunity';
                        Editable = OpportunityDescriptionEditable;
                        Enabled = IsMainInfoSet;
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
            group(InteractionFinishedDetails)
            {
                Visible = Step = Step::"Step 4";
                group(Step4)
                {
                    ShowCaption = true;
                    Caption = 'What was the result of is the interaction?';

                    field(Note4; Step4InstructionTxt)
                    {
                        ApplicationArea = All;
                        MultiLine = true;
                        ShowCaption = false;
                    }
                    field("Interaction Description"; InteractionLogEntry.Description)
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Interaction Result Description';
                        ToolTip = 'Specifies a description of the interaction.';
                    }
                    field(Evaluation; Rec.Evaluation)
                    {
                        ApplicationArea = RelationshipMgmt;
                        Enabled = IsMainInfoSet;
                        Importance = Additional;
                        ToolTip = 'Specifies the evaluation of the interaction involving the contact in the segment.';

                        trigger OnValidate()
                        begin
                            InteractionLogEntry.Evaluation := Rec.Evaluation;
                        end;
                    }
                    field(ShowMoreLess4; GetShowMoreLessLbl(ShowLessStep4))
                    {
                        ShowCaption = false;
                        ApplicationArea = RelationshipMgmt;
                        ToolTip = 'Show more/fewer fields.';

                        trigger OnDrillDown()
                        begin
                            ShowLessStep4 := not ShowLessStep4;
                            CurrPage.Update(true);
                        end;
                    }
                    group(AdditionalFieldsStep4)
                    {
                        ShowCaption = false;
                        Visible = ShowLessStep4;

                        field("Interaction Successful"; Rec."Interaction Successful")
                        {
                            ApplicationArea = RelationshipMgmt;
                            Caption = 'Was Successful';
                            Enabled = IsMainInfoSet;
                            Importance = Additional;
                            ToolTip = 'Specifies if the interaction was successful. Clear this check box to indicate that the interaction was not a success.';

                            trigger OnValidate()
                            begin
                                InteractionLogEntry."Attempt Failed" := not Rec."Interaction Successful";
                            end;
                        }
                        field("Cost (LCY)"; Rec."Cost (LCY)")
                        {
                            ApplicationArea = RelationshipMgmt;
                            Enabled = IsMainInfoSet;
                            Importance = Additional;
                            ToolTip = 'Specifies the cost of the interaction with the contact that this segment line applies to.';

                            trigger OnValidate()
                            begin
                                InteractionLogEntry."Cost (LCY)" := Rec."Cost (LCY)";
                            end;
                        }
                        field("Duration (Min.)"; Rec."Duration (Min.)")
                        {
                            ApplicationArea = RelationshipMgmt;
                            Enabled = IsMainInfoSet;
                            Importance = Additional;
                            ToolTip = 'Specifies the duration of the interaction with the contact.';

                            trigger OnValidate()
                            begin
                                InteractionLogEntry."Duration (Min.)" := Rec."Duration (Min.)";
                            end;
                        }
                    }
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Preview)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Preview';
                Enabled = HTMLAttachment;
                Image = PreviewChecks;
                ToolTip = 'Test the setup of the interaction.';
                Visible = HTMLAttachment;

                trigger OnAction()
                begin
                    Rec.PreviewSegLineHTMLContent();
                end;
            }
            action(Finish)
            {
                ApplicationArea = RelationshipMgmt;
                Enabled = IsMainInfoSet;
                Image = Approve;
                InFooterBar = true;
                Visible = IsOnMobile;

                trigger OnAction()
                begin
                    Rec.FinishSegLineWizard(true);
                    CurrPage.Close();
                end;
            }
            action(CancelInteraction)
            {
                ApplicationArea = All;
                Caption = 'Cancel';
                ToolTip = 'Cancel the interaction';
                InFooterBar = true;
                Visible = Step <> Step::"Step 4";

                trigger OnAction()
                begin
                    Rec.FinishSegLineWizard(false);
                    CurrPage.Close();
                end;
            }
            action(Back)
            {
                ApplicationArea = All;
                Caption = 'Back';
                ToolTip = 'Go back to the previous step';
                Visible = (Step <> Step::"Step 1") and (Step <> Step::"Step 4");
                InFooterBar = true;

                trigger OnAction()
                begin
                    if Step = Step::"Step 2" then
                        Step := Step::"Step 1"
                    else
                        if Step = Step::"Step 3" then
                            if InteractionTemplate."Wizard Action" = InteractionTemplate."Wizard Action"::" " then
                                Step := Step::"Step 1"
                            else
                                Step := Step::"Step 2";
                end;
            }
            action(NextInteraction)
            {
                ApplicationArea = All;
                Caption = 'Next';
                ToolTip = 'Go to the next step';
                Visible = (Step <> Step::"Step 4");
                InFooterBar = true;

                trigger OnAction()
                var
                begin
                    ProcessStep();
                end;
            }
            action(FinishInteraction)
            {
                ApplicationArea = All;
                Caption = 'Finish';
                Image = Approve;
                ToolTip = 'Finish the interaction.';
                Visible = Step = Step::"Step 4";
                InFooterBar = true;

                trigger OnAction()
                begin
                    ProcessStep();
                end;
            }
        }
        area(navigation)
        {
            action("Co&mments")
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
        }
    }

    trigger OnInit()
    begin
        SalespersonCodeEditable := true;
        OpportunityDescriptionEditable := true;
        CampaignDescriptionEditable := true;
        IsOnMobile := ClientTypeManagement.GetCurrentClientType() = CLIENTTYPE::Phone;
    end;

    trigger OnOpenPage()
    begin
        CampaignDescriptionEditable := false;
        OpportunityDescriptionEditable := false;
        SetContactEditable();
        UpdateUIFlags();

        if SalespersonPurchaser.Get(Rec.GetFilter("Salesperson Code")) then
            SalespersonCodeEditable := false;

        AttachmentReload();

        CurrPage.Update(false);
    end;

    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Campaign: Record Campaign;
        InteractionTemplate: Record "Interaction Template";
        InteractionLogEntry: Record "Interaction Log Entry";
        ToDoTask: Record "To-do";
        ClientTypeManagement: Codeunit "Client Type Management";
        Step: Option "Step 1","Step 2","Step 3","Step 4";
        HTMLContentBodyText: Text;
        CampaignDescriptionEditable: Boolean;
        OpportunityDescriptionEditable: Boolean;
        SalespersonCodeEditable: Boolean;
        HTMLAttachment: Boolean;
        UntitledTxt: Label 'untitled';
        IsOnMobile: Boolean;
        IsContactEditable: Boolean;
        ShowLessStep1: Boolean;
        ShowLessStep4: Boolean;
        Step1InstructionTxt: Label 'This wizard helps you to create interactions and record information regarding their cost, duration, connection to a campaign and eventually create opportunity in last step.';
        Step2InstructionTxt: Label 'Depending on wizard action set on interaction template, when you choose Next wizard will:';
        Step2OpenInstructionTxt: Label 'Open - opens attachment added to interaction template for your review';
        Step2ImportInstructionTxt: Label 'Import  -  attachment you want to add to interaction you''re creating';
        Step2MergeInstructionTxt: Label 'Merge - merge interaction template defined data to Word document';
        Step3InstructionTxt: Label 'Following fields are optional.\\NOTE: Pressing Next will log the interaction.';
        Step4InstructionTxt: Label 'Following fields are optional.\\NOTE: You can always evaluate interaction later using Evaluate Interaction action.';
        InteractionTemplateCodeMandatoryErr: Label 'Interaction Template Code is mandatory.';
        DescriptionMandatoryErr: Label 'Description is mandatory.';
        ShowLessLbl: Label 'Show less';
        ShowMoreLbl: Label 'Show more';

    protected var
        IsMainInfoSet: Boolean;

    procedure Caption(): Text
    var
        Contact: Record Contact;
        CaptionStr: Text;
    begin
        if Contact.Get(Rec.GetFilter("Contact Company No.")) then
            CaptionStr := CopyStr(Contact."No." + ' ' + Contact.Name, 1, MaxStrLen(CaptionStr));
        if Contact.Get(Rec.GetFilter("Contact No.")) then
            CaptionStr := CopyStr(CaptionStr + ' ' + Contact."No." + ' ' + Contact.Name, 1, MaxStrLen(CaptionStr));
        if SalespersonPurchaser.Get(Rec.GetFilter("Salesperson Code")) then
            CaptionStr := CopyStr(CaptionStr + ' ' + SalespersonPurchaser.Code + ' ' + SalespersonPurchaser.Name, 1, MaxStrLen(CaptionStr));
        if Campaign.Get(Rec.GetFilter("Campaign No.")) then
            CaptionStr := CopyStr(CaptionStr + ' ' + Campaign."No." + ' ' + Campaign.Description, 1, MaxStrLen(CaptionStr));
        if ToDoTask.Get(Rec.GetFilter("To-do No.")) then
            CaptionStr := CopyStr(CaptionStr + ' ' + ToDoTask."No." + ' ' + ToDoTask.Description, 1, MaxStrLen(CaptionStr));

        if CaptionStr = '' then
            CaptionStr := UntitledTxt;

        OnAfterCaption(Rec, CaptionStr);
        exit(CaptionStr);
    end;

    procedure UpdateUIFlags()
    begin
        IsMainInfoSet := Rec."Interaction Template Code" <> '';
    end;

    procedure AttachmentReload()
    begin
        Rec.LoadSegLineAttachment(true);
        HTMLAttachment := Rec.IsHTMLAttachment();
        if HTMLAttachment then
            HTMLContentBodyText := Rec.LoadContentBodyTextFromCustomLayoutAttachment();
    end;

    local procedure SetContactNo(Contact: Record Contact)
    begin
        Rec.Validate("Contact No.", Contact."No.");
        Rec."Wizard Contact Name" := Contact.Name;
    end;

    local procedure SetContactEditable()
    begin
        IsContactEditable := (Rec.GetFilter("Contact No.") = '') and (Rec.GetFilter("Contact Company No.") = '');

        OnAfterSetContactEditable(Rec, IsContactEditable);
    end;

    local procedure ProcessStep()
    begin
        case Step of
            Step::"Step 1":
                begin
                    ValidateStep1();
                    Step := Step::"Step 2";

                    if InteractionTemplate."Wizard Action" = InteractionTemplate."Wizard Action"::" " then
                        ProcessStep();
                end;
            Step::"Step 2":
                begin
                    if not HTMLAttachment then
                        Rec.HandleTrigger();
                    Step := Step::"Step 3";
                end;
            Step::"Step 3":
                begin
                    Rec.FinishSegLineWizard(true);
                    if Rec.GetInteractionLogEntryNo() <> 0 then begin
                        InteractionLogEntry.Get(Rec.GetInteractionLogEntryNo());
                        Step := Step::"Step 4";
                    end
                end;
            Step::"Step 4":
                begin
                    Rec.ProcessInterLogEntryComments(InteractionLogEntry."Entry No.");
                    InteractionLogEntry.Modify();
                    CurrPage.Close();
                end;
        end;
    end;

    local procedure ValidateStep1()
    begin
        if Rec."Interaction Template Code" = '' then
            Error(InteractionTemplateCodeMandatoryErr);
        if Rec.Description = '' then
            Error(DescriptionMandatoryErr);
    end;

    local procedure GetShowMoreLessLbl(ShowLess: Boolean): Text;
    begin
        if ShowLess then
            exit(ShowLessLbl);
        exit(ShowMoreLbl);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCaption(var SegmentLine: Record "Segment Line"; var CaptionStr: Text[260])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetContactEditable(var SegmentLine: Record "Segment Line"; var IsContactEditable: Boolean)
    begin
    end;
}

