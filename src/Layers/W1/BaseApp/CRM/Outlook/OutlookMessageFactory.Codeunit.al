// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Outlook;

codeunit 9530 "Outlook Message Factory"
{
    SingleInstance = true;
    Subtype = Normal;
    ObsoleteState = Pending;
    ObsoleteReason = 'This codeunit depends on legacy Office interop API and is not supported in the modern client.';
    ObsoleteTag = '25.0';

    trigger OnRun()
    begin
    end;
}

