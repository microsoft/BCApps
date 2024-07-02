// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

page 333 "No. Series Proposal Sub"
{

    Caption = 'No. Series Proposals';
    PageType = ListPart;
    SourceTable = "No. Series Proposal Line";
    SourceTableTemporary = true;
    DeleteAllowed = true;
    InsertAllowed = false;
    ModifyAllowed = true;
    InherentPermissions = X;
    InherentEntitlements = X;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Series Code"; Rec."Series Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Series Code field.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Description field.';
                }
                field("Starting No."; Rec."Starting No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Starting No. field.';
                }
                field("Increment-by No."; Rec."Increment-by No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Increment-by No. field.';
                }
                field("Ending No."; Rec."Ending No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Ending No. field.';
                }
                field("Warning No."; Rec."Warning No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Warning No. field.';
                }
            }
        }
    }

    internal procedure Load(var NoSeriesGenerated: Record "No. Series Proposal Line")
    begin
        NoSeriesGenerated.Reset();
        if NoSeriesGenerated.FindSet() then
            repeat
                Rec := NoSeriesGenerated;
                Rec.Insert();
            until NoSeriesGenerated.Next() = 0;
    end;

    internal procedure GetTempRecord(EntryNo: Integer; var NoSeriesGenerated: Record "No. Series Proposal Line")
    begin
        NoSeriesGenerated.DeleteAll();
        Rec.Reset();
        Rec.SetRange("Proposal No.", EntryNo);
        if Rec.FindSet() then
            repeat
                NoSeriesGenerated.Copy(Rec, false);
                NoSeriesGenerated.Insert();
            until Rec.Next() = 0;
    end;
}
