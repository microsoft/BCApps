// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7075 "EA KPI Entries"
{
    PageType = List;
    Caption = 'Expense Agent Entries';
    ApplicationArea = All;
    SourceTable = "EA KPI Entry";
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            repeater(Main)
            {
                field(Type; Rec."Record Type")
                {
                    Visible = TypeVisible;
                    ToolTip = 'Specifies the type of the record (Expense or Expense Report).';
                }
                field("No."; Rec."No.")
                {
                    ToolTip = 'Specifies the document number of the record.';

                    trigger OnDrillDown()
                    begin
                        Rec.OpenCard();
                    end;
                }
                field(CreatedByExpUserId; Rec."Created By Exp. User Id")
                {
                    Visible = false;
                    ToolTip = 'Specifies the SystemId of the Expense User on whose behalf the record was created by the Expense Agent.';

                    trigger OnDrillDown()
                    var
                        ExpenseUser: Record "Expense User";
                    begin
                        ExpenseUser.GetBySystemId(Rec."Created By Exp. User Id");
                        Page.Run(Page::"Expense User", ExpenseUser);
                    end;
                }
                field(ExpenseUserName; Rec."Expense User Name")
                {
                    ToolTip = 'Specifies the name of the Expense User on whose behalf the record was created by the Expense Agent.';

                    trigger OnDrillDown()
                    var
                        ExpenseUser: Record "Expense User";
                    begin
                        ExpenseUser.GetBySystemId(Rec."Created By Exp. User Id");
                        Page.Run(Page::"Expense User", ExpenseUser);
                    end;
                }
                field(SystemModifiedAt; Rec.SystemModifiedAt)
                {
                    Caption = 'Date Modified';
                    ToolTip = 'Specifies the date and time when the record was last modified.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(View)
            {
                ApplicationArea = All;
                Caption = 'View';
                ToolTip = 'Opens the record.';
                Image = View;

                trigger OnAction()
                begin
                    Rec.OpenCard();
                end;
            }
        }
        area(Promoted)
        {
            actionref(View_Promoted; View)
            {
            }
        }
    }

    trigger OnOpenPage()
    begin
        TypeVisible := Rec.GetFilter("Record Type") = '';
        if TypeVisible then
            exit;

        if Rec.GetFilter("Record Type") = Format(Rec."Record Type"::Expense) then
            Caption := 'Expenses created by Expense Agent';

        if Rec.GetFilter("Record Type") = Format(Rec."Record Type"::"Expense Report") then
            Caption := 'Expense Reports created by Expense Agent';
    end;

    var
        TypeVisible: Boolean;
}
