// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

/// <summary>
/// Interactive worksheet for configuring allowed dimension values per account basis.
/// Enables users to specify which dimension values are permitted for specific accounts, customers, vendors, or items.
/// </summary>
/// <remarks>
/// Used in dimension value restrictions where certain accounts should only allow specific dimension values.
/// Provides bulk operations to set allowed/disallowed status for multiple dimension values simultaneously.
/// Integrates with default dimension setup to enforce dimension value constraints during posting operations.
/// </remarks>
page 546 "Dim. Allowed Values per Acc."
{
    Caption = 'Allowed Dimension Values';
    PageType = Worksheet;
    DataCaptionExpression = Rec.GetCaption();
    SourceTable = "Dim. Value per Account";
    SourceTableTemporary = true;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = true;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                IndentationColumn = NameIndent;
                IndentationControls = DimensionValueName;
                ShowCaption = false;
                field(DimensionValueCode; Rec."Dimension Value Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = Emphasize;
                }
                field(DimensionValueName; Rec."Dimension Value Name")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = Emphasize;
                }
                field(Allowed; Rec.Allowed)
                {
                    ApplicationArea = Dimensions;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(SetAllowed)
            {
                ApplicationArea = Dimensions;
                Caption = 'Set Allowed';
                Image = Approve;
                ToolTip = 'Set selected dimension values allowed.';

                trigger OnAction()
                var
                    DimValuePerAccount: Record "Dim. Value per Account";
                begin
                    CurrPage.SetSelectionFilter(DimValuePerAccount);
                    if DimValuePerAccount.FindSet() then
                        repeat
                            Rec.Get(DimValuePerAccount."Table ID", DimValuePerAccount."No.", DimValuePerAccount."Dimension Code", DimValuePerAccount."Dimension Value Code");
                            Rec.Validate(Allowed, true);
                            Rec.Modify();
                        until DimValuePerAccount.Next() = 0;
                end;
            }
            action(SetDisallowed)
            {
                ApplicationArea = Dimensions;
                Caption = 'Set Disallowed';
                Image = Reject;
                ToolTip = 'Specify the dimension values that cannot be used for an account.';

                trigger OnAction()
                var
                    DimValuePerAccount: Record "Dim. Value per Account";
                begin
                    CurrPage.SetSelectionFilter(DimValuePerAccount);
                    if DimValuePerAccount.FindSet() then
                        repeat
                            Rec.Get(DimValuePerAccount."Table ID", DimValuePerAccount."No.", DimValuePerAccount."Dimension Code", DimValuePerAccount."Dimension Value Code");
                            Rec.Validate(Allowed, false);
                            Rec.Modify();
                        until DimValuePerAccount.Next() = 0;
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(SetAllowed_Promoted; SetAllowed)
                {
                }
                actionref(SetDisallowed_Promoted; SetDisallowed)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        NameIndent := 0;
        FormatLine();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = Action::LookupOK then begin
            Rec.Reset();
            DimMgt.CheckIfNoAllowedValuesSelected(Rec);
        end;
    end;

    var
        DimMgt: Codeunit DimensionManagement;
        Emphasize: Boolean;
        NameIndent: Integer;

    local procedure FormatLine()
    begin
        Rec.CalcFields("Dimension Value Type", Indentation);
        Emphasize := Rec."Dimension Value Type" <> Rec."Dimension Value Type"::Standard;
        NameIndent := Rec.Indentation;
    end;

    /// <summary>
    /// Populates the page buffer with dimension value per account data for display in the worksheet.
    /// Transfers data from temporary records to the page's record structure for proper display formatting.
    /// </summary>
    /// <param name="TempDimValuePerAccount">Temporary buffer containing dimension value restriction data to display</param>
    procedure SetBufferData(var TempDimValuePerAccount: Record "Dim. Value per Account" temporary)
    begin
        if TempDimValuePerAccount.FindSet() then
            repeat
                Rec := TempDimValuePerAccount;
                Rec.Insert();
            until TempDimValuePerAccount.Next() = 0;
    end;

    /// <summary>
    /// Retrieves modified dimension value allowance data from the page buffer back to temporary records.
    /// Updates the temporary buffer with changes made through the worksheet interface.
    /// </summary>
    /// <param name="TempDimValuePerAccount">Temporary buffer to update with modified allowance settings</param>
    procedure GetBufferData(var TempDimValuePerAccount: Record "Dim. Value per Account" temporary)
    begin
        Rec.Reset();
        if Rec.FindSet() then
            repeat
                TempDimValuePerAccount.Get(Rec."Table ID", Rec."No.", Rec."Dimension Code", Rec."Dimension Value Code");
                TempDimValuePerAccount.Allowed := Rec.Allowed;
                TempDimValuePerAccount.Modify();
            until Rec.Next() = 0;
    end;
}
