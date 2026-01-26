// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

page 11000016 "Import Protocol List"
{
    Caption = 'Import Protocol List';
    Editable = false;
    PageType = List;
    SourceTable = "Import Protocol";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies an import protocol code that you want attached to the entry.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of what the import protocol stands for.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Modify)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Modify';
                Image = EditFilter;
                ToolTip = 'Change the setup of the selected import protocol.';

                trigger OnAction()
                begin
                    PAGE.Run(PAGE::"Import Protocols", Rec);
                    CurrPage.Update();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Modify_Promoted; Modify)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Rec.Find('-') then begin
            PAGE.RunModal(PAGE::"Import Protocols", Rec);
            if not Rec.Find('-') then
                CurrPage.Close();
        end;
    end;
}

