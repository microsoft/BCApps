// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Journal;

page 7323 "Whse. Journal Batches"
{
    Caption = 'Whse. Journal Batches';
    DataCaptionExpression = DataCaption();
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Warehouse Journal Batch";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = Warehouse;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Warehouse;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = Warehouse;
                }
                field("No. Series"; Rec."No. Series")
                {
                    ApplicationArea = Warehouse;
                }
                field("Registering No. Series"; Rec."Registering No. Series")
                {
                    ApplicationArea = Warehouse;
                }
                field("Assigned User ID"; Rec."Assigned User ID")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("No. of Lines"; Rec."No. of Lines")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of lines in this journal batch.';
                    Visible = false;
                }
            }
        }
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

    actions
    {
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.SetupNewBatch();
    end;

    local procedure DataCaption(): Text[250]
    var
        WhseJnlTemplate: Record "Warehouse Journal Template";
    begin
        if not CurrPage.LookupMode then
            if Rec.GetFilter("Journal Template Name") <> '' then
                if Rec.GetRangeMin("Journal Template Name") = Rec.GetRangeMax("Journal Template Name") then
                    if WhseJnlTemplate.Get(Rec.GetRangeMin("Journal Template Name")) then
                        exit(WhseJnlTemplate.Name + ' ' + WhseJnlTemplate.Description);
    end;
}

