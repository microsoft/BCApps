// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.AuditCodes;

/// <summary>
/// Source codes are used to categorize the source of a transaction.
/// </summary>
/// <remarks>
/// This page is used to set up source codes that are used to categorize the source of a transaction. 
/// Each feature that introduces a new transaction source should add a field to set up a default source code.
/// </remarks>
page 279 "Source Code Setup"
{
    ApplicationArea = All;
    Caption = 'Source Code Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Source Code Setup";
    UsageCategory = Administration;

    layout
    {
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}

