// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

page 12201 "Fattura Project Info"
{
    Caption = 'Fattura Project Info';
    PageType = List;
    SourceTable = "Fattura Project Info";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a code that identifies the type of project.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line type.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Rec.SetRecFilter();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        case Rec.GetFilter(Type) of
            'Project':
                Rec.Validate(Type, Rec.Type::Project);
            'Tender':
                Rec.Validate(Type, Rec.Type::Tender);
        end;
    end;
}

