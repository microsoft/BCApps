// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Analysis;

/// <summary>
/// Provides user configuration options for the trailing sales orders chart.
/// </summary>
page 761 "Trailing Sales Orders Setup"
{
    Caption = 'Trailing Sales Orders Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = StandardDialog;
    SourceTable = "Trailing Sales Orders Setup";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Use Work Date as Base"; Rec."Use Work Date as Base")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        if not Rec.Get(UserId) then begin
            Rec."User ID" := CopyStr(UserId(), 1, MaxStrLen(Rec."User ID"));
            Rec."Use Work Date as Base" := true;
            Rec.Insert();
        end;
        Rec.FilterGroup(2);
        Rec.SetRange("User ID", UserId);
        Rec.FilterGroup(0);
    end;
}

