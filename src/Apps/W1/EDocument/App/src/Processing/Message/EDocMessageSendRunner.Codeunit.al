// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Message;

codeunit 6537 "E-Doc. Message Send Runner"
{
    Access = Internal;
    TableNo = "E-Document Message";
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        EDocMessageMgt: Codeunit "E-Doc. Message Mgt.";
    begin
        EDocMessageMgt.SendMessage(Rec."Entry No.");
    end;
}