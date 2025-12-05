// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

page 130463 "Test Input Group Languages"
{
    PageType = ListPart;
    SourceTable = "Test Input Group";
    Caption = 'Language Versions';
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Languages)
            {
                Editable = false;

                field("Language Tag"; Rec."Language Tag")
                {
                    ApplicationArea = All;

                    trigger OnDrillDown()
                    var
                        TestInputPage: Page "Test Input";
                    begin
                        TestInputPage.SetRecord(Rec);
                        TestInputPage.Run();
                    end;
                }
                field("Language Name"; Rec."Language Name")
                {
                    ApplicationArea = All;
                }
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field("No. of Entries"; Rec."No. of Entries")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetCurrentKey("Group Name", "Language ID");
    end;
}
