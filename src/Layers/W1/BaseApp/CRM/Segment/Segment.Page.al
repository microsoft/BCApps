// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Segment;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Opportunity;
using Microsoft.CRM.Reports;
using Microsoft.CRM.Task;
using System.Environment;
using System.Integration;
using System.Integration.Excel;

page 5091 Segment
{
    Caption = 'Segment';
    PageType = ListPlus;
    PopulateAllFields = true;
    SourceTable = "Segment Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Importance = Additional;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the segment.';

                    trigger OnValidate()
                    begin
                        DescriptionOnAfterValidate();
                    end;
                }
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code of the salesperson responsible for this segment and/or interaction.';

                    trigger OnValidate()
                    begin
                        SalespersonCodeOnAfterValidate();
                    end;
                }
                field(Date; Rec.Date)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the date that the segment was created.';

                    trigger OnValidate()
                    begin
                        DateOnAfterValidate();
                    end;
                }
                field("No. of Lines"; Rec."No. of Lines")
                {
                    ApplicationArea = RelationshipMgmt;
                    DrillDown = false;
                    ToolTip = 'Specifies the number of lines within the segment.';
                }
                field("No. of Criteria Actions"; Rec."No. of Criteria Actions")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of actions you have taken when modifying the segmentation criteria, that is, when adding contacts to the segment, refining, or reducing it.';
                }
            }
            group(Interaction)
            {
                Caption = 'Interaction';
                field("Interaction Template Code"; Rec."Interaction Template Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the interaction template code of the interaction involving the segment.';

                    trigger OnValidate()
                    begin
                        InteractionTemplateCodeOnAfter();
                    end;
                }
                field("Language Code (Default)"; Rec."Language Code (Default)")
                {
                    ApplicationArea = RelationshipMgmt;
                    Enabled = LanguageCodeDefaultEnable;
                    ToolTip = 'Specifies the language code for the segment.';

                    trigger OnValidate()
                    begin
                        LanguageCodeDefaultOnAfterVali();
                    end;
                }
                field("Subject (Default)"; Rec."Subject (Default)")
                {
                    ApplicationArea = RelationshipMgmt;
                    Enabled = SubjectDefaultEnable;
                    ToolTip = 'Specifies the subject of the segment. The text in the field is used as the subject in e-mails and in Word documents.';

                    trigger OnValidate()
                    begin
                        SubjectDefaultOnAfterValidate();
                    end;
                }
                field(Attachment; Rec."Attachment No." > 0)
                {
                    ApplicationArea = RelationshipMgmt;
                    AssistEdit = true;
                    BlankZero = true;
                    Caption = 'Attachment';
                    Enabled = AttachmentEnable;
                    ToolTip = 'Specifies if the linked attachment is inherited or unique.';

                    trigger OnAssistEdit()
                    begin
                        Rec.MaintainAttachment();
                        UpdateEditable();
                        CurrPage.SegLines.PAGE.UpdateForm();
                    end;
                }
                field("Word Template Code"; Rec."Word Template Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Word Template Code';
                    ToolTip = 'Specifies the Word Template code to use for merging.';
                }
                field("Modified Word Template"; Rec."Modified Word Template" > 0)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Modified Word Template';
                    ToolTip = 'Specifies if the Word Template is modified. Use the "Modify Word Template" action to modify the Word Template.';
                    Enabled = false;
                }

                field("Ignore Contact Corres. Type"; Rec."Ignore Contact Corres. Type")
                {
                    ApplicationArea = RelationshipMgmt;
                    Enabled = IgnoreContactCorresTypeEnable;
                    ToolTip = 'Specifies that the correspondence type that you select in the Correspondence Type (Default) field should be used. If there is no check mark, the program uses the correspondence type selected on the Contact Card.';

                    trigger OnValidate()
                    begin
                        IgnoreContactCorresTypeOnAfter();
                    end;
                }
                field("Correspondence Type (Default)"; Rec."Correspondence Type (Default)")
                {
                    ApplicationArea = RelationshipMgmt;
                    Enabled = CorrespondenceTypeDefaultEnabl;
                    ToolTip = 'Specifies the preferred type of correspondence for the interaction. NOTE: If you use the Web client, you must not select the Hard Copy option because printing is not possible from the web client.';

                    trigger OnValidate()
                    begin
                        CorrespondenceTypeDefaultOnAft();
                    end;
                }
                field("Information Flow"; Rec."Information Flow")
                {
                    ApplicationArea = RelationshipMgmt;
                    Enabled = InformationFlowEnable;
                    ToolTip = 'Specifies the direction of the information that is part of the interaction created for the segment. There are two options: Inbound and Outbound.';

                    trigger OnValidate()
                    begin
                        InformationFlowOnAfterValidate();
                    end;
                }
                field("Initiated By"; Rec."Initiated By")
                {
                    ApplicationArea = RelationshipMgmt;
                    Enabled = InitiatedByEnable;
                    ToolTip = 'Specifies whether the interaction recorded for this segment was initiated by your company or by one of your contacts. The Us option indicates that your company was the initiator; the Them option indicates that a contact was the initiator.';

                    trigger OnValidate()
                    begin
                        InitiatedByOnAfterValidate();
                    end;
                }
                field("Unit Cost (LCY)"; Rec."Unit Cost (LCY)")
                {
                    ApplicationArea = RelationshipMgmt;
                    Enabled = UnitCostLCYEnable;
                    ToolTip = 'Specifies the cost, in LCY, of one unit of the item or resource on the line.';

                    trigger OnValidate()
                    begin
                        UnitCostLCYOnAfterValidate();
                    end;
                }
                field("Unit Duration (Min.)"; Rec."Unit Duration (Min.)")
                {
                    ApplicationArea = RelationshipMgmt;
                    Enabled = UnitDurationMinEnable;
                    ToolTip = 'Specifies the duration of a single interaction created for this segment.';

                    trigger OnValidate()
                    begin
                        UnitDurationMinOnAfterValidate();
                    end;
                }
                field("Send Word Docs. as Attmt."; Rec."Send Word Docs. as Attmt.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies that the Microsoft Word document should be sent as an attachment in the e-mail message.';

                    trigger OnValidate()
                    begin
                        SendWordDocsasAttmtOnAfterVali();
                    end;
                }
            }
            part(SegLines; "Segment Subform")
            {
                ApplicationArea = RelationshipMgmt;
                SubPageLink = "Segment No." = field("No.");
            }
            group(Campaign)
            {
                Caption = 'Campaign';
                field("Campaign No."; Rec."Campaign No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of the campaign for which the segment has been created.';

                    trigger OnValidate()
                    begin
                        CampaignNoOnAfterValidate();
                    end;
                }
                field("Campaign Description"; Rec."Campaign Description")
                {
                    ApplicationArea = RelationshipMgmt;
                    Editable = false;
                    ToolTip = 'Specifies a description of the campaign to which the segment is related. The description is copied from the campaign card.';
                }
                field("Campaign Target"; Rec."Campaign Target")
                {
                    ApplicationArea = RelationshipMgmt;
                    Enabled = CampaignTargetEnable;
                    ToolTip = 'Specifies that the segment is part of the target of the campaign to which it is linked.';

                    trigger OnValidate()
                    begin
                        CampaignTargetOnAfterValidate();
                    end;
                }
                field("Campaign Response"; Rec."Campaign Response")
                {
                    ApplicationArea = RelationshipMgmt;
                    Enabled = CampaignResponseEnable;
                    ToolTip = 'Specifies that the interaction created for the segment is the response to a campaign.';

                    trigger OnValidate()
                    begin
                        CampaignResponseOnAfterValidat();
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
            group("&Segment")
            {
                Caption = '&Segment';
                Image = Segment;
                action(Criteria)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Criteria';
                    Image = "Filter";
                    RunObject = Page "Segment Criteria";
                    RunPageLink = "Segment No." = field("No.");
                    ToolTip = 'View a list of the actions that you have performed (adding or removing contacts) in order to define the segment criteria.';
                }
                action("Oppo&rtunities")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Oppo&rtunities';
                    Image = OpportunityList;
                    RunObject = Page "Opportunity List";
                    RunPageLink = "Segment No." = field("No.");
                    RunPageView = sorting("Segment No.");
                    ToolTip = 'View the sales opportunities that are handled by salespeople for the segment. Opportunities must involve a contact and can be linked to campaigns.';
                }
                action("Create opportunity")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Create Opportunity';
                    Image = NewOpportunity;
                    RunObject = Page "Opportunity Card";
                    RunPageLink = "Segment No." = field("No.");
                    RunPageMode = Create;
                    ToolTip = 'Create a new opportunity card.';
                }
                action("Create opportunities")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Create opportunities';
                    ToolTip = 'Create a new opportunity card related to the segment.';

                    trigger OnAction()
                    begin
                        CreateOpportunitiesForAllContacts();
                    end;
                }
                action("T&asks")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'T&asks';
                    Image = TaskList;
                    RunObject = Page "Task List";
                    RunPageLink = "Segment No." = field("No."),
                                  "System To-do Type" = filter(Organizer | "Salesperson Attendee");
                    RunPageView = sorting("Segment No.");
                    ToolTip = 'View all marketing tasks that involve the segment.';
                }
                action("Modify Word Template")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Modify Word Template';
                    ToolTip = 'Modify the currently selected Word Template to be used for this segment.';

                    trigger OnAction()
                    begin
                        Rec.CreateWordTemplateAttachment();
                        UpdateEditable();
                        CurrPage.SegLines.PAGE.UpdateForm();
                    end;
                }
            }
        }
        area(processing)
        {
            action(LogSegment)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = '&Log';
                Image = Approve;
                ToolTip = 'Log segments and interactions that are assigned to your segments and delivery attachments that you have sent.';

                trigger OnAction()
                var
                    LogSegment: Report "Log Segment";
                begin
                    LogSegment.SetSegmentNo(Rec."No.");
                    LogSegment.RunModal();
                    if not Rec.Get(Rec."No.") then begin
                        Message(LoggedSegmentLbl, Rec."No.");
                        CurrPage.Close();
                    end;
                end;
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                group(Contacts)
                {
                    Caption = 'Contacts';
                    Image = CustomerContact;
                    action(AddContacts)
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Add Contacts';
                        Ellipsis = true;
                        Image = AddContacts;
                        ToolTip = 'Select which contacts to add to the segment.';

                        trigger OnAction()
                        var
                            SegHeader: Record "Segment Header";
                        begin
                            SegHeader := Rec;
                            SegHeader.SetRecFilter();
                            REPORT.RunModal(REPORT::"Add Contacts", true, false, SegHeader);
                        end;
                    }
                    action(ReduceContacts)
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Reduce Contacts';
                        Ellipsis = true;
                        Image = RemoveContacts;
                        ToolTip = 'Select which contacts to remove from your segment.';

                        trigger OnAction()
                        var
                            SegHeader: Record "Segment Header";
                        begin
                            SegHeader := Rec;
                            SegHeader.SetRecFilter();
                            REPORT.RunModal(REPORT::"Remove Contacts - Reduce", true, false, SegHeader);
                        end;
                    }
                    action(RefineContacts)
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Re&fine Contacts';
                        Ellipsis = true;
                        Image = ContactFilter;
                        ToolTip = 'Select which contacts to keep in your segment.';

                        trigger OnAction()
                        var
                            SegHeader: Record "Segment Header";
                        begin
                            SegHeader := Rec;
                            SegHeader.SetRecFilter();
                            REPORT.RunModal(REPORT::"Remove Contacts - Refine", true, false, SegHeader);
                        end;
                    }
                }
                group("S&egment")
                {
                    Caption = 'S&egment';
                    Image = Segment;
                    action("Go Back")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Go Back';
                        Image = Undo;
                        ToolTip = 'Go one step back, for example if you have added contacts to a segment by mistake.';

                        trigger OnAction()
                        var
                            SegmentHistoryMgt: Codeunit SegHistoryManagement;
                        begin
                            Rec.CalcFields("No. of Criteria Actions");
                            if Rec."No. of Criteria Actions" > 0 then
                                if Confirm(UndoLastCriteriaMsg, false) then
                                    SegmentHistoryMgt.GoBack(Rec."No.");
                        end;
                    }
                    separator(Action54)
                    {
                        Caption = '';
                    }
                    action(ReuseCriteria)
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Reuse Criteria';
                        Ellipsis = true;
                        Image = Reuse;
                        ToolTip = 'Reuse a saved segment criteria.';

                        trigger OnAction()
                        begin
                            Rec.ReuseCriteria();
                        end;
                    }
                    action("Reuse Segment")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Reuse Segment';
                        Ellipsis = true;
                        Image = Reuse;
                        ToolTip = 'Reuse a logged segment.';

                        trigger OnAction()
                        begin
                            Rec.ReuseLogged(0);
                        end;
                    }
                    action(SaveCriteria)
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Save Criteria';
                        Ellipsis = true;
                        Image = Save;
                        ToolTip = 'Save a segment criteria.';

                        trigger OnAction()
                        begin
                            Rec.SaveCriteria();
                        end;
                    }
                }
                separator(Action59)
                {
                    Caption = '';
                }
                group(Action60)
                {
                    Caption = 'Attachment';
                    Image = Attachments;
                    action(Open)
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Open';
                        Image = Edit;
                        ShortCutKey = 'Return';
                        ToolTip = 'Open the card for the selected record.';

                        trigger OnAction()
                        begin
                            Rec.TestField("Interaction Template Code");
                            Rec.OpenAttachment();
                        end;
                    }
                    action(Create)
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Create';
                        Image = New;
                        ToolTip = 'Create an attachment.';

                        trigger OnAction()
                        begin
                            Rec.TestField("Interaction Template Code");
                            Rec.CreateAttachment();
                        end;
                    }
                    action(Import)
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Import';
                        Image = Import;
                        ToolTip = 'Import an attachment.';

                        trigger OnAction()
                        begin
                            Rec.TestField("Interaction Template Code");
                            Rec.ImportAttachment();
                        end;
                    }
                    action(Export)
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Export';
                        Image = Export;
                        ToolTip = 'Export an attachment.';

                        trigger OnAction()
                        begin
                            Rec.TestField("Interaction Template Code");
                            Rec.ExportAttachment();
                        end;
                    }
                    action(Remove)
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Remove';
                        Image = Cancel;
                        ToolTip = 'Remove an attachment.';

                        trigger OnAction()
                        begin
                            Rec.TestField("Interaction Template Code");
                            Rec.RemoveAttachment(false);
                        end;
                    }
                }
                action(ExportContacts)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'E&xport Contacts';
                    Image = ExportFile;
                    ToolTip = 'Export the list of contacts to a file on your device. For Business Central online, the file is an Excel workbook. For Business Central on-premises, it''s a text file that you can then open in Excel.';

                    trigger OnAction()
                    var
                        SegLineLocal: Record "Segment Line";
                        EditinExcel: Codeunit "Edit in Excel";
                        EditinExcelFilters: Codeunit "Edit in Excel Filters";
                        ODataUtility: Codeunit "ODataUtility";
                        EnvironmentInfo: Codeunit "Environment Information";
                    begin
                        SegLineLocal.SetRange("Segment No.", Rec."No.");
                        if EnvironmentInfo.IsSaaS() then begin
                            EditinExcelFilters.AddFieldV2(ODataUtility.ExternalizeName(SegLineLocal.FieldName(SegLineLocal."Segment No.")), Enum::"Edit in Excel Filter Type"::Equal, Rec."No.", Enum::"Edit in Excel Edm Type"::"Edm.String");
                            EditinExcel.EditPageInExcel(Text.CopyStr(CurrPage.Caption, 1, 240), Page::"Segment Subform", EditinExcelFilters)
                        end
                        else
                            XMLPORT.Run(XMLPORT::"Export Segment Contact", false, false, SegLineLocal);
                    end;
                }
                action("Apply &Mailing Group")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Apply &Mailing Group';
                    Image = DistributionGroup;
                    ToolTip = 'Assign a mailing group to a segment.';

                    trigger OnAction()
                    var
                        SegHeader: Record "Segment Header";
                    begin
                        SegHeader := Rec;
                        SegHeader.SetRecFilter();
                        REPORT.Run(REPORT::"Apply Mailing Group", true, true, SegHeader);
                    end;
                }
            }
            group("&Print")
            {
                Caption = '&Print';
                Image = Print;
                action(CoverSheet)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Print Cover &Sheets';
                    Image = PrintCover;
                    ToolTip = 'View cover sheets to send to your contact.';

                    trigger OnAction()
                    var
                        SegHeader: Record "Segment Header";
                        ContactCoverSheet: Report "Contact Cover Sheet";
                    begin
                        SegHeader := Rec;
                        SegHeader.SetRecFilter();
                        ContactCoverSheet.SetRunFromSegment();
                        ContactCoverSheet.SetTableView(SegHeader);
                        ContactCoverSheet.RunModal();
                    end;
                }
                action("Print &Labels")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Print &Labels';
                    Image = Print;
                    ToolTip = 'View mailing labels with names and addresses.';

                    trigger OnAction()
                    var
                        SegHeader: Record "Segment Header";
                    begin
                        SegHeader := Rec;
                        SegHeader.SetRecFilter();
                        REPORT.Run(REPORT::"Segment - Labels", true, false, SegHeader);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(LogSegment_Promoted; LogSegment)
                {
                }
                actionref(AddContacts_Promoted; AddContacts)
                {
                }
                actionref(CoverSheet_Promoted; CoverSheet)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateEditable();
    end;

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields("Attachment No.");
        Rec.CalcFields("Modified Word Template");
    end;

    trigger OnInit()
    begin
        UnitDurationMinEnable := true;
        UnitCostLCYEnable := true;
        InitiatedByEnable := true;
        InformationFlowEnable := true;
        IgnoreContactCorresTypeEnable := true;
        AttachmentEnable := true;
        LanguageCodeDefaultEnable := true;
        SubjectDefaultEnable := true;
        CorrespondenceTypeDefaultEnabl := true;
        CampaignResponseEnable := true;
        CampaignTargetEnable := true;
    end;

    var
        LoggedSegmentLbl: Label 'Segment %1 has been logged.', Comment = '%1 = Segment No.';
        UndoLastCriteriaMsg: Label 'This will undo the last criteria action.\Do you want to continue?';
        CampaignTargetEnable: Boolean;
        CampaignResponseEnable: Boolean;
        CorrespondenceTypeDefaultEnabl: Boolean;
        SubjectDefaultEnable: Boolean;
        LanguageCodeDefaultEnable: Boolean;
        AttachmentEnable: Boolean;
        IgnoreContactCorresTypeEnable: Boolean;
        InformationFlowEnable: Boolean;
        InitiatedByEnable: Boolean;
        UnitCostLCYEnable: Boolean;
        UnitDurationMinEnable: Boolean;
        CreateOppQst: Label 'Do you want to create an opportunity for all contacts in segment?';

    local procedure UpdateEditable()
    var
        SegmentInteractionLanguage: Record "Segment Interaction Language";
    begin
        CampaignTargetEnable := Rec."Campaign No." <> '';
        CampaignResponseEnable := Rec."Campaign No." <> '';
        CorrespondenceTypeDefaultEnabl := Rec."Ignore Contact Corres. Type" = true;
        LanguageCodeDefaultEnable := Rec."Interaction Template Code" <> '';
        SubjectDefaultEnable := SegmentInteractionLanguage.Get(Rec."No.", 0, Rec."Language Code (Default)");
        AttachmentEnable := Rec."Interaction Template Code" <> '';
        IgnoreContactCorresTypeEnable := Rec."Interaction Template Code" <> '';
        InformationFlowEnable := Rec."Interaction Template Code" <> '';
        InitiatedByEnable := Rec."Interaction Template Code" <> '';
        UnitCostLCYEnable := Rec."Interaction Template Code" <> '';
        UnitDurationMinEnable := Rec."Interaction Template Code" <> '';
        LanguageCodeDefaultEnable := Rec."Interaction Template Code" <> '';

        OnAfterUpdateEditable();
    end;

    local procedure DateOnAfterValidate()
    begin
        CurrPage.SegLines.PAGE.UpdateForm();
    end;

    local procedure SalespersonCodeOnAfterValidate()
    begin
        CurrPage.SegLines.PAGE.UpdateForm();
    end;

    local procedure DescriptionOnAfterValidate()
    begin
        CurrPage.SegLines.PAGE.UpdateForm();
    end;

    local procedure InteractionTemplateCodeOnAfter()
    begin
        UpdateEditable();
        CurrPage.SegLines.PAGE.UpdateForm();
        CurrPage.Update();
    end;

    local procedure InformationFlowOnAfterValidate()
    begin
        CurrPage.SegLines.PAGE.UpdateForm();
    end;

    local procedure InitiatedByOnAfterValidate()
    begin
        CurrPage.SegLines.PAGE.UpdateForm();
    end;

    local procedure UnitCostLCYOnAfterValidate()
    begin
        CurrPage.SegLines.PAGE.UpdateForm();
    end;

    local procedure UnitDurationMinOnAfterValidate()
    begin
        CurrPage.SegLines.PAGE.UpdateForm();
    end;

    local procedure CorrespondenceTypeDefaultOnAft()
    begin
        CurrPage.SegLines.PAGE.UpdateForm();
    end;

    local procedure SendWordDocsasAttmtOnAfterVali()
    begin
        CurrPage.SegLines.PAGE.UpdateForm();
    end;

    local procedure LanguageCodeDefaultOnAfterVali()
    begin
        UpdateEditable();
        CurrPage.SegLines.PAGE.UpdateForm();
        CurrPage.Update();
    end;

    local procedure IgnoreContactCorresTypeOnAfter()
    begin
        UpdateEditable();
        CurrPage.SegLines.PAGE.UpdateForm();
    end;

    local procedure SubjectDefaultOnAfterValidate()
    begin
        CurrPage.SegLines.PAGE.UpdateForm();
    end;

    local procedure CampaignResponseOnAfterValidat()
    begin
        CurrPage.SegLines.PAGE.UpdateForm();
    end;

    local procedure CampaignTargetOnAfterValidate()
    begin
        CurrPage.SegLines.PAGE.UpdateForm();
    end;

    local procedure CampaignNoOnAfterValidate()
    begin
        if Rec."Campaign No." = '' then begin
            Rec."Campaign Target" := false;
            Rec."Campaign Response" := false;
        end;

        Rec.CalcFields("Campaign Description");
        CampaignTargetEnable := Rec."Campaign No." <> '';
        CampaignResponseEnable := Rec."Campaign No." <> '';
        CurrPage.SegLines.PAGE.UpdateForm();
    end;

    local procedure CreateOpportunitiesForAllContacts()
    begin
        if Confirm(CreateOppQst) then
            Rec.CreateOpportunities();
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterUpdateEditable()
    begin
    end;
}

