// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

/// <summary>
/// Discriminator for an E-Document Message kind. The enum value binds to an
/// "IEDocumentMessageType" implementation that owns identity, applicability,
/// state-transition intent (via the Apply Context), and UX.
/// Format apps and localizations extend this enum.
/// </summary>
enum 6115 "E-Document Message Type" implements IEDocumentMessageType
{
    Extensible = true;

    value(0; Unknown)
    {
        Caption = 'Unknown';
        Implementation = IEDocumentMessageType = "EDoc Unknown Msg Type";
    }
}
