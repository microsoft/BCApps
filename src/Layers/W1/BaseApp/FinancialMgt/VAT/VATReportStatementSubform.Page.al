// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

page 742 "VAT Report Statement Subform"
{
    Caption = 'VAT Report Statement Subform';
    PageType = ListPart;
    ShowFilter = false;
    SourceTable = "VAT Statement Report Line";
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Row No."; Rec."Row No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a number that identifies the line.';
                    Editable = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the VAT report statement.';
                    Editable = false;
                }
                field("Box No."; Rec."Box No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number on the box that the VAT statement applies to.';
                    Editable = false;
                }
                field(Note; Rec.Note)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies any text that you want to add to the specific line.';
                    Visible = ShowVATNote;
                }
                field(Base; Rec.Base)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount that the VAT amount in the amount is calculated from.';
                    Visible = ShowBase;
                    Editable = false;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the entry in the report statement.';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
    }

    var
        ShowBase: Boolean;
        ShowVATNote: Boolean;

    trigger OnOpenPage()
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        VATReportSetup.Get();
        ShowBase := VATReportSetup."Report VAT Base";
        ShowVATNote := VATReportSetup."Report VAT Note";
    end;

    procedure SelectFirst()
    begin
        if Rec.Count > 0 then
            Rec.FindFirst();
    end;
}

