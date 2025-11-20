// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

page 787 "New Fin. Report Excel Templ."
{
    Caption = 'Copy Financial Report Excel Layout';
    PageType = StandardDialog;
    Extensible = false;
    SourceTable = "Fin. Report Excel Template";
    SourceTableTemporary = true;
    DelayedInsert = true;

    layout
    {
        area(content)
        {
            field("Financial Report Name"; Rec."Financial Report Name")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
            }
            field(CodeToCopy; CodeToCopy)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Source Layout Code';
                ToolTip = 'Specifies the code of the existing layout to copy from.';
                Visible = CodeToCopy <> '';
                Editable = false;
            }
            field(NewCode; NewCode)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'New Layout Code';
                ToolTip = 'Specifies the code of the new layout.';
                ShowMandatory = true;
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = Action::Ok then begin
            if NewCode = '' then
                Error(MissingNewCodeErr);
            Rec.Code := NewCode;
        end;
    end;

    var
        NewCode: Code[50];
        CodeToCopy: Code[50];
        MissingNewCodeErr: Label 'You must specify a code for the new layout.';
        CopyOfTxt: Label 'Copy of %1', Comment = '%1 = Original layout description';

    internal procedure SetSource(SourceExcelTemplate: Record "Fin. Report Excel Template")
    begin
        Rec."Financial Report Name" := SourceExcelTemplate."Financial Report Name";
        Rec.Description := CopyStr(StrSubstNo(CopyOfTxt, SourceExcelTemplate.Description), 1, MaxStrLen(Rec.Description));
        Rec.Insert();
        CodeToCopy := SourceExcelTemplate.Code;
    end;
}