// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Catalog;

page 5732 "Catalog Item Setup"
{
    AdditionalSearchTerms = 'non-inventoriable setup,special order setup';
    ApplicationArea = Basic, Suite;
    Caption = 'Catalog Item Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Nonstock Item Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No. Format"; Rec."No. Format")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the format of the catalog item number that appears on the item card.';
                    trigger OnValidate()
                    begin
                        NoFormatSeparatorEditable := Rec."No. Format" <> Rec."No. Format"::"Item No. Series";
                    end;
                }
                field("No. Format Separator"; Rec."No. Format Separator")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = NoFormatSeparatorEditable;
                    ToolTip = 'Specifies the character that separates the elements of your catalog item number format, if the format uses both a code and a number.';
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

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;

    trigger OnAfterGetRecord()
    begin
        NoFormatSeparatorEditable := Rec."No. Format" <> Rec."No. Format"::"Item No. Series";
    end;

    var
        NoFormatSeparatorEditable: Boolean;
}
