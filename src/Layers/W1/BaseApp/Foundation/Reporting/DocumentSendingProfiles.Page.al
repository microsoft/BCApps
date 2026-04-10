// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

page 359 "Document Sending Profiles"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Document Sending Profiles';
    CardPageID = "Document Sending Profile";
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Document Sending Profile";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Default; Rec.Default)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Printer; Rec.Printer)
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Electronic Document"; Rec."Electronic Document")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Electronic Format"; Rec."Electronic Format")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Format';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }
}

