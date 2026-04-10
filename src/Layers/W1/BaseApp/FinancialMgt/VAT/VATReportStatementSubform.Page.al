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
                    Editable = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Box No."; Rec."Box No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field(Note; Rec.Note)
                {
                    ApplicationArea = Basic, Suite;
                    Visible = ShowVATNote;
                }
                field(Base; Rec.Base)
                {
                    ApplicationArea = Basic, Suite;
                    Visible = ShowBase;
                    Editable = false;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
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

