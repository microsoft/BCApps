// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Segment;

page 5092 "Segment Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Segment Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Contact No."; Rec."Contact No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the contact to which this segment line applies.';

                    trigger OnValidate()
                    begin
                        ContactNoOnAfterValidate();
                    end;
                }
                field("Correspondence Type"; Rec."Correspondence Type")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the type of correspondence for the interaction. NOTE: If you use the Web client, you must not select the Hard Copy option because printing is not possible from the web client.';
                }
                field("Send Word Doc. As Attmt."; Rec."Send Word Doc. As Attmt.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies that the Microsoft Word document that is linked to that segment line should be sent as an attachment in the e-mail message.';
                    Visible = false;
                }
                field("Contact Alt. Address Code"; Rec."Contact Alt. Address Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the code of the contact''s alternate address to use for this interaction.';
                    Visible = false;
                }
                field("Contact Company Name"; Rec."Contact Company Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the company for which the contact works. If the contact is a company, this field contains the company''s name.';
                }
                field("Contact Name"; Rec."Contact Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the contact to which the segment line applies. The program automatically fills in this field when you fill in the Contact No. field on the line.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the segment line.';
                }
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ApplicationArea = Suite, RelationshipMgmt;
                    ToolTip = 'Specifies the code of the salesperson responsible for this segment line and/or interaction.';
                }
                field("Interaction Template Code"; Rec."Interaction Template Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the interaction template code of the interaction involving the contact on this segment line.';
                }
                field("Language Code"; Rec."Language Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the language that is used when translating specified text on documents to foreign business partner, such as an item description on an order confirmation.';

                    trigger OnValidate()
                    begin
                        LanguageCodeOnAfterValidate();
                    end;
                }
                field(Subject; Rec.Subject)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the subject of the segment line. The text in the field is used as the subject in e-mails and Word documents.';
                }
                field(Evaluation; Rec.Evaluation)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the evaluation of the interaction involving the contact in the segment.';
                }
                field("Cost (LCY)"; Rec."Cost (LCY)")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the cost of the interaction with the contact that this segment line applies to.';
                }
                field("Duration (Min.)"; Rec."Duration (Min.)")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the duration of the interaction with the contact to which this segment line applies.';
                }
                field("Initiated By"; Rec."Initiated By")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies whether the interaction recorded for this segment line was initiated by your company or by one of your contacts. The Us option indicates that your company was the initiator; the Them option indicates that a contact was the initiator.';
                    Visible = false;
                }
                field("Information Flow"; Rec."Information Flow")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the direction of the information that is part of the interaction created for this segment line. There are two options: Inbound and Outbound.';
                    Visible = false;
                }
                field("Campaign No."; Rec."Campaign No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of the campaign for which the segment line has been created.';
                    Visible = false;
                }
                field("Campaign Target"; Rec."Campaign Target")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies that the segment involved in this interaction is the target of a campaign. This is used to measure the response rate of a campaign.';
                    Visible = false;
                }
                field("Campaign Response"; Rec."Campaign Response")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies that the interaction created for the segment is the response to a campaign. For example, coupons that are sent as a response to a campaign.';
                    Visible = false;
                }
                field(AttachmentText; Rec.AttachmentText())
                {
                    ApplicationArea = RelationshipMgmt;
                    AssistEdit = true;
                    Caption = 'Attachment';
                    Editable = false;
                    ToolTip = 'Specifies if the linked attachment is inherited or unique.';

                    trigger OnAssistEdit()
                    begin
                        CurrPage.SaveRecord();
                        Rec.MaintainSegLineAttachment();
                        CurrPage.Update(false);
                    end;
                }
                field("Word Template Code"; Rec."Word Template Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Word Template Code';
                    ToolTip = 'Specifies the Word Template code to use for merging.';
                }

                field("Contact Via"; Rec."Contact Via")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the telephone number you used when calling the contact, or the e-mail address you used when sending an e-mail to the contact.';
                    Visible = false;
                }
                field("Contact Phone No."; Rec."Contact Phone No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    DrillDown = false;
                    ToolTip = 'Specifies the telephone number of the contact to whom the segment line applies. The number will be filled in for you if you choose a contact in the Contact No. field on the line.';
                }
                field("Contact Mobile Phone No."; Rec."Contact Mobile Phone No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    DrillDown = false;
                    ToolTip = 'Specifies the mobile telephone number of the contact to whom the segment line applies. The number will be filled in for you if you choose a contact in the Contact No. field on the line.';
                }
                field("Contact E-Mail"; Rec."Contact Email")
                {
                    ApplicationArea = RelationshipMgmt;
                    DrillDown = false;
                    ToolTip = 'Specifies the email address of the contact to whom the segment line applies. The address will be filled in for you if you choose a contact in the Contact No. field on the line.';
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                    ToolTip = 'Specifies the line number of the contact to whom the segment line applies.';
                }
                field("Segment No."; Rec."Segment No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                    ToolTip = 'Specifies the segment number of the contact to whom the segment line applies.';
                }
                field(Date; Rec.Date)
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                    ToolTip = 'Specifies the date of the contact to whom the segment line applies.';
                }
                field("Time of Interaction"; Rec."Time of Interaction")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                    ToolTip = 'Specifies the time of interaction of the contact to whom the segment line applies.';
                }
                field("Attempt Failed"; Rec."Attempt Failed")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                    ToolTip = 'Specifies the attempt failed of the contact to whom the segment line applies.';
                }
                field("To-do No."; Rec."To-do No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                    ToolTip = 'Specifies the To-do number of the contact to whom the segment line applies.';
                }
                field("Contact Company No."; Rec."Contact Company No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                    ToolTip = 'Specifies the contact company number of the contact to whom the segment line applies.';
                }
                field("Campaign Entry No."; Rec."Campaign Entry No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                    ToolTip = 'Specifies the campaign entry number of the contact to whom the segment line applies.';
                }
                field("Interaction Group Code"; Rec."Interaction Group Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                    ToolTip = 'Specifies the interaction group code of the contact to whom the segment line applies.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                    ToolTip = 'Specifies the document type of the contact to whom the segment line applies.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                    ToolTip = 'Specifies the document number of the contact to whom the segment line applies.';
                }
                field("Version No."; Rec."Version No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                    ToolTip = 'Specifies the version number of the contact to whom the segment line applies.';
                }
                field("Opportunity No."; Rec."Opportunity No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                    ToolTip = 'Specifies the opportunity number of the contact to whom the segment line applies.';
                }
                field("Wizard Step"; Rec."Wizard Step")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                    ToolTip = 'Specifies the wizard step of the contact to whom the segment line applies.';
                }
                field("Wizard Contact Name"; Rec."Wizard Contact Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                    ToolTip = 'Specifies the wizard contact name of the contact to whom the segment line applies.';
                }
                field("Opportunity Description"; Rec."Opportunity Description")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                    ToolTip = 'Specifies the opportunity description of the contact to whom the segment line applies.';
                }
                field("Campaign Description"; Rec."Campaign Description")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                    ToolTip = 'Specifies the campaign description of the contact to whom the segment line applies.';
                }
                field("Interaction Successful"; Rec."Interaction Successful")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                    ToolTip = 'Specifies if the interaction was successful for the contact to whom the segment line applies.';
                }
                field("Dial Contact"; Rec."Dial Contact")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                    ToolTip = 'Specifies the dial contact of the contact to whom the segment line applies.';
                }
                field("Mail Contact"; Rec."Mail Contact")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                    ToolTip = 'Specifies the mail contact of the contact to whom the segment line applies.';
                }

            }
        }
    }

    actions
    {
        area(processing)
        {
            group(Line)
            {
                Caption = 'Line';
                Image = Line;
                group(Attachment)
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
                            Rec.OpenSegLineAttachment();
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
                            Rec.CreateSegLineAttachment();
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
                            Rec.ImportSegLineAttachment();
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
                            Rec.ExportSegLineAttachment();
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
                            Rec.RemoveAttachment();
                        end;
                    }
                }
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Make &Phone Call")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Make &Phone Call';
                    Image = Calls;
                    ToolTip = 'Call the selected contact.';

                    trigger OnAction()
                    begin
                        Rec.CreatePhoneCall();
                    end;
                }
            }
        }
    }

    trigger OnDeleteRecord(): Boolean
    begin
        if Rec."Contact No." <> '' then begin
            SegCriteriaManagement.DeleteContact(Rec."Segment No.", Rec."Contact No.");
            SegHistoryManagement.DeleteLine(Rec."Segment No.", Rec."Contact No.", Rec."Line No.");
        end;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if Rec."Contact No." <> '' then begin
            SegCriteriaManagement.InsertContact(Rec."Segment No.", Rec."Contact No.");
            SegHistoryManagement.InsertLine(Rec."Segment No.", Rec."Contact No.", Rec."Line No.");
        end;
    end;

    trigger OnModifyRecord(): Boolean
    begin
        if Rec."Contact No." <> xRec."Contact No." then begin
            if xRec."Contact No." <> '' then begin
                SegCriteriaManagement.DeleteContact(Rec."Segment No.", xRec."Contact No.");
                SegHistoryManagement.DeleteLine(Rec."Segment No.", xRec."Contact No.", Rec."Line No.");
            end;
            if Rec."Contact No." <> '' then begin
                SegCriteriaManagement.InsertContact(Rec."Segment No.", Rec."Contact No.");
                SegHistoryManagement.InsertLine(Rec."Segment No.", Rec."Contact No.", Rec."Line No.");
            end;
        end;
    end;

    var
        SegHistoryManagement: Codeunit SegHistoryManagement;
        SegCriteriaManagement: Codeunit SegCriteriaManagement;

    procedure UpdateForm()
    begin
        CurrPage.Update(false);
    end;

    local procedure ContactNoOnAfterValidate()
    begin
        CurrPage.Update(true);
    end;

    local procedure LanguageCodeOnAfterValidate()
    begin
        CurrPage.Update(false);
    end;
}

