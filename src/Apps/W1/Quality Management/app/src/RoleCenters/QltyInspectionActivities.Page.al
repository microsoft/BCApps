// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.RoleCenters;

using Microsoft.QualityManagement.Document;

page 20425 "Qlty. Inspection Activities"
{
    Caption = 'Activities';
    PageType = CardPart;
    RefreshOnActivate = true;
    SourceTable = "Qlty. Mgmt. Role Center Cue";
    ApplicationArea = QualityManagement;

    layout
    {
        area(Content)
        {
            cuegroup("Current Tests")
            {
                Caption = 'Current Tests';

                field("Unassigned Tests"; Rec."Unassigned Tests")
                {
                    DrillDownPageID = "Qlty. Inspection List";
                }
                field("My Open Tests"; Rec."My Open Tests")
                {
                    DrillDownPageID = "Qlty. Inspection List";
                }
                field("My Open and Due Tests"; Rec."My Open and Due Tests")
                {
                    DrillDownPageID = "Qlty. Inspection List";
                }
                field("All Open Tests"; Rec."All Open Tests")
                {
                    DrillDownPageID = "Qlty. Inspection List";
                }
                field("All Open and Due Tests"; Rec."All Open and Due Tests")
                {
                    DrillDownPageID = "Qlty. Inspection List";
                }
            }
            cuegroup("Finished Tests")
            {
                Caption = 'Finished Tests';

                field("My Finished Tests"; Rec."My Finished Tests")
                {
                    DrillDownPageID = "Qlty. Inspection List";
                }
                field("All Finished Tests"; Rec."All Finished Tests")
                {
                    DrillDownPageID = "Qlty. Inspection List";
                }
            }
        }
    }

    trigger OnInit()
    begin
        if not Rec.Get() then
            if Rec.Insert() then;
    end;
}
