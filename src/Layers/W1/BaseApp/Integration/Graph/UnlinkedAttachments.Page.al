// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Graph;

page 199 "Unlinked Attachments"
{
    Caption = 'Unlinked Files';
    Editable = false;
    PageType = List;
    SourceTable = "Unlinked Attachment";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("File Name"; Rec."File Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Created Date-Time"; Rec."Created Date-Time")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field(ID; Rec.ID)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
            }
        }
    }

    actions
    {
    }
}

