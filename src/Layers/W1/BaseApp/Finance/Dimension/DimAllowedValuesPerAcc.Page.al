// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

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
                    ToolTip = 'Specifies the code for the dimension value.';
                }
                field(DimensionValueName; Rec."Dimension Value Name")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies a descriptive name for the dimension value.';
                }
                field(Allowed; Rec.Allowed)
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies whether the related record can be posted in transactions.';
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

    procedure SetBufferData(var TempDimValuePerAccount: Record "Dim. Value per Account" temporary)
    begin
        if TempDimValuePerAccount.FindSet() then
            repeat
                Rec := TempDimValuePerAccount;
                Rec.Insert();
            until TempDimValuePerAccount.Next() = 0;
    end;

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
