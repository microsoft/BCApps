// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Interaction;

using Microsoft.Foundation.Reporting;

page 5154 "Interact. Tmpl. Languages"
{
    Caption = 'Interact. Tmpl. Languages';
    DataCaptionFields = "Interaction Template Code";
    PageType = List;
    SourceTable = "Interaction Tmpl. Language";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Interaction Template Code"; Rec."Interaction Template Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code for the interaction template that you have selected.';
                }
                field("Language Code"; Rec."Language Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the language that is used when translating specified text on documents to foreign business partner, such as an item description on an order confirmation.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the description of the interaction template language. This field will not be displayed in the Word attachment.';
                }
                field(WordTemplateCode; Rec."Word Template Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Word template to use when you create communications for an interaction. The Word template will create either a document or be used as the body text in an email.';
                }
                field(Attachment; Rec."Attachment No." <> 0)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Attachment';
                    ToolTip = 'Specifies if the linked attachment is inherited or unique.';

                    trigger OnAssistEdit()
                    begin
                        if Rec."Attachment No." = 0 then
                            Rec.CreateAttachment()
                        else
                            Rec.OpenAttachment();

                        CurrPage.Update();
                    end;
                }
                field("Custom Layout Code"; Rec."Custom Layout Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of the report layout.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        UpdateAttachments(Rec."Custom Layout Code");
                    end;
                }
                field(CustLayoutDescription; CustomReportLayoutDescription)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Custom Layout';
                    ToolTip = 'Specifies the report layout that will be used.';
                    Visible = CustLayoutVisible;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        CustomReportLayout: Record "Custom Report Layout";
                    begin
                        if CustomReportLayout.LookupLayoutOK(REPORT::"Email Merge") then begin
                            Rec.Validate("Custom Layout Code", CustomReportLayout.Code);
                            Rec.Modify(true);

                            CustomReportLayoutDescription := CustomReportLayout.Description;
                            UpdateAttachments(Rec."Custom Layout Code");
                        end;
                    end;

                    trigger OnValidate()
                    var
                        CustomReportLayout: Record "Custom Report Layout";
                    begin
                        if CustomReportLayoutDescription = '' then begin
                            Rec.Validate("Custom Layout Code", '');
                            Rec.Modify(true);
                        end else begin
                            CustomReportLayout.SetRange("Report ID", REPORT::"Email Merge");
                            CustomReportLayout.SetFilter(Description, StrSubstNo('@*%1*', CustomReportLayoutDescription));
                            if not CustomReportLayout.FindFirst() then
                                Error(CouldNotFindCustomReportLayoutErr, CustomReportLayoutDescription);

                            Rec.Validate("Custom Layout Code", CustomReportLayout.Code);
                            Rec.Modify(true);
                        end;

                        UpdateAttachments(Rec."Custom Layout Code");
                    end;
                }
                field(ReportLayoutName; Rec."Report Layout Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the report layout that will be used.';

                    trigger OnValidate()
                    begin
                        if Rec."Report Layout Name" <> '' then
                            Rec.Validate("Custom Layout Code", '');
                        UpdateAttachments(Rec."Report Layout Name");
                    end;
                }
                field(ReportLayoutAppID; Rec."Report Layout AppID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies which app the report layout belongs to.';
                    Visible = false;
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
            group("&Attachment")
            {
                Caption = '&Attachment';
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
                        Rec.OpenAttachment();
                    end;
                }
                action(Create)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Create';
                    Ellipsis = true;
                    Image = New;
                    ToolTip = 'Create an attachment.';

                    trigger OnAction()
                    begin
                        Rec.CreateAttachment();
                    end;
                }
                action("Copy &from")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Copy &from';
                    Ellipsis = true;
                    Image = Copy;
                    ToolTip = 'Copy from an attachment.';

                    trigger OnAction()
                    begin
                        Rec.CopyFromAttachment();
                    end;
                }
                action(Import)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Import';
                    Ellipsis = true;
                    Image = Import;
                    ToolTip = 'Import an attachment.';

                    trigger OnAction()
                    begin
                        Rec.ImportAttachment();
                    end;
                }
                action("E&xport")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'E&xport';
                    Ellipsis = true;
                    Image = Export;
                    ToolTip = 'Export an attachment.';

                    trigger OnAction()
                    begin
                        Rec.ExportAttachment();
                    end;
                }
                action(Remove)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Remove';
                    Ellipsis = true;
                    Image = Cancel;
                    ToolTip = 'Remove an attachment.';

                    trigger OnAction()
                    begin
                        Rec.RemoveAttachment(true);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        Rec.CalcFields("Custom Layout Description");
        CustomReportLayoutDescription := Rec."Custom Layout Description";
    end;

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields("Custom Layout Description");
        CustomReportLayoutDescription := Rec."Custom Layout Description";
    end;

    trigger OnOpenPage()
    var
        CustomReportLayout: Record "Custom Report Layout";
    begin
        CustLayoutVisible := CustomReportLayout.ReadPermission;
        if CustLayoutVisible then begin
            CustomReportLayout.SetRange("Report ID", Report::"Email Merge");
            CustLayoutVisible := not CustomReportLayout.IsEmpty();
        end;
    end;

    var
        CustomReportLayoutDescription: Text;
        CustLayoutVisible: Boolean;
        CouldNotFindCustomReportLayoutErr: Label 'There is no Custom Report Layout with %1 in the description.', Comment = '%1 Description of Custom Report Layout';

    local procedure UpdateAttachments(NewCustomLayoutCode: Code[20])
    begin
        if NewCustomLayoutCode <> '' then
            Rec.CreateAttachment()
        else
            if xRec."Custom Layout Code" <> '' then
                Rec.RemoveAttachment(false);

        Rec.CalcFields("Custom Layout Description");
        CurrPage.Update();
    end;

    local procedure UpdateAttachments(NewReportLayoutName: Text[250])
    begin
        if NewReportLayoutName <> '' then
            Rec.CreateAttachment()
        else
            if xRec."Report Layout Name" <> '' then
                Rec.RemoveAttachment(false);

        CurrPage.Update();
    end;
}

