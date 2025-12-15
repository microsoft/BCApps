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
            cuegroup("Current Inspections")
            {
                Caption = 'Current Tests';

                field("Unassigned Inspections"; Rec."Unassigned Inspections")
                {
                    DrillDownPageID = "Qlty. Inspection List";
                }
                field("My Open Inspections"; Rec."My Open Inspections")
                {
                    DrillDownPageID = "Qlty. Inspection List";
                }
                field("My Open and Due Inspections"; Rec."My Open and Due Inspections")
                {
                    DrillDownPageID = "Qlty. Inspection List";
                }
                field("All Open Inspections"; Rec."All Open Inspections")
                {
                    DrillDownPageID = "Qlty. Inspection List";
                }
                field("All Open and Due Inspections"; Rec."All Open and Due Inspections")
                {
                    DrillDownPageID = "Qlty. Inspection List";
                }
            }
            cuegroup("Finished Inspections")
            {
                Caption = 'Finished Tests';

                field("My Finished Inspections"; Rec."My Finished Inspections")
                {
                    DrillDownPageID = "Qlty. Inspection List";
                }
                field("All Finished Inspections"; Rec."All Finished Inspections")
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
