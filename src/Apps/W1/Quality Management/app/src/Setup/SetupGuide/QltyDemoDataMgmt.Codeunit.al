// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Setup;

using System.Apps;

/// <summary>
/// Handles launching Contoso Demo Tool or showing installation message.
/// </summary>
codeunit 20422 "Qlty. Demo Data Mgmt."
{
    Access = Internal;

    /// <summary>
    /// Launches the Contoso Demo Tool if installed, otherwise shows installation message.
    /// </summary>
    procedure LaunchDemoData()
    begin
        if IsContosoDemoToolInstalled() then
            OpenContosoDemoTool()
        else
            Message(NotInstalledMsg);
    end;

    /// <summary>
    /// Checks if the Quality Management Contoso Coffee Demo Dataset app is installed.
    /// </summary>
    /// <returns>True if the app is installed, false otherwise.</returns>
    procedure IsContosoDemoToolInstalled(): Boolean
    var
        ExtensionManagement: Codeunit "Extension Management";
        ContosoAppId: Guid;
    begin
        // Quality Management Contoso Coffee Demo Dataset App ID
        ContosoAppId := '40bf2bab-2a57-4c34-9002-c11d23fcbff6';
        exit(ExtensionManagement.IsInstalledByAppId(ContosoAppId));
    end;

    local procedure OpenContosoDemoTool()
    var
        ContosoDemoToolPageId: Integer;
    begin
        // Contoso Demo Tool page ID 
        ContosoDemoToolPageId := 5194;
        Page.Run(ContosoDemoToolPageId);
    end;

    var
        NotInstalledMsg: Label 'The "Quality Management Contoso Coffee Demo Dataset" app is not installed.\\To explore Quality Management with demo data, please install this app from Microsoft AppSource.';
}
