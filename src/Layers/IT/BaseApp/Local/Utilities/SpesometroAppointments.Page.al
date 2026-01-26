// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

page 12120 "Spesometro Appointments"
{
    Caption = 'Spesometro Appointments';
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = "Spesometro Appointment";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Appointment Code"; Rec."Appointment Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code for the company that is submitting VAT statements on behalf of other legal entities.';
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the vendor that is providing the service.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the start date of the Spesometro appointment.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the end date of the Spesometro appointment.';
                }
                field(Designation; Rec.Designation)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the designation or role of the appointment of the person performing the report transmission.';
                }
            }
        }
    }

    actions
    {
    }
}

