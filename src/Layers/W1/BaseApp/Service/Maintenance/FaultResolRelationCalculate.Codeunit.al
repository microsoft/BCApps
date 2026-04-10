// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Maintenance;

using Microsoft.Service.History;
using Microsoft.Service.Setup;

codeunit 5913 "FaultResolRelation-Calculate"
{

    trigger OnRun()
    begin
    end;

    var
        TempFaultResolutionRelation: Record "Fault/Resol. Cod. Relationship" temporary;
        FaultResolutionRelation: Record "Fault/Resol. Cod. Relationship";
        ServShptHeader: Record "Service Shipment Header";
        ServShptItemLine: Record "Service Shipment Item Line";
        ServShptLine: Record "Service Shipment Line";
        ResolutionCode: Record "Resolution Code";
        ServMgtSetup: Record "Service Mgt. Setup";
        Window: Dialog;
        AreaFlag: Boolean;
        SymptomFlag: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Searching Posted Service Order No.  #1###########';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure CopyResolutionRelationToTable(FromDate: Date; ToDate: Date; ServiceItemGroupRelation: Boolean; RetainManuallyInserted: Boolean)
    begin
        TempFaultResolutionRelation.Reset();
        if RetainManuallyInserted then
            FaultResolutionRelation.SetRange("Created Manually", false);

        FaultResolutionRelation.DeleteAll();

        Clear(FaultResolutionRelation);
        if FaultResolutionRelation.Find('-') then
            repeat
                TempFaultResolutionRelation.Init();
                TempFaultResolutionRelation."Fault Code" := FaultResolutionRelation."Fault Code";
                TempFaultResolutionRelation."Fault Area Code" := FaultResolutionRelation."Fault Area Code";
                TempFaultResolutionRelation."Symptom Code" := FaultResolutionRelation."Symptom Code";
                TempFaultResolutionRelation."Resolution Code" := FaultResolutionRelation."Resolution Code";
                TempFaultResolutionRelation."Service Item Group Code" := FaultResolutionRelation."Service Item Group Code";
                TempFaultResolutionRelation.Occurrences := FaultResolutionRelation.Occurrences;
                TempFaultResolutionRelation.Description := FaultResolutionRelation.Description;
                TempFaultResolutionRelation."Created Manually" := FaultResolutionRelation."Created Manually";
                TempFaultResolutionRelation.Insert();
            until FaultResolutionRelation.Next() = 0;

        Clear(FaultResolutionRelation);
        FaultResolutionRelation.DeleteAll();
        Window.Open(
          Text000);
        ServShptHeader.SetCurrentKey("Posting Date");
        ServShptHeader.SetRange("Posting Date", FromDate, ToDate);
        if ServShptHeader.Find('-') then begin
            ServMgtSetup.Get();
            case ServMgtSetup."Fault Reporting Level" of
                ServMgtSetup."Fault Reporting Level"::Fault:
                    begin
                        AreaFlag := false;
                        SymptomFlag := false;
                    end;
                ServMgtSetup."Fault Reporting Level"::"Fault+Symptom":
                    begin
                        AreaFlag := false;
                        SymptomFlag := true;
                    end;
                ServMgtSetup."Fault Reporting Level"::"Fault+Symptom+Area (IRIS)":
                    begin
                        AreaFlag := true;
                        SymptomFlag := true;
                    end;
            end;

            repeat
                Window.Update(1, ServShptHeader."No.");
                ServShptItemLine.SetRange("No.", ServShptHeader."No.");
                if ServShptItemLine.Find('-') then
                    repeat
                        ServShptLine.SetRange("Document No.", ServShptHeader."No.");
                        ServShptLine.SetRange("Service Item Line No.", ServShptItemLine."Line No.");
                        ServShptLine.SetFilter("Resolution Code", '<>%1', '');
                        if ServShptLine.Find('-') then
                            repeat
                                TempFaultResolutionRelation.Init();
                                TempFaultResolutionRelation."Fault Code" := ServShptLine."Fault Code";
                                if ServiceItemGroupRelation then
                                    TempFaultResolutionRelation."Service Item Group Code" := ServShptItemLine."Service Item Group Code"
                                else
                                    TempFaultResolutionRelation."Service Item Group Code" := '';
                                if AreaFlag then
                                    TempFaultResolutionRelation."Fault Area Code" := ServShptLine."Fault Area Code"
                                else
                                    TempFaultResolutionRelation."Fault Area Code" := '';
                                if SymptomFlag then
                                    TempFaultResolutionRelation."Symptom Code" := ServShptLine."Symptom Code"
                                else
                                    TempFaultResolutionRelation."Symptom Code" := '';
                                TempFaultResolutionRelation."Resolution Code" := ServShptLine."Resolution Code";
                                if ResolutionCode.Get(ServShptLine."Resolution Code") then
                                    TempFaultResolutionRelation.Description := ResolutionCode.Description;
                                if not TempFaultResolutionRelation.Insert() then begin
                                    FaultResolutionRelation.SetRange("Fault Code", ServShptLine."Fault Code");
                                    if AreaFlag then
                                        FaultResolutionRelation.SetRange("Fault Area Code", ServShptLine."Fault Area Code")
                                    else
                                        FaultResolutionRelation.SetRange("Fault Area Code");
                                    if ServiceItemGroupRelation then
                                        FaultResolutionRelation.SetRange("Service Item Group Code", ServShptItemLine."Service Item Group Code")
                                    else
                                        FaultResolutionRelation.SetRange("Service Item Group Code");
                                    if SymptomFlag then
                                        FaultResolutionRelation.SetRange("Symptom Code", ServShptLine."Symptom Code")
                                    else
                                        FaultResolutionRelation.SetRange("Symptom Code");
                                    FaultResolutionRelation.SetRange("Resolution Code", ServShptLine."Resolution Code");
                                    if FaultResolutionRelation.Find('-') then begin
                                        FaultResolutionRelation.Occurrences := FaultResolutionRelation.Occurrences + 1;
                                        FaultResolutionRelation.Modify();
                                    end else begin
                                        FaultResolutionRelation.Init();
                                        FaultResolutionRelation."Fault Code" := ServShptLine."Fault Code";
                                        if AreaFlag then
                                            FaultResolutionRelation."Fault Area Code" := ServShptLine."Fault Area Code"
                                        else
                                            FaultResolutionRelation."Fault Area Code" := '';
                                        if SymptomFlag then
                                            FaultResolutionRelation."Symptom Code" := ServShptLine."Symptom Code"
                                        else
                                            FaultResolutionRelation."Symptom Code" := '';
                                        if ServiceItemGroupRelation then
                                            FaultResolutionRelation."Service Item Group Code" := ServShptItemLine."Service Item Group Code"
                                        else
                                            FaultResolutionRelation."Service Item Group Code" := '';
                                        FaultResolutionRelation."Resolution Code" := ServShptLine."Resolution Code";
                                        if ResolutionCode.Get(ServShptLine."Resolution Code") then
                                            FaultResolutionRelation.Description := ResolutionCode.Description;
                                        FaultResolutionRelation.Occurrences := 1;
                                        FaultResolutionRelation.Insert();
                                    end;
                                end;
                            until ServShptLine.Next() = 0;

                    until ServShptItemLine.Next() = 0;

            until ServShptHeader.Next() = 0;
        end;
        if TempFaultResolutionRelation.Find('-') then
            repeat
                FaultResolutionRelation.SetRange("Fault Code", TempFaultResolutionRelation."Fault Code");
                if ServiceItemGroupRelation then
                    FaultResolutionRelation.SetRange("Service Item Group Code", TempFaultResolutionRelation."Service Item Group Code")
                else
                    FaultResolutionRelation.SetRange("Service Item Group Code");
                if AreaFlag then
                    FaultResolutionRelation.SetRange("Fault Area Code", TempFaultResolutionRelation."Fault Area Code")
                else
                    FaultResolutionRelation.SetRange("Fault Area Code");
                if SymptomFlag then
                    FaultResolutionRelation.SetRange("Symptom Code", TempFaultResolutionRelation."Symptom Code")
                else
                    FaultResolutionRelation.SetRange("Symptom Code");
                FaultResolutionRelation.SetRange("Resolution Code", TempFaultResolutionRelation."Resolution Code");
                if FaultResolutionRelation.Find('-') then begin
                    FaultResolutionRelation.Occurrences := FaultResolutionRelation.Occurrences + 1;
                    FaultResolutionRelation.Modify();
                end else begin
                    FaultResolutionRelation.Init();
                    FaultResolutionRelation."Fault Code" := TempFaultResolutionRelation."Fault Code";
                    if AreaFlag then
                        FaultResolutionRelation."Fault Area Code" := TempFaultResolutionRelation."Fault Area Code"
                    else
                        FaultResolutionRelation."Fault Area Code" := '';
                    if SymptomFlag then
                        FaultResolutionRelation."Symptom Code" := TempFaultResolutionRelation."Symptom Code"
                    else
                        FaultResolutionRelation."Symptom Code" := '';
                    FaultResolutionRelation."Resolution Code" := TempFaultResolutionRelation."Resolution Code";
                    if ServiceItemGroupRelation then
                        FaultResolutionRelation."Service Item Group Code" := TempFaultResolutionRelation."Service Item Group Code"
                    else
                        FaultResolutionRelation."Service Item Group Code" := '';
                    if ResolutionCode.Get(TempFaultResolutionRelation."Resolution Code") then
                        FaultResolutionRelation.Description := ResolutionCode.Description;
                    FaultResolutionRelation."Created Manually" := TempFaultResolutionRelation."Created Manually";
                    FaultResolutionRelation.Occurrences := 1;
                    FaultResolutionRelation.Insert();
                end;
            until TempFaultResolutionRelation.Next() = 0;

        Window.Close();
    end;
}

