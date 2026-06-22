// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.RoleCenters;

using Microsoft.Service.Document;
using Microsoft.Service.Reports;

page 9066 "Serv Outbound Technician Act."
{
    Caption = 'Activities';
    PageType = CardPart;
    RefreshOnActivate = true;
    SourceTable = "Service Cue";

    layout
    {
        area(content)
        {
            cuegroup("Outbound Service Orders")
            {
                Caption = 'Outbound Service Orders';
                field("Service Orders - Today"; Rec."Service Orders - Today")
                {
                    ApplicationArea = Service;
                    DrillDownPageID = "Service Orders";
                }
                field("Service Orders - to Follow-up"; Rec."Service Orders - to Follow-up")
                {
                    ApplicationArea = Service;
                    DrillDownPageID = "Service Orders";
                }

                actions
                {
                    action("New Service Order")
                    {
                        ApplicationArea = Service;
                        Caption = 'New Service Order';
                        RunObject = Page "Service Order";
                        RunPageMode = Create;
                        ToolTip = 'Create an order for specific service work to be performed on a customer''s item. ';
                    }
                    action("Service Item Worksheet")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Item Worksheet';
                        RunObject = Report "Service Item Worksheet";
                    }
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;

        Rec.SetRespCenterFilter();
        Rec.SetRange("Date Filter", WorkDate(), WorkDate());
        Rec.SetRange("User ID Filter", UserId());
    end;
}

