// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Setup;

page 9097 "IC Setup Diagnostics List"
{
    PageType = List;
    SourceTable = "Intercompany Setup Diagnostic";
    SourceTableTemporary = true;
    Editable = false;
    DeleteAllowed = false;
    layout
    {
        area(Content)
        {
            repeater(SubDiagnostics)
            {
                field(Description; Rec.Description)
                {
                    Tooltip = 'Description of the intercompany setup issue found.';
                    ApplicationArea = Intercompany;
                    StyleExpr = DiagnosticStyle;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        case Rec.Status of
            Rec.Status::Warning:
                DiagnosticStyle := 'AttentionAccent';
            Rec.Status::Error:
                DiagnosticStyle := 'Attention'
        end;
    end;

    var
        DiagnosticStyle: Text;

    procedure InsertDiagnostic(var TempIntercompanySetupDiagnostic: Record "Intercompany Setup Diagnostic" temporary)
    begin
        Clear(Rec);
        Rec.TransferFields(TempIntercompanySetupDiagnostic);
        Rec.Insert();
    end;
}
