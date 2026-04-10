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

                    trigger OnValidate()
                    begin
                        ContactNoOnAfterValidate();
                    end;
                }
                field("Correspondence Type"; Rec."Correspondence Type")
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field("Send Word Doc. As Attmt."; Rec."Send Word Doc. As Attmt.")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                }
                field("Contact Alt. Address Code"; Rec."Contact Alt. Address Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                }
                field("Contact Company Name"; Rec."Contact Company Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    DrillDown = false;
                }
                field("Contact Name"; Rec."Contact Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    DrillDown = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ApplicationArea = Suite, RelationshipMgmt;
                }
                field("Interaction Template Code"; Rec."Interaction Template Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the interaction template code of the interaction involving the contact on this segment line.';
                }
                field("Language Code"; Rec."Language Code")
                {
                    ApplicationArea = RelationshipMgmt;

                    trigger OnValidate()
                    begin
                        LanguageCodeOnAfterValidate();
                    end;
                }
                field(Subject; Rec.Subject)
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field(Evaluation; Rec.Evaluation)
                {
                    ApplicationArea = RelationshipMgmt;
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
                    Visible = false;
                }
                field("Information Flow"; Rec."Information Flow")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                }
                field("Campaign No."; Rec."Campaign No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                }
                field("Campaign Target"; Rec."Campaign Target")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                }
                field("Campaign Response"; Rec."Campaign Response")
                {
                    ApplicationArea = RelationshipMgmt;
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
                }
                field("Contact Mobile Phone No."; Rec."Contact Mobile Phone No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    DrillDown = false;
                }
                field("Contact E-Mail"; Rec."Contact Email")
                {
                    ApplicationArea = RelationshipMgmt;
                    DrillDown = false;
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                }
                field("Segment No."; Rec."Segment No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                }
                field(Date; Rec.Date)
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
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
                }
                field("To-do No."; Rec."To-do No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                }
                field("Contact Company No."; Rec."Contact Company No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                }
                field("Campaign Entry No."; Rec."Campaign Entry No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                }
                field("Interaction Group Code"; Rec."Interaction Group Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                }
                field("Version No."; Rec."Version No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                }
                field("Opportunity No."; Rec."Opportunity No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                }
                field("Wizard Step"; Rec."Wizard Step")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                }
                field("Wizard Contact Name"; Rec."Wizard Contact Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
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
                }
                field("Mail Contact"; Rec."Mail Contact")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
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

