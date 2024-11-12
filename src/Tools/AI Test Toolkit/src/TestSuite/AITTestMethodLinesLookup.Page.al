// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

page 149037 "AIT Test Method Lines Lookup"
{
    Caption = 'Test Method Lines';
    PageType = List;
    ApplicationArea = All;
    SourceTable = "AIT Test Method Line";
    Extensible = false;
    UsageCategory = None;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field(CodeunitID; Rec."Codeunit ID")
                {
                }
                field(CodeunitName; Rec."Codeunit Name")
                {
                }
                field(InputDataset; Rec."Input Dataset")
                {
                }
                field(Description; Rec.Description)
                {
                }
            }
        }
    }
}