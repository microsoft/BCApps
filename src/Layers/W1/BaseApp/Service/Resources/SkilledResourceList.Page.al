// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Resources;

using Microsoft.Projects.Resources.Resource;
using Microsoft.Service.Document;

page 6023 "Skilled Resource List"
{
    Caption = 'Skilled Resource List';
    CardPageID = "Resource Card";
    DataCaptionExpression = GetCaption();
    Editable = false;
    PageType = List;
    SourceTable = Resource;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Qualified; Qualified)
                {
                    ApplicationArea = Service;
                    Caption = 'Skilled';
                    Editable = false;
                    ToolTip = 'Specifies that there are skills required to service the service item, service item group or item, if you have opened the Skilled Resource List window.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a description of the resource.';
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

    trigger OnAfterGetRecord()
    begin
        Clear(ServOrderAllocMgt);
        Qualified := ServOrderAllocMgt.ResourceQualified(Rec."No.", ResourceSkillType, ResourceSkillNo);
    end;

    var
        ServOrderAllocMgt: Codeunit ServAllocationManagement;
        Qualified: Boolean;
        ResourceSkillType: Enum "Resource Skill Type";
        ResourceSkillNo: Code[20];
        Description: Text[100];

    procedure Initialize(Type2: Enum "Resource Skill Type"; No2: Code[20]; Description2: Text[100])
    begin
        ResourceSkillType := Type2;
        ResourceSkillNo := No2;
        Description := Description2;
    end;

    local procedure GetCaption() Text: Text[260]
    begin
        Text := CopyStr(ResourceSkillNo + ' ' + Description, 1, MaxStrLen(Text));
    end;
}

