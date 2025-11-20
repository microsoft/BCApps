// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Maintenance;

using Microsoft.Service.Document;
using Microsoft.Service.Item;

page 5930 "Fault/Resol. Cod. Relationship"
{
    ApplicationArea = Service;
    Caption = 'Fault/Resolution Codes Relationships';
    DelayedInsert = true;
    PageType = Worksheet;
    SourceTable = "Fault/Resol. Cod. Relationship";
    SourceTableView = sorting("Service Item Group Code", "Fault Code", Occurrences)
                      order(descending);
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(ServItemGroupCode; ServItemGroupCode)
                {
                    ApplicationArea = Service;
                    Caption = 'Service Item Group';
                    TableRelation = "Service Item Group".Code;
                    ToolTip = 'Specifies the code for the service item group for which you want to setup a new combination. For example: CD ROM.';

                    trigger OnValidate()
                    begin
                        if ServItemGroupCode <> '' then
                            Rec.SetRange("Service Item Group Code", ServItemGroupCode)
                        else
                            Rec.SetRange("Service Item Group Code");
                        ServItemGroupCodeOnAfterValida();
                    end;
                }
                field(FaultArea; FaultArea)
                {
                    ApplicationArea = Service;
                    Caption = 'Fault Area Code';
                    TableRelation = "Fault Area".Code;
                    ToolTip = 'Specifies a code for the fault area. For example: communication.';

                    trigger OnValidate()
                    begin
                        if FaultArea <> '' then
                            Rec.SetRange("Fault Area Code", FaultArea)
                        else
                            Rec.SetRange("Fault Area Code");
                        FaultAreaOnAfterValidate();
                    end;
                }
                field(SymptomCode; SymptomCode)
                {
                    ApplicationArea = Service;
                    Caption = 'Symptom Code';
                    TableRelation = "Symptom Code".Code;
                    ToolTip = 'Specifies a code for the symptom. For example: Quality';

                    trigger OnValidate()
                    begin
                        if SymptomCode <> '' then
                            Rec.SetRange("Symptom Code", SymptomCode)
                        else
                            Rec.SetRange("Symptom Code");
                        SymptomCodeOnAfterValidate();
                    end;
                }
                field(FaultCode; FaultCode)
                {
                    ApplicationArea = Service;
                    Caption = 'Fault Code';
                    ToolTip = 'Specifies a code for the fault. For example: transmission.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        FaultCodeRec.SetRange("Fault Area Code", FaultArea);
                        FaultCodeRec.SetRange("Symptom Code", SymptomCode);
                        if not FaultCodeRec.Get(FaultArea, SymptomCode, FaultCode) then;
                        if PAGE.RunModal(0, FaultCodeRec) = ACTION::LookupOK then begin
                            FaultCode := FaultCodeRec.Code;
                            Rec.SetRange("Fault Code", FaultCode);
                            CurrPage.Update(false);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        if FaultCode <> '' then begin
                            FaultCodeRec.Get(FaultArea, SymptomCode, FaultCode);
                            Rec.SetRange("Fault Code", FaultCode);
                        end else
                            Rec.SetRange("Fault Code");
                        FaultCodeOnAfterValidate();
                    end;
                }
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Fault Area Code"; Rec."Fault Area Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the fault area code.';
                }
                field("Symptom Code"; Rec."Symptom Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the symptom code.';
                }
                field("Fault Code"; Rec."Fault Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the fault code.';
                }
                field("Resolution Code"; Rec."Resolution Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the resolution code.';
                }
                field("Service Item Group Code"; Rec."Service Item Group Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the service item group linked to the relationship.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a description of the relationship between the fault code and the resolution code.';
                }
                field(Occurrences; Rec.Occurrences)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of times the combination of fault code, symptom code, fault area, and resolution code occurs in the posted service lines.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [ACTION::OK, ACTION::LookupOK] then
            OKOnPush();
    end;

    var
        FaultCodeRec: Record "Fault Code";
        ServItemLine: Record "Service Item Line";
        ServInvLine: Record "Service Line";
        ServItemGroupCode: Code[10];
        FaultArea: Code[10];
        FaultCode: Code[10];
        SymptomCode: Code[10];
        ServTableID: Integer;
        ServDocumentType: Integer;
        ServDocumentNo: Code[20];
        ServLineNo: Integer;

    procedure SetFilters(Symptom: Code[10]; Fault: Code[10]; "Area": Code[10]; ServItemGroup: Code[10])
    begin
        ServItemGroupCode := ServItemGroup;
        FaultArea := Area;
        FaultCode := Fault;
        SymptomCode := Symptom;
        if Fault <> '' then
            Rec.SetRange("Fault Code", Fault)
        else
            Rec.SetRange("Fault Code");
        if Area <> '' then
            Rec.SetRange("Fault Area Code", Area)
        else
            Rec.SetRange("Fault Area Code");
        if Symptom <> '' then
            Rec.SetRange("Symptom Code", Symptom)
        else
            Rec.SetRange("Symptom Code");
        if ServItemGroup <> '' then
            Rec.SetRange("Service Item Group Code", ServItemGroup)
        else
            Rec.SetRange("Service Item Group Code");
    end;

    procedure SetDocument(TableID: Integer; DocumentType: Integer; DocumentNo: Code[20]; LineNo: Integer)
    begin
        ServDocumentType := DocumentType;
        ServDocumentNo := DocumentNo;
        ServLineNo := LineNo;
        ServTableID := TableID;
    end;

    local procedure UpdateOriginalRecord()
    begin
        case ServTableID of
            DATABASE::"Service Item Line":
                begin
                    ServItemLine.Get(ServDocumentType, ServDocumentNo, ServLineNo);
                    ServItemLine."Fault Area Code" := Rec."Fault Area Code";
                    ServItemLine."Symptom Code" := Rec."Symptom Code";
                    ServItemLine."Fault Code" := Rec."Fault Code";
                    ServItemLine."Resolution Code" := Rec."Resolution Code";
                    OnUpdateOriginalRecordOnBeforeServItemLineModify(Rec, ServItemLine);
                    ServItemLine.Modify(true);
                end;
            DATABASE::"Service Line":
                begin
                    ServInvLine.Get(ServDocumentType, ServDocumentNo, ServLineNo);
                    ServInvLine."Fault Area Code" := Rec."Fault Area Code";
                    ServInvLine."Symptom Code" := Rec."Symptom Code";
                    ServInvLine."Fault Code" := Rec."Fault Code";
                    ServInvLine."Resolution Code" := Rec."Resolution Code";
                    OnUpdateOriginalRecordOnBeforeServInvLineModify(Rec, ServInvLine);
                    ServInvLine.Modify();
                end;
        end;
    end;

    local procedure FaultAreaOnAfterValidate()
    begin
        CurrPage.Update(false);
    end;

    local procedure SymptomCodeOnAfterValidate()
    begin
        CurrPage.Update(false);
    end;

    local procedure ServItemGroupCodeOnAfterValida()
    begin
        CurrPage.Update(false);
    end;

    local procedure FaultCodeOnAfterValidate()
    begin
        CurrPage.Update(false);
    end;

    local procedure OKOnPush()
    begin
        UpdateOriginalRecord();
        CurrPage.Close();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateOriginalRecordOnBeforeServItemLineModify(FaultResolCodRelationship: Record "Fault/Resol. Cod. Relationship"; var ServiceItemLine: Record "Service Item Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateOriginalRecordOnBeforeServInvLineModify(FaultResolCodRelationship: Record "Fault/Resol. Cod. Relationship"; var ServiceLine: Record "Service Line")
    begin
    end;
}

