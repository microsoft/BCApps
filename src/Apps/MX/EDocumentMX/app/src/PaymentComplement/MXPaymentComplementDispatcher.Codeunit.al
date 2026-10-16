// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.EServices.EDocument.Interfactura;

using Microsoft.eServices.EDocument.Processing.Message;

/// <summary>
/// Queues MX payment complement messages in a separate background task session.
/// This must not run as a Job Queue OnRun handler because QueueMessage performs a COMMIT.
/// </summary>
codeunit 3365 "MX Payment Compl. Dispatcher"
{
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "MX Payment Complement" = r;

    trigger OnRun()
    var
        Complement: Record "MX Payment Complement";
        MessageAPI: Codeunit "E-Document Message API";
    begin
        Complement.SetFilter("E-Document Message Entry No.", '>%1', 0);
        Complement.SetRange(Reversed, false);
        if not Complement.FindSet() then
            exit;
        repeat
            if MessageAPI.GetMessageStatus(Complement."E-Document Message Entry No.") = Enum::"E-Doc. Message Status"::Created then
                MessageAPI.QueueMessage(Complement."E-Document Message Entry No.");
        until Complement.Next() = 0;
    end;
}