// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

page 12200 "Fattura Codes"
{
    Caption = 'Fattura Codes';
    PageType = List;
    SourceTable = "Fattura Code";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a code that identifies the type.';
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
            'Payment Terms':
                Rec.Validate(Type, Rec.Type::"Payment Terms");
            'Payment Method':
                Rec.Validate(Type, Rec.Type::"Payment Method");
        end;
    end;
}

