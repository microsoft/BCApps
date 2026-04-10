// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

/// <summary>
/// FactBox displaying dimension set entries for the current record in a read-only format.
/// Provides a compact view of dimension information in pages without requiring navigation to dimension details.
/// </summary>
/// <remarks>
/// Commonly used as a FactBox on document pages to show associated dimension values.
/// Automatically displays dimension codes, names, and values for the current dimension set ID.
/// Caption can be customized to reflect the context of the parent page or document.
/// </remarks>
page 699 "Dimension Set Entries FactBox"
{
    Caption = 'Dimensions';
    Editable = false;
    PageType = ListPart;
    SourceTable = "Dimension Set Entry";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Dimension Code"; Rec."Dimension Code")
                {
                    ApplicationArea = Dimensions;
                }
                field("Dimension Name"; Rec."Dimension Name")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("Dimension Value Code"; Rec."Dimension Value Code")
                {
                    ApplicationArea = Dimensions;
                }
                field("Dimension Value Name"; Rec."Dimension Value Name")
                {
                    ApplicationArea = Dimensions;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        if FormCaption <> '' then
            CurrPage.Caption := FormCaption;
    end;

    trigger OnInit()
    begin
        if FormCaption <> '' then
            CurrPage.Caption := FormCaption;
    end;

    var
        FormCaption: Text[250];

    /// <summary>
    /// Sets a custom caption for the FactBox by appending text to the default caption.
    /// Used to provide context-specific titles when the FactBox is displayed on different pages.
    /// </summary>
    /// <param name="NewFormCaption">Text to prepend to the default FactBox caption</param>
    procedure SetFormCaption(NewFormCaption: Text[250])
    begin
        FormCaption := CopyStr(NewFormCaption + ' - ' + CurrPage.Caption, 1, MaxStrLen(FormCaption));
    end;
}

