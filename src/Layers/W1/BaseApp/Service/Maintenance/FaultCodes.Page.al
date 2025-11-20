// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Maintenance;

page 5927 "Fault Codes"
{
    ApplicationArea = Service;
    Caption = 'Fault Codes';
    DataCaptionFields = "Fault Area Code", "Symptom Code";
    PageType = List;
    SourceTable = "Fault Code";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Fault Area Code"; Rec."Fault Area Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the fault area associated with the fault code.';
                    Visible = FaultAreaCodeVisible;
                }
                field("Symptom Code"; Rec."Symptom Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the symptom linked to the fault code.';
                    Visible = SymptomCodeVisible;
                }
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a code for the fault.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a description of the fault code.';
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
        area(processing)
        {
            action("Import IRIS to Fault Code")
            {
                ApplicationArea = Service;
                Caption = 'Import IRIS to Fault Code';
                Image = Import;
                RunObject = XMLport "Import IRIS to Fault Codes";
                ToolTip = 'Import the International Repair Coding System to define fault codes for service items.';
            }
        }
    }

    trigger OnInit()
    begin
        SymptomCodeVisible := true;
        FaultAreaCodeVisible := true;
    end;

    trigger OnOpenPage()
    begin
        FaultAreaCodeVisible := not CurrPage.LookupMode;
        SymptomCodeVisible := not CurrPage.LookupMode;
    end;

    var
        FaultAreaCodeVisible: Boolean;
        SymptomCodeVisible: Boolean;
}

