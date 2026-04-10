// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

/// <summary>
/// Display page for viewing dimension set entries in a read-only list format.
/// Shows all dimension entries for a specific dimension set ID with codes, names, and values.
/// </summary>
/// <remarks>
/// Used as a drill-down page from dimension set ID fields and as a lookup page for dimension set references.
/// Provides detailed view of dimension combinations with optional shortcut dimension number update functionality.
/// Supports custom captions when displayed in different contexts throughout the application.
/// </remarks>
page 479 "Dimension Set Entries"
{
    Caption = 'Dimension Set Entries';
    Editable = false;
    PageType = List;
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
                field(DimensionValueCode; Rec."Dimension Value Code")
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
        area(Processing)
        {
            action(UpdDimSetGlblDimNo)
            {
                ApplicationArea = Dimensions;
                Caption = 'Update Shortcut Dimension No.';
                Image = ChangeDimensions;
                ToolTip = 'Fix incorrect settings for one or more global or shortcut dimensions.';
                Visible = UpdDimSetGlblDimNoVisible;

                trigger OnAction()
                begin
                    Report.Run(Report::"Update Dim. Set Glbl. Dim. No.");
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(UpdDimSetGlblDimNo_Promoted; UpdDimSetGlblDimNo)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if FormCaption <> '' then
            CurrPage.Caption := FormCaption;
    end;

    var
        FormCaption: Text[250];

    /// <summary>
    /// Sets a custom caption for the page by appending text to the default caption.
    /// Used to provide context-specific titles when the page is opened from different sources.
    /// </summary>
    /// <param name="NewFormCaption">Text to prepend to the default page caption</param>
    procedure SetFormCaption(NewFormCaption: Text[250])
    begin
        FormCaption := CopyStr(NewFormCaption + ' - ' + CurrPage.Caption, 1, MaxStrLen(FormCaption));
    end;

    /// <summary>
    /// Makes the "Update Shortcut Dimension No." action visible on the page.
    /// Enables access to the utility for fixing incorrect global dimension number settings.
    /// </summary>
    procedure SetUpdDimSetGlblDimNoVisible()
    begin
        UpdDimSetGlblDimNoVisible := true;
    end;

    var
        UpdDimSetGlblDimNoVisible: Boolean;
}

