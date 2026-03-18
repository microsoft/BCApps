// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#pragma warning disable AA0247
codeunit 5369 "Manual Int Mapping Events"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CDS Setup Defaults", 'OnAfterResetConfiguration', '', true, true)]
    local procedure HandleOnAfterResetConfiguration(CDSConnectionSetup: Record "CDS Connection Setup")
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        ManIntegrationTableMapping: Record "Man. Integration Table Mapping";
        ManIntFieldMapping: Record "Man. Int. Field Mapping";
    begin
        ManIntegrationTableMapping.Reset();
        if ManIntegrationTableMapping.FindSet() then
            repeat
                if not IntegrationTableMapping.Get(ManIntegrationTableMapping.Name) then begin
                    ManIntegrationTableMapping.InsertIntegrationTableMapping(
                        IntegrationTableMapping,
                        ManIntegrationTableMapping.Name,
                        ManIntegrationTableMapping."Table ID",
                        ManIntegrationTableMapping."Integration Table ID",
                        ManIntegrationTableMapping."Integration Table UID",
                        ManIntegrationTableMapping."Int. Tbl. Modified On Id",
                        ManIntegrationTableMapping."Sync Only Coupled Records",
                        ManIntegrationTableMapping.Direction
                        );

                    IntegrationTableMapping."Table Filter" := ManIntegrationTableMapping."Table Filter";
                    IntegrationTableMapping."Integration Table Filter" := ManIntegrationTableMapping."Integration Table Filter";
                    IntegrationTableMapping."User Defined" := true;
                    IntegrationTableMapping.Modify(true);
                end;

                ManIntFieldMapping.Reset();
                ManIntFieldMapping.SetRange(Name, ManIntegrationTableMapping.Name);
                if ManIntFieldMapping.FindSet() then
                    repeat
                        ManIntegrationTableMapping.InsertIntegrationFieldMapping(
                            ManIntFieldMapping.Name,
                            ManIntFieldMapping."Table Field No.",
                            ManIntFieldMapping."Integration Table Field No.",
                            ManIntFieldMapping.Direction,
                            ManIntFieldMapping."Const Value",
                            ManIntFieldMapping."Validate Field",
                            ManIntFieldMapping."Validate Integr. Table Field",
                            false,
                            ManIntFieldMapping."Transformation Rule"
                            );
                    until ManIntFieldMapping.Next() = 0;
            until ManIntegrationTableMapping.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Integration Management", 'OnAfterAddExtraFieldMappings', '', true, true)]
    local procedure AddExtraFieldMappings(IntegrationTableMappingName: Code[20])
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
        ManIntegrationTableMapping: Record "Man. Integration Table Mapping";
        ManIntFieldMapping: Record "Man. Int. Field Mapping";
    begin
        ManIntFieldMapping.Reset();
        ManIntFieldMapping.SetRange(Name, IntegrationTableMappingName);
        if ManIntFieldMapping.FindSet() then
            repeat
                IntegrationFieldMapping.Reset();
                IntegrationFieldMapping.SetRange("Integration Table Mapping Name", IntegrationTableMappingName);
                IntegrationFieldMapping.SetRange("Field No.", ManIntFieldMapping."Table Field No.");
                IntegrationFieldMapping.SetRange("Integration Table Field No.", ManIntFieldMapping."Integration Table Field No.");
                if IntegrationFieldMapping.IsEmpty() then
                    ManIntegrationTableMapping.InsertIntegrationFieldMapping(
                        IntegrationTableMappingName,
                        ManIntFieldMapping."Table Field No.",
                        ManIntFieldMapping."Integration Table Field No.",
                        ManIntFieldMapping.Direction,
                        ManIntFieldMapping."Const Value",
                        ManIntFieldMapping."Validate Field",
                        ManIntFieldMapping."Validate Integr. Table Field",
                        false,
                        ManIntFieldMapping."Transformation Rule"
                        );
            until ManIntFieldMapping.Next() = 0;
    end;
}
