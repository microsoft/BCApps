// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.RoleCenters;

using Microsoft.EServices.EDocument;

pageextension 7000133 "SII Acc. Payables Activities" extends "Acc. Payables Activities"
{
    layout
    {
        addafter("Document Approvals")
        {
            cuegroup(MissingSIIEntries)
            {
                Caption = 'Missing SII Entries';
                field("Missing SII Entries"; Rec."Missing SII Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Missing SII Entries';
                    DrillDownPageID = "Recreate Missing SII Entries";
                    ToolTip = 'Specifies that some posted documents were not transferred to SII.';

                    trigger OnDrillDown()
                    var
                        SIIRecreateMissingEntries: Codeunit "SII Recreate Missing Entries";
                    begin
                        SIIRecreateMissingEntries.ShowRecreateMissingEntriesPage();
                    end;
                }
                field("Days Since Last SII Check"; Rec."Days Since Last SII Check")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Recreate Missing SII Entries";
                    Image = Calendar;
                    ToolTip = 'Specifies the number of days since the last check for missing SII entries.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        SIIRecreateMissingEntries: Codeunit "SII Recreate Missing Entries";
    begin
        if Rec.FieldActive("Missing SII Entries") then
            Rec."Missing SII Entries" := SIIRecreateMissingEntries.GetMissingEntriesCount();
        if Rec.FieldActive("Days Since Last SII Check") then
            Rec."Days Since Last SII Check" := SIIRecreateMissingEntries.GetDaysSinceLastCheck();
    end;
}