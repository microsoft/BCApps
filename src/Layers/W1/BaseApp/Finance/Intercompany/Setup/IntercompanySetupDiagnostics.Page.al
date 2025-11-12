// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Setup;

page 9051 "Intercompany Setup Diagnostics"
{
    PageType = ListPart;
    SourceTableTemporary = true;
    SourceTable = "Intercompany Setup Diagnostic";
    layout
    {
        area(Content)
        {
            cuegroup(Diagnostics)
            {
                Caption = 'Issues Found';
                field(PartnerSetup; GetDiagnosticsErrorsCount(ICSetupDiagnostics.GetPartnerSetupId()))
                {
                    CaptionClass = GetCaptionForDiagnostic(ICSetupDiagnostics.GetPartnerSetupId());
                    StyleExpr = PartnerSetupStyleExpr;
                    ApplicationArea = Intercompany;
                    Tooltip = 'IC Partner Diagnostics';
                    trigger OnDrillDown()
                    begin
                        DrilldownDiagnostics(ICSetupDiagnostics.GetPartnerSetupId());
                    end;
                }
                field(MappingSetup; GetDiagnosticsErrorsCount(ICSetupDiagnostics.GetMappingSetupId()))
                {
                    CaptionClass = GetCaptionForDiagnostic(ICSetupDiagnostics.GetMappingSetupId());
                    StyleExpr = MappingSetupStyleExpr;
                    ApplicationArea = Intercompany;
                    Tooltip = 'IC Mapping Diagnostics';
                    trigger OnDrillDown()
                    begin
                        DrilldownDiagnostics(ICSetupDiagnostics.GetMappingSetupId());
                    end;
                }
            }
        }
    }
    var
        TempSubIntercompanySetupDiagnostic: Record "Intercompany Setup Diagnostic" temporary;
        ICSetupDiagnostics: Codeunit "IC Setup Diagnostics";
        PartnerSetupStyleExpr: Text;
        MappingSetupStyleExpr: Text;

    trigger OnInit()
    begin
        // Diagnostics related to companies having different ICSetup code 
        ICSetupDiagnostics.InsertPartnerSetupDiagnostics(Rec, TempSubIntercompanySetupDiagnostic);
        // Diagnostics related to missing mappings
        ICSetupDiagnostics.InsertMappingSetupDiagnostics(Rec, TempSubIntercompanySetupDiagnostic);
        SetupStyleExprs();
    end;

    local procedure DrilldownDiagnostics(Id: Code[20])
    var
        ICSetupDiagnosticsList: Page "IC Setup Diagnostics List";
    begin
        TempSubIntercompanySetupDiagnostic.SetRange(Id, Id);
        if not TempSubIntercompanySetupDiagnostic.FindSet() then begin
            TempSubIntercompanySetupDiagnostic.SetRange(Id);
            exit;
        end;
        repeat
            ICSetupDiagnosticsList.InsertDiagnostic(TempSubIntercompanySetupDiagnostic);
        until TempSubIntercompanySetupDiagnostic.Next() = 0;
        TempSubIntercompanySetupDiagnostic.SetRange(Id);
        ICSetupDiagnosticsList.RunModal();
    end;

    local procedure GetDiagnosticsErrorsCount(DiagnosticId: Text): Integer
    var
        DiagnosticsCount: Integer;
    begin
        TempSubIntercompanySetupDiagnostic.SetRange(Id, DiagnosticId);
        DiagnosticsCount := TempSubIntercompanySetupDiagnostic.Count();
        TempSubIntercompanySetupDiagnostic.SetRange(Id);
        exit(DiagnosticsCount);
    end;

    local procedure GetCaptionForDiagnostic(DiagnosticId: Text): Text
    begin
        Rec.SetRange(Id, DiagnosticId);
        if not Rec.FindFirst() then begin
            Rec.SetRange(Id);
            exit('');
        end;
        Rec.SetRange(Id);
        exit(Rec.Description);
    end;

    local procedure SetupStyleExprs()
    begin
        Rec.SetRange(Id, ICSetupDiagnostics.GetPartnerSetupId());
        if Rec.FindFirst() then
            case Rec.Status of
                Rec.Status::Ok:
                    PartnerSetupStyleExpr := 'Favorable';
                else
                    PartnerSetupStyleExpr := 'Unfavorable';
            end;
        Rec.SetRange(Id, ICSetupDiagnostics.GetMappingSetupId());
        if Rec.FindFirst() then
            case Rec.Status of
                Rec.Status::Ok:
                    MappingSetupStyleExpr := 'Favorable';
                else
                    MappingSetupStyleExpr := 'Unfavorable';
            end;
        Rec.SetRange(Id);
    end;
}
