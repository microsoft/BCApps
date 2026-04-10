// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;

page 968 "Time Sheet Line Assemb. Detail"
{
    Caption = 'Time Sheet Line Assemb. Detail';
    Editable = false;
    PageType = StandardDialog;
    SourceTable = "Time Sheet Line";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Assembly Order No."; Rec."Assembly Order No.")
                {
                    ApplicationArea = Assembly;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Jobs;
                }
                field(Chargeable; Rec.Chargeable)
                {
                    ApplicationArea = Jobs;
                }
            }
        }
    }

    actions
    {
    }

    procedure SetParameters(TimeSheetLine: Record "Time Sheet Line")
    begin
        Rec := TimeSheetLine;
        Rec.Insert();
    end;
}

