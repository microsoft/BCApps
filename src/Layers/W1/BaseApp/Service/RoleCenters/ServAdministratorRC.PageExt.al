// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.RoleCenters;

using Microsoft.RoleCenters;
using Microsoft.Service.Document;
using Microsoft.Service.Maintenance;
using Microsoft.Service.Setup;

pageextension 6471 "Serv. Administrator RC" extends "Administrator Role Center"
{
    actions
    {
        addafter("Res&ources Setup")
        {
            action("&Service Setup")
            {
                ApplicationArea = Service;
                Caption = '&Service Setup';
                Image = ServiceSetup;
                RunObject = Page "Service Mgt. Setup";
                ToolTip = 'Configure your company policies for service management.';
            }
        }
        addafter("&Human Resource Setup")
        {
            action("&Service Order Status Setup")
            {
                ApplicationArea = Service;
                Caption = '&Service Order Status Setup';
                Image = ServiceOrderSetup;
                RunObject = Page "Service Order Status Setup";
                ToolTip = 'View or edit different service order status options and the level of priority assigned to each one.';
            }
            action("&Repair Status Setup")
            {
                ApplicationArea = Service;
                Caption = '&Repair Status Setup';
                Image = ServiceSetup;
                RunObject = Page "Repair Status Setup";
                ToolTip = 'View or edit the different repair status options that you can assign to service items. You can use repair status to identify the progress of repair and maintenance of service items.';
            }
        }
        addafter("Report Selection - &Warehouse")
        {
            action("Report Selection - S&ervice")
            {
                ApplicationArea = Service;
                Caption = 'Report Selection - S&ervice';
                Image = SelectReport;
                RunObject = Page "Report Selection - Service";
                ToolTip = 'View or edit the list of reports that can be printed when you work with service management.';
            }
        }
        addafter("Con&tacts")
        {
            action("Service Trou&bleshooting")
            {
                ApplicationArea = Service;
                Caption = 'Service Trou&bleshooting';
                Image = Troubleshoot;
                RunObject = Page Troubleshooting;
                ToolTip = 'View or edit information about technical problems with a service item.';
            }
            group("&Import")
            {
                Caption = '&Import';
                Image = Import;
                action("Import IRIS to &Area/Symptom Code")
                {
                    ApplicationArea = Service;
                    Caption = 'Import IRIS to &Area/Symptom Code';
                    Image = Import;
                    RunObject = XMLport "Imp. IRIS to Area/Symptom Code";
                    ToolTip = 'Import the International Repair Coding System to define area/symptom codes for service items.';
                }
                action("Import IRIS to &Fault Codes")
                {
                    ApplicationArea = Service;
                    Caption = 'Import IRIS to &Fault Codes';
                    Image = Import;
                    RunObject = XMLport "Import IRIS to Fault Codes";
                    ToolTip = 'Import the International Repair Coding System to define fault codes for service items.';
                }
                action("Import IRIS to &Resolution Codes")
                {
                    ApplicationArea = Service;
                    Caption = 'Import IRIS to &Resolution Codes';
                    Image = Import;
                    RunObject = XMLport "Import IRIS to Resol. Codes";
                    ToolTip = 'Import the International Repair Coding System to define resolution codes for service items.';
                }
            }
        }
    }
}
