// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Service.Maintenance;
using System.Utilities;

table 5928 "Service Status Priority Setup"
{
    Caption = 'Service Status Priority Setup';
    DrillDownPageID = "Service Order Status Setup";
    LookupPageID = "Service Order Status Setup";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Service Order Status"; Enum "Service Document Status")
        {
            Caption = 'Service Order Status';
        }
        field(2; Priority; Option)
        {
            Caption = 'Priority';
            OptionCaption = 'High,Medium High,Medium Low,Low';
            OptionMembers = High,"Medium High","Medium Low",Low;

            trigger OnValidate()
            var
                ConfirmManagement: Codeunit "Confirm Management";
            begin
                if Priority <> xRec.Priority then begin
                    ServStatusPrioritySetup.Reset();
                    ServStatusPrioritySetup.SetRange(Priority, Priority);
                    if ServStatusPrioritySetup.FindFirst() then
                        if not ConfirmManagement.GetResponseOrDefault(
                             StrSubstNo(
                               Text000, FieldCaption(Priority), Format(Priority),
                               FieldCaption("Service Order Status"), Format("Service Order Status")), true)
                        then
                            Priority := xRec.Priority;

                    RepairStatus.Reset();
                    RepairStatus.SetRange("Service Order Status", "Service Order Status");
                    RepairStatus.ModifyAll(Priority, Priority);
                end;
            end;
        }
    }

    keys
    {
        key(Key1; "Service Order Status")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        ServStatusPrioritySetup: Record "Service Status Priority Setup";
        RepairStatus: Record "Repair Status";

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 %2 is already used with %3 %4.\\Do you want to continue?';
#pragma warning restore AA0470
#pragma warning restore AA0074
}

