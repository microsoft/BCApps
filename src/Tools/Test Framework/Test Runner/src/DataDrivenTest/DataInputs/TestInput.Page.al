// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

page 130457 "Test Input"
{
    PageType = Document;
    ApplicationArea = All;
    SourceTable = "Test Input Group";

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    Caption = 'Code';
                    ToolTip = 'Specifies the code for the test input.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                    ToolTip = 'Specifies the description of the test input.';
                }
                field(Sensitive; Rec.Sensitive)
                {
                    ApplicationArea = All;
                    Caption = 'Sensitive';
                    ToolTip = 'Specifies if the test input is sensitive and should not be shown directly off the page.';
                }
                field("No. of Entries"; Rec."No. of Entries")
                {
                    ApplicationArea = All;
                    Caption = 'No. of Entries';
                    ToolTip = 'Specifies the number of entries in the dataset.';
                    Editable = false;
                }
            }
            part(TestInputPart; "Test Input Part")
            {
                ApplicationArea = All;
                SubPageLink = "Test Input Group Code" = field(Code);
            }
        }
    }
}