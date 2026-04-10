// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

page 333 "No. Series Generation Sub"
{

    Caption = 'No. Series Generations';
    PageType = ListPart;
    SourceTable = "No. Series Generation Detail";
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
                    Enabled = IsEnabled;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Description field.';
                    Enabled = IsEnabled;
                }
                field("Starting No."; Rec."Starting No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Starting No. field.';
                    Enabled = IsEnabled;
                }
                field("Increment-by No."; Rec."Increment-by No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Increment-by No. field.';
                    Enabled = IsEnabled;
                }
                field("Ending No."; Rec."Ending No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Ending No. field.';
                    Enabled = IsEnabled;
                }
                field("Warning No."; Rec."Warning No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Warning No. field.';
                    Enabled = IsEnabled;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Starting Date field.';
                    Enabled = IsEnabled;
                }
                field(Message; Rec.Message)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Message field.';
                    Style = Attention;
                    Editable = false;
                }
                field("Setup Table Name"; Rec."Setup Table Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Setup Table Name field.';
                    Enabled = IsEnabled;
                }
                field("Setup Field Name"; Rec."Setup Field Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Setup Field Name field.';
                    Enabled = IsEnabled;
                }

            }
        }
    }

    var
        IsEnabled: Boolean;

    trigger OnAfterGetRecord()
    begin
        IsEnabled := not Rec.Exists;
    end;

    internal procedure Load(var GeneratedNoSeries: Record "No. Series Generation Detail")
    begin
        GeneratedNoSeries.Reset();
        if GeneratedNoSeries.FindSet() then
            repeat
                Rec := GeneratedNoSeries;
                Rec.Insert();
            until GeneratedNoSeries.Next() = 0;
    end;

    internal procedure GetTempRecord(EntryNo: Integer; var GeneratedNoSeries: Record "No. Series Generation Detail")
    begin
        GeneratedNoSeries.DeleteAll();
        Rec.Reset();
        Rec.SetRange("Generation No.", EntryNo);
        if Rec.FindSet() then
            repeat
                GeneratedNoSeries.Copy(Rec, false);
                GeneratedNoSeries.Insert();
            until Rec.Next() = 0;
    end;
}
