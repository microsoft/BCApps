// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.SyncEngine;

using System.Reflection;

page 5383 "Man. Int. Field Mapping Wizard"
{
    ApplicationArea = All;
    Caption = 'User Defined Field Mappings';
    PageType = ListPart;
    SourceTable = "Man. Int. Field Mapping";
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            repeater(repeaterName)
            {
                field(TableFieldCaptionValue; Rec."Table Field Caption")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    Caption = 'Field Name';

                    trigger OnAssistEdit()
                    var
                        Field: Record "Field";
                        FieldSelection: Codeunit "Field Selection";
                    begin
                        Field.SetRange(TableNo, IntegrationMappingTableId);
                        Rec.GetAllValidFields(Field, false, IntegrationMappingName, IntegrationMappingTableId);
                        if FieldSelection.Open(Field) then begin
                            Rec."Table Field No." := Field."No.";
                            Rec."Table Field Caption" := Field."Field Caption";
                        end;
                    end;
                }
                field(IntegrationTableFieldCaptionValue; Rec."Int. Table Field Caption")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    Caption = 'Integration Field Name';

                    trigger OnAssistEdit()
                    var
                        IntegrationField: Record "Integration Field";
                        Field: Record "Field";
                        LocalField: Record Field;
                    begin
                        Rec.GetAllValidIntegrationFields(IntegrationField, IntegrationMappingName, IntegrationMappingIntTableId);
                        if LookupIntegrationField(IntegrationField) then begin
                            if not IntegrationField.IsRuntime then begin
                                Field.Get(IntegrationField."Table No.", IntegrationField."Field No.");
                                LocalField.Get(IntegrationMappingTableId, Rec."Table Field No.");
                                Rec.CompareFieldType(LocalField, Field);
                                Rec."Integration Table Field No." := Field."No.";
                            end else
                                // Potential improvement: Handle runtime fields type comparison
                                // expose altpgen's casting logic to AL
                                // and use it here to compare types
                                Rec."Integration Table Field Name" := IntegrationField."Field Name";
                            Rec."Int. Table Field Caption" := IntegrationField."Field Caption";
                        end;
                    end;
                }
                field(Direction; Rec."Direction")
                {
                }
                field(ConstValue; Rec."Const Value")
                {
                }
                field("Transformation Rule"; Rec."Transformation Rule")
                {
                }
                field(ValidateField; Rec."Validate Field")
                {
                }
                field(ValidateIntegrTableField; Rec."Validate Integr. Table Field")
                {
                }
            }
        }
    }

    var
        IntegrationMappingTableId: Integer;
        IntegrationMappingIntTableId: Integer;
        IntegrationMappingName: Code[20];

    internal procedure SetValues(lIntegrationMappingTableId: Integer; lIntegrationMappingIntTableId: Integer; lIntegrationMappingName: Code[20])
    begin
        IntegrationMappingTableId := lIntegrationMappingTableId;
        IntegrationMappingIntTableId := lIntegrationMappingIntTableId;
        IntegrationMappingName := lIntegrationMappingName;
    end;

    internal procedure GetValues(var ManIntFieldMapping: Record "Man. Int. Field Mapping" temporary);
    begin
        if Rec.FindSet() then
            repeat
                ManIntFieldMapping.Copy(Rec);
                ManIntFieldMapping.Insert();
            until Rec.Next() = 0;
    end;

    procedure LookupIntegrationField(var IntegrationField: Record "Integration Field"): Boolean
    var
        IntegrationFieldsLookup: Page "Integration Fields Lookup";
    begin
        if Page.RunModal(Page::"Integration Fields Lookup", IntegrationField) = Action::LookupOK then begin
            IntegrationFieldsLookup.GetSelectedFields(IntegrationField);
            exit(true);
        end;
        exit(false);
    end;
}