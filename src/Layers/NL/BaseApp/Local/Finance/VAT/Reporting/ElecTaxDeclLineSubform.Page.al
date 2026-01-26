// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

page 11413 "Elec. Tax Decl. Line Subform"
{
    Caption = 'Lines';
    Editable = false;
    PageType = ListPart;
    SourceTable = "Elec. Tax Declaration Line";

    layout
    {
        area(content)
        {
            repeater(Control1000000)
            {
                IndentationColumn = NameIndent;
                IndentationControls = Name;
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the XML element or XML attribute.';
                }
                field(Data; Rec.Data)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the data of the XML element or XML attribute.';
                }
                field("Line Type"; Rec."Line Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the Elec. Tax Declaration Line contains data of an XML element or XML attribute.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        NameIndent := 0;
        NameOnFormat();
    end;

    trigger OnOpenPage()
    begin
        Rec.SetRange("Line Type", Rec."Line Type"::Element);
    end;

    var
        NameEmphasize: Boolean;
        NameIndent: Integer;

    local procedure NameOnFormat()
    begin
        NameIndent := Rec."Indentation Level";
        NameEmphasize := Rec."Line Type" = Rec."Line Type"::Element;
    end;
}

