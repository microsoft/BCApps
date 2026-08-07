// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#pragma warning disable AA0247

#pragma warning disable AL0432
pageextension 20357 "Extension Management Ext." extends "Extension Management"
#pragma warning restore AL0432
{
    actions
    {
        addlast(processing)
        {
            action("Connectivity Apps")
            {
                ApplicationArea = All;
                Caption = 'Connectivity Apps';
                Visible = IsConnectivityAppsAvailable;
                Image = NewItem;
                ToolTip = 'View apps that can connect your business to external services to increase productivity by automating processes.';

                trigger OnAction()
                begin
                    Page.Run(Page::"Connectivity Apps");
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        IsConnectivityAppsAvailable := ConnectivityAppsImpl.IsConnectivityAppsAvailableForGeo();
    end;

    var
        ConnectivityAppsImpl: Codeunit "Connectivity Apps Impl.";
        IsConnectivityAppsAvailable: Boolean;
}
