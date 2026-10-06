// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExternalStorage.DocumentAttachments;

enum 8751 "DA Internal Cleanup Origin"
{
    Access = Internal;
    Extensible = false;

    value(0; Copy) { Caption = 'Copy'; }
    value(1; Automatic) { Caption = 'Automatic'; }
    value(2; Move) { Caption = 'Move'; }
    value(3; "Delete from Internal") { Caption = 'Delete from Internal'; }
}
