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
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field(Code; Rec.Code)
                {
                }
                field(Description; Rec.Description)
                {
                }
                field(Sensitive; Rec.Sensitive)
                {
                }
                field("No. of Entries"; Rec."No. of Entries")
                {
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