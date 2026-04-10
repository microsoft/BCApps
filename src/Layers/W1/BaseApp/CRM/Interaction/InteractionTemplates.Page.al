// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Interaction;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Team;
using Microsoft.Foundation.Company;
using System.Integration.Word;

page 5075 "Interaction Templates"
{
    ApplicationArea = RelationshipMgmt;
    Caption = 'Interaction Templates';
    PageType = List;
    SourceTable = "Interaction Template";
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
                    ApplicationArea = All;
                }
                field("Interaction Group Code"; Rec."Interaction Group Code")
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field("Word Template Code"; Rec."Word Template Code")
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Wizard Action"; Rec."Wizard Action")
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field("Correspondence Type (Default)"; Rec."Correspondence Type (Default)")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the preferred type of correspondence for the interaction. NOTE: If you use the Web client, you must not select the Hard Copy option because printing is not possible from the web client.';
                }
                field("Language Code (Default)"; Rec."Language Code (Default)")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the default language code for the interaction. If the contact''s preferred language is not available, then the program uses this language as the default language.';
                }
                field(Attachment; Rec."Attachment No." <> 0)
                {
                    ApplicationArea = RelationshipMgmt;
                    AssistEdit = true;
                    Caption = 'Attachment';
                    ToolTip = 'Specifies if the linked attachment is inherited or unique.';

                    trigger OnAssistEdit()
                    var
                        InteractTmplLanguage: Record "Interaction Tmpl. Language";
                    begin
                        if Rec."Word Template Code" <> '' then
                            Error(WordTemplateUsedErr);

                        if InteractTmplLanguage.Get(Rec.Code, Rec."Language Code (Default)") then begin
                            if InteractTmplLanguage."Attachment No." <> 0 then
                                InteractTmplLanguage.OpenAttachment()
                            else
                                InteractTmplLanguage.CreateAttachment();
                        end else begin
                            InteractTmplLanguage.Init();
                            InteractTmplLanguage."Interaction Template Code" := Rec.Code;
                            InteractTmplLanguage."Language Code" := Rec."Language Code (Default)";
                            InteractTmplLanguage.Description := Rec.Description;
                            InteractTmplLanguage.CreateAttachment();
                        end;
                        CurrPage.Update();
                    end;
                }
                field("Ignore Contact Corres. Type"; Rec."Ignore Contact Corres. Type")
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field("Unit Cost (LCY)"; Rec."Unit Cost (LCY)")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the cost, in LCY, of one unit of the item or resource on the line.';
                }
                field("Unit Duration (Min.)"; Rec."Unit Duration (Min.)")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the usual duration of interactions created using the interaction template.';
                }
                field("Information Flow"; Rec."Information Flow")
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field("Initiated By"; Rec."Initiated By")
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field("Campaign No."; Rec."Campaign No.")
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field("Campaign Target"; Rec."Campaign Target")
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field("Campaign Response"; Rec."Campaign Response")
                {
                    ApplicationArea = RelationshipMgmt;
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
            group("&Interaction Template")
            {
                Caption = '&Interaction Template';
                Image = Interaction;
                action("Interaction Log E&ntries")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Interaction Log E&ntries';
                    Image = InteractionLog;
                    RunObject = Page "Interaction Log Entries";
                    RunPageLink = "Interaction Template Code" = field(Code);
                    RunPageView = sorting("Interaction Template Code", Date);
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View a list of the interactions that you have logged, for example, when you create an interaction, print a cover sheet, a sales order, and so on.';
                }
                action(Statistics)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Interaction Tmpl. Statistics";
                    RunPageLink = Code = field(Code);
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
                action(Languages)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Languages';
                    Image = Language;
                    RunObject = Page "Interact. Tmpl. Languages";
                    RunPageLink = "Interaction Template Code" = field(Code);
                    ToolTip = 'Set up and select the preferred languages for the interactions with your contacts.';
                }
            }
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
                    var
                        InteractTemplLanguage: Record "Interaction Tmpl. Language";
                    begin
                        if Rec."Word Template Code" <> '' then
                            Error(WordTemplateUsedErr);

                        if InteractTemplLanguage.Get(Rec.Code, Rec."Language Code (Default)") then
                            InteractTemplLanguage.OpenAttachment();
                    end;
                }
                action(Create)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Create';
                    Ellipsis = true;
                    Image = New;
                    ToolTip = 'Create a new interaction template.';

                    trigger OnAction()
                    var
                        InteractTemplLanguage: Record "Interaction Tmpl. Language";
                    begin
                        if Rec."Word Template Code" <> '' then
                            Error(WordTemplateUsedErr);

                        if not InteractTemplLanguage.Get(Rec.Code, Rec."Language Code (Default)") then begin
                            InteractTemplLanguage.Init();
                            InteractTemplLanguage."Interaction Template Code" := Rec.Code;
                            InteractTemplLanguage."Language Code" := Rec."Language Code (Default)";
                            InteractTemplLanguage.Description := Rec.Description;
                        end;
                        InteractTemplLanguage.CreateAttachment();
                        CurrPage.Update();
                    end;
                }
                action("Copy &from")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Copy &from';
                    Ellipsis = true;
                    Image = Copy;
                    ToolTip = 'Copy an existing interaction template.';

                    trigger OnAction()
                    var
                        InteractTemplLanguage: Record "Interaction Tmpl. Language";
                    begin
                        if Rec."Word Template Code" <> '' then
                            Error(WordTemplateUsedErr);

                        if not InteractTemplLanguage.Get(Rec.Code, Rec."Language Code (Default)") then begin
                            InteractTemplLanguage.Init();
                            InteractTemplLanguage."Interaction Template Code" := Rec.Code;
                            InteractTemplLanguage."Language Code" := Rec."Language Code (Default)";
                            InteractTemplLanguage.Description := Rec.Description;
                            InteractTemplLanguage.Insert();
                            Commit();
                        end;
                        InteractTemplLanguage.CopyFromAttachment();
                        CurrPage.Update();
                    end;
                }
                action(Import)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Import';
                    Ellipsis = true;
                    Image = Import;
                    ToolTip = 'Import an interaction template.';

                    trigger OnAction()
                    var
                        InteractTemplLanguage: Record "Interaction Tmpl. Language";
                    begin
                        if Rec."Word Template Code" <> '' then
                            Error(WordTemplateUsedErr);

                        if not InteractTemplLanguage.Get(Rec.Code, Rec."Language Code (Default)") then begin
                            InteractTemplLanguage.Init();
                            InteractTemplLanguage."Interaction Template Code" := Rec.Code;
                            InteractTemplLanguage."Language Code" := Rec."Language Code (Default)";
                            InteractTemplLanguage.Description := Rec.Description;
                            InteractTemplLanguage.Insert();
                        end;
                        InteractTemplLanguage.ImportAttachment();
                        CurrPage.Update();
                    end;
                }
                action("E&xport")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'E&xport';
                    Ellipsis = true;
                    Image = Export;
                    ToolTip = 'Export an interaction template.';

                    trigger OnAction()
                    var
                        InteractTemplLanguage: Record "Interaction Tmpl. Language";
                    begin
                        if Rec."Word Template Code" <> '' then
                            Error(WordTemplateUsedErr);

                        if InteractTemplLanguage.Get(Rec.Code, Rec."Language Code (Default)") then
                            InteractTemplLanguage.ExportAttachment();
                    end;
                }
                action(Remove)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Remove';
                    Ellipsis = true;
                    Image = Cancel;
                    ToolTip = 'Remote an interaction template.';

                    trigger OnAction()
                    var
                        InteractTemplLanguage: Record "Interaction Tmpl. Language";
                    begin
                        if Rec."Word Template Code" <> '' then
                            Error(WordTemplateUsedErr);

                        if InteractTemplLanguage.Get(Rec.Code, Rec."Language Code (Default)") then
                            InteractTemplLanguage.RemoveAttachment(true);
                    end;
                }
            }
            action(WordTemplate)
            {
                ApplicationArea = All;
                Caption = 'Create Interaction Word Template';
                ToolTip = 'Create a Word template to use in interaction templates.';
                Image = Word;

                trigger OnAction()
                var
                    InteractionMergeData: Record "Interaction Merge Data";
                    CompanyInformation: Record "Company Information";
                    WordTemplateInteractions: Codeunit "Word Template Interactions";
                    WordTemplatesCreationWizard: Page "Word Template Creation Wizard";
                    IncludeFields: List of [Text[30]];
                begin
                    WordTemplatesCreationWizard.SetTableNo(Database::"Interaction Merge Data");
                    WordTemplatesCreationWizard.SetRelatedTable(Database::"Contact", InteractionMergeData.FieldNo("Contact No."), 'CONTA');
                    WordTemplatesCreationWizard.SetRelatedTable(Database::"Salesperson/Purchaser", InteractionMergeData.FieldNo("Salesperson Code"), 'SALES');
                    if CompanyInformation.FindFirst() then
                        WordTemplatesCreationWizard.SetUnrelatedTable(Database::"Company Information", CompanyInformation.SystemId, 'COMPA');

                    IncludeFields.Add(CopyStr(CompanyInformation.FieldName("Post Code"), 1, 30));
                    IncludeFields.Add(CopyStr(CompanyInformation.FieldName(IBAN), 1, 30));
                    IncludeFields.Add(CopyStr(CompanyInformation.FieldName("SWIFT Code"), 1, 30));
                    WordTemplatesCreationWizard.SetFieldsToBeIncluded(Database::"Company Information", IncludeFields);

                    WordTemplateInteractions.OnBeforeCreateInteractionWordTemplate(WordTemplatesCreationWizard);
                    WordTemplatesCreationWizard.RunModal();
                end;
            }

        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                group(Category_Attachment)
                {
                    Caption = 'Attachment';

                    actionref(Open_Promoted; Open)
                    {
                    }
                    actionref(Create_Promoted; Create)
                    {
                    }
                    actionref(Import_Promoted; Import)
                    {
                    }
                    actionref("E&xport_Promoted"; "E&xport")
                    {
                    }
                    actionref(Remove_Promoted; Remove)
                    {
                    }
                    actionref("Copy &from_Promoted"; "Copy &from")
                    {
                    }
                }
                actionref(WordTemplate_Promoted; WordTemplate)
                {
                }
                actionref(Statistics_Promoted; Statistics)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields("Attachment No.");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if Rec.GetFilter("Interaction Group Code") <> '' then
            if Rec.GetRangeMin("Interaction Group Code") = Rec.GetRangeMax("Interaction Group Code") then
                Rec."Interaction Group Code" := Rec.GetRangeMin("Interaction Group Code");
    end;

    var
        WordTemplateUsedErr: Label 'You cannot use an attachment when a Word template has been specified.';
}

