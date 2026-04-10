// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Duplicates;

page 5138 "Duplicate Search String Setup"
{
    Caption = 'Duplicate Search String Setup';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Duplicate Search String Setup";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Field Name"; Rec."Field Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    Editable = false;

                    trigger OnAssistEdit()
                    begin
                        if GuiAllowed() then
                            Rec.LookupFieldName();
                    end;
                }
                field("Part of Field"; Rec."Part of Field")
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field(Length; Rec.Length)
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
    }
}

