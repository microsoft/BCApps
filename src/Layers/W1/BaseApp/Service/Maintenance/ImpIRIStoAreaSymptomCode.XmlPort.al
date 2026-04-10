// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Maintenance;

xmlport 5900 "Imp. IRIS to Area/Symptom Code"
{
    Caption = 'Imp. IRIS to Area/Symptom Code';
    Direction = Import;
    Format = VariableText;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement("Fault Area/Symptom Code"; "Fault Area/Symptom Code")
            {
                XmlName = 'Import';
                UseTemporary = true;
                fieldelement(Type; "Fault Area/Symptom Code".Type)
                {
                }
                fieldelement(Code; "Fault Area/Symptom Code".Code)
                {
                }
                fieldelement(Description; "Fault Area/Symptom Code".Description)
                {
                }

                trigger OnBeforeInsertRecord()
                var
                    FaultArea: Record "Fault Area";
                    SymptCode: Record "Symptom Code";
                begin
                    case "Fault Area/Symptom Code".Type of
                        "Fault Area/Symptom Code".Type::"Fault Area":
                            begin
                                FaultArea.Init();
                                FaultArea.Code := "Fault Area/Symptom Code".Code;
                                FaultArea.Description := "Fault Area/Symptom Code".Description;
                                if not FaultArea.Insert() then
                                    FaultArea.Modify();
                                Counter += 1;
                            end;
                        "Fault Area/Symptom Code".Type::"Symptom Code":
                            begin
                                SymptCode.Init();
                                SymptCode.Code := "Fault Area/Symptom Code".Code;
                                SymptCode.Description := "Fault Area/Symptom Code".Description;
                                if not SymptCode.Insert() then
                                    SymptCode.Modify();
                                Counter += 1;
                            end;
                    end;
                end;
            }
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    trigger OnPostXmlPort()
    begin
        Message(Text001, Counter);
    end;

    var
        Counter: Integer;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label '%1 records were successfully inserted or modified.';
#pragma warning restore AA0470
#pragma warning restore AA0074
}

