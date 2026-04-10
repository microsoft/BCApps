// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

page 1431 "Forward Links"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Forward Links';
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Named Forward Link";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Link; Rec.Link)
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Load)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Load';
                Image = Import;
                ToolTip = 'Fill the table with the links used by error handlers.';

                trigger OnAction()
                begin
                    Rec.Load();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Load_Promoted; Load)
                {
                }
            }
        }
    }
}

