// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.Agents;

/// <summary>
/// No-op implementation of IAgentTestResourceProvider.
/// Used by the ProvideInputAndWait overload that does not support attachments.
/// Any call to GetResource will error, since this provider should only be used
/// when LoadResources is false.
/// </summary>
codeunit 130565 "NoOp Agent Test Res. Provider" implements "IAgentTestResourceProvider"
{
    Access = Internal;

#pragma warning disable AA0150
    procedure GetResource(ResourcePath: Text; var ResourceInStream: InStream; var FileName: Text[250]; var MIMEType: Text[100])
#pragma warning restore AA0150
    begin
        Error(NoResourceProviderErr);
    end;

    var
        NoResourceProviderErr: Label 'No resource provider configured. Use the ProvideInputAndWait overload that accepts an IAgentTestResourceProvider to load attachments.';
}
